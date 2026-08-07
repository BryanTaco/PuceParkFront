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
    private func perform<T: Decodable>(
        _ url: String,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        encoding: ParameterEncoding = URLEncoding.default
    ) async throws -> T {
        let resp = await AF.request(url, method: method, parameters: parameters,
                                    encoding: encoding, headers: headers)
            .serializingData()
            .response

        let data   = resp.data ?? Data()
        let status = resp.response?.statusCode ?? 0

        if status >= 400 || resp.error != nil {
            let msg = (try? JSONDecoder().decode(BackendError.self, from: data))?.message
                ?? resp.error?.localizedDescription
                ?? "Error del servidor (\(status))"
            throw ParkAPIError(message: msg)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
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
}
