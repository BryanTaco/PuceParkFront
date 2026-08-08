import Foundation
import Alamofire

private struct BackendError: Decodable {
    let message: String
}

struct ParkAPIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

class ParkService {
    static let shared = ParkService()
    private init() {}
    private let base = AppConfig.apiBaseUrl
    private let usersBase = AppConfig.usersBaseUrl   // microservicio de perfiles (/users)

    private var headers: HTTPHeaders {
        guard let t = AuthService.shared.savedToken else { return [] }
        return ["Authorization": "Bearer \(t)"]
    }

    // Centralised request: decodes the backend { "message": "..." } error body
    // so callers receive the real error text, not a generic Alamofire string.
    private func rawRequest(
        _ url: String, _ method: HTTPMethod,
        _ parameters: [String: Any]?, _ encoding: ParameterEncoding
    ) async -> (data: Data, status: Int, error: Error?) {
        let resp = await AF.request(url, method: method, parameters: parameters,
                                    encoding: encoding, headers: headers)
            .serializingData()
            .response
        return (resp.data ?? Data(), resp.response?.statusCode ?? 0, resp.error)
    }

    private func perform<T: Decodable>(
        _ url: String,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        encoding: ParameterEncoding = URLEncoding.default
    ) async throws -> T {
        var r = await rawRequest(url, method, parameters, encoding)

        // Token expirado: intenta refrescar una vez y reintenta.
        if r.status == 401 {
            if await AuthService.shared.refreshSession() {
                r = await rawRequest(url, method, parameters, encoding)
            }
            if r.status == 401 {
                // No se pudo refrescar → cerrar sesión y forzar re-login.
                AuthService.shared.logout()
                await MainActor.run { NotificationCenter.default.post(name: .ppSessionExpired, object: nil) }
                throw ParkAPIError(message: "Tu sesión expiró. Vuelve a iniciar sesión.")
            }
        }

        if r.status >= 400 || r.error != nil {
            let msg = (try? JSONDecoder().decode(BackendError.self, from: r.data))?.message
                ?? r.error?.localizedDescription
                ?? "Error del servidor (\(r.status))"
            throw ParkAPIError(message: msg)
        }

        do {
            return try JSONDecoder().decode(T.self, from: r.data)
        } catch {
            throw ParkAPIError(message: "Error al procesar la respuesta del servidor")
        }
    }

    func getZonas() async throws -> [ZonaParqueo] {
        try await perform("\(base)/zonas")
    }

    func getPuestosByZona(zonaId: Int) async throws -> [PuestoParqueo] {
        try await perform("\(base)/puestos/zona/\(zonaId)")
    }

    func ocuparPuesto(id: Int) async throws -> PuestoParqueo {
        // Envía el nombre del perfil (users-service) para el ranking, sin joins entre servicios
        let body: [String: Any] = ["fullName": AuthService.shared.savedFullName ?? ""]
        return try await perform("\(base)/puestos/\(id)/ocupar", method: .put,
                                 parameters: body, encoding: JSONEncoding.default)
    }

    func liberarPuesto(id: Int) async throws -> PuestoParqueo {
        try await perform("\(base)/puestos/\(id)/liberar", method: .put)
    }

    func forzarLiberacion(id: Int) async throws -> PuestoParqueo {
        try await perform("\(base)/puestos/\(id)/forzar-liberacion", method: .put)
    }

    func forzarOcupacion(id: Int, placa: String) async throws -> PuestoParqueo {
        let body: [String: Any] = ["vehiclePlate": placa]
        return try await perform("\(base)/puestos/\(id)/forzar-ocupacion", method: .put,
                                 parameters: body, encoding: JSONEncoding.default)
    }

    // ── Perfil: microservicio de usuarios (users-service vía nginx: /users/me) ──
    func getPerfil() async throws -> PerfilUsuario {
        try await perform("\(usersBase)/me")
    }

    func getPerfilEstado() async throws -> PerfilEstado {
        try await perform("\(usersBase)/me/estado")
    }

    func updatePerfil(fullName: String, vehiclePlate: String, permitNumber: String, darkMode: Bool) async throws -> PerfilUsuario {
        let body: [String: Any] = ["fullName": fullName, "vehiclePlate": vehiclePlate,
                                    "permitNumber": permitNumber, "darkMode": darkMode]
        return try await perform("\(usersBase)/me", method: .put,
                                 parameters: body, encoding: JSONEncoding.default)
    }

    func getHistorialMe() async throws -> [HistorialParqueo] {
        try await perform("\(base)/historial/me")
    }

    func getHistorialGuardia() async throws -> [HistorialParqueo] {
        try await perform("\(base)/historial/guardia/me")
    }

    func getEstadisticasMe(year: Int, month: Int) async throws -> EstadisticasPersonales {
        let mes = "\(year)-\(String(format: "%02d", month))"
        return try await perform("\(base)/historial/me/estadisticas",
                                 parameters: ["mes": mes])
    }

    func getRankingMensual(year: Int, month: Int) async throws -> [RankingEntrada] {
        let mes = "\(year)-\(String(format: "%02d", month))"
        return try await perform("\(base)/historial/ranking/mensual",
                                 parameters: ["mes": mes])
    }

    // ── Admin: zonas y puestos (rol ADMIN) ──────────────────────────────────
    func crearZona(name: String, description: String, maxCapacity: Int, location: String) async throws -> ZonaParqueo {
        let body: [String: Any] = ["name": name, "description": description, "maxCapacity": maxCapacity, "location": location]
        return try await perform("\(base)/zonas", method: .post, parameters: body, encoding: JSONEncoding.default)
    }

    func actualizarZona(id: Int, name: String, description: String, maxCapacity: Int, location: String) async throws -> ZonaParqueo {
        let body: [String: Any] = ["name": name, "description": description, "maxCapacity": maxCapacity, "location": location]
        return try await perform("\(base)/zonas/\(id)", method: .put, parameters: body, encoding: JSONEncoding.default)
    }

    func eliminarZona(id: Int) async throws {
        try await performVoid("\(base)/zonas/\(id)", method: .delete)
    }

    func crearPuesto(zoneId: Int, spaceNumber: String, row: String, order: Int) async throws -> PuestoParqueo {
        let body: [String: Any] = ["zoneId": zoneId, "spaceNumber": spaceNumber, "row": row, "order": order]
        return try await perform("\(base)/puestos", method: .post, parameters: body, encoding: JSONEncoding.default)
    }

    // Petición sin cuerpo de respuesta (ej. DELETE 204). Reusa el manejo de 401/refresh.
    private func performVoid(
        _ url: String, method: HTTPMethod = .get,
        parameters: [String: Any]? = nil, encoding: ParameterEncoding = URLEncoding.default
    ) async throws {
        var r = await rawRequest(url, method, parameters, encoding)
        if r.status == 401 {
            if await AuthService.shared.refreshSession() { r = await rawRequest(url, method, parameters, encoding) }
            if r.status == 401 {
                AuthService.shared.logout()
                await MainActor.run { NotificationCenter.default.post(name: .ppSessionExpired, object: nil) }
                throw ParkAPIError(message: "Tu sesión expiró. Vuelve a iniciar sesión.")
            }
        }
        if r.status >= 400 || r.error != nil {
            let msg = (try? JSONDecoder().decode(BackendError.self, from: r.data))?.message
                ?? r.error?.localizedDescription ?? "Error del servidor (\(r.status))"
            throw ParkAPIError(message: msg)
        }
    }
}
