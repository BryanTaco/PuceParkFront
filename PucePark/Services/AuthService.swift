import Foundation

private struct CognitoResponse: Decodable, Sendable {
    struct AuthResult: Decodable, Sendable { let IdToken: String; let AccessToken: String }
    let AuthenticationResult: AuthResult
}

struct CognitoError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

class AuthService {
    static let shared = AuthService()
    private init() {}

    private let tokenKey    = "pp_idToken"
    private let usernameKey = "pp_username"
    private let gruposKey   = "pp_grupos"
    private let fullNameKey = "pp_fullName"

    var savedToken:    String?   { UserDefaults.standard.string(forKey: tokenKey) }
    var savedUsername: String?   { UserDefaults.standard.string(forKey: usernameKey) }
    var savedGrupos:   [String]  { UserDefaults.standard.stringArray(forKey: gruposKey) ?? [] }
    var isLoggedIn:    Bool      { savedToken != nil }

    // Nombre del perfil (del users-service) — se envía al ocupar para el ranking
    var savedFullName: String?   { UserDefaults.standard.string(forKey: fullNameKey) }
    func saveFullName(_ name: String) { UserDefaults.standard.set(name, forKey: fullNameKey) }

    func login(username: String, password: String) async throws -> AuthSession {
        let body: [String: Any] = [
            "AuthFlow": "USER_PASSWORD_AUTH",
            "ClientId": AppConfig.cognitoClientId,
            "AuthParameters": ["USERNAME": username, "PASSWORD": password]
        ]

        var req = URLRequest(url: URL(string: AppConfig.cognitoEndpoint)!)
        req.httpMethod = "POST"
        req.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        req.setValue("AWSCognitoIdentityProviderService.InitiateAuth", forHTTPHeaderField: "X-Amz-Target")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? 0

        guard statusCode == 200 else {
            let raw = String(data: data, encoding: .utf8) ?? ""
            print("🔴 COGNITO ERROR \(statusCode): \(raw)")
            throw CognitoError(message: friendlyError(from: data))
        }

        let decoded = try JSONDecoder().decode(CognitoResponse.self, from: data)
        let idToken  = decoded.AuthenticationResult.IdToken
        let grupos   = decodeGroups(from: idToken)
        let session  = AuthSession(idToken: idToken,
                                   accessToken: decoded.AuthenticationResult.AccessToken,
                                   username: username, grupos: grupos)
        UserDefaults.standard.set(idToken,  forKey: tokenKey)
        UserDefaults.standard.set(username, forKey: usernameKey)
        UserDefaults.standard.set(grupos,   forKey: gruposKey)
        return session
    }

    func logout() {
        [tokenKey, usernameKey, gruposKey, fullNameKey].forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    func currentSession() -> AuthSession? {
        guard let token = savedToken, let username = savedUsername else { return nil }
        if isTokenExpired(token) { logout(); return nil }
        return AuthSession(idToken: token, accessToken: "", username: username, grupos: savedGrupos)
    }

    private func friendlyError(from data: Data) -> String {
        struct CognitoErr: Decodable { let __type: String?; let message: String? }
        let err = try? JSONDecoder().decode(CognitoErr.self, from: data)
        switch err?.__type {
        case "NotAuthorizedException":       return "Contraseña incorrecta."
        case "UserNotFoundException":        return "Usuario no encontrado."
        case "UserNotConfirmedException":    return "Cuenta pendiente de confirmación."
        case "PasswordResetRequiredException": return "Debes restablecer tu contraseña."
        case "TooManyRequestsException", "LimitExceededException": return "Demasiados intentos. Espera un momento."
        default: return err?.message ?? "Error de autenticación. Intenta de nuevo."
        }
    }

    private func decodePayload(from jwt: String) -> [String: Any]? {
        let parts = jwt.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var b64 = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let pad = b64.count % 4; if pad != 0 { b64 += String(repeating: "=", count: 4 - pad) }
        guard let data = Data(base64Encoded: b64) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    private func isTokenExpired(_ jwt: String) -> Bool {
        guard let payload = decodePayload(from: jwt),
              let exp = payload["exp"] as? Double else { return true }
        return Date().timeIntervalSince1970 >= exp
    }

    private func decodeGroups(from jwt: String) -> [String] {
        guard let payload = decodePayload(from: jwt),
              let groups = payload["cognito:groups"] as? [String] else { return [] }
        return groups
    }
}
