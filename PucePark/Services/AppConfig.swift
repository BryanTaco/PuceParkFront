import Foundation

enum AppConfig {
    private static let filename = "config"

    private static var config: [String: Any] {
        guard
            let url  = Bundle.main.url(forResource: filename, withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        else { fatalError("No se pudo cargar config.plist") }
        return dict
    }

    static var apiBaseUrl: String {
        guard let v = config["API_BASE_URL"] as? String else { fatalError("API_BASE_URL no definida") }
        return v
    }
    // Microservicio de usuarios (perfiles) — vía nginx: http://localhost/users
    static var usersBaseUrl: String {
        guard let v = config["USERS_BASE_URL"] as? String else { fatalError("USERS_BASE_URL no definida") }
        return v
    }
    static var cognitoRegion: String {
        guard let v = config["COGNITO_REGION"] as? String else { fatalError("COGNITO_REGION no definida") }
        return v
    }
    static var cognitoClientId: String {
        guard let v = config["COGNITO_CLIENT_ID"] as? String else { fatalError("COGNITO_CLIENT_ID no definida") }
        return v
    }
    static var cognitoEndpoint: String { "https://cognito-idp.\(cognitoRegion).amazonaws.com/" }
}
