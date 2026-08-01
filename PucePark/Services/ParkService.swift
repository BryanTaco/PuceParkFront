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
        try await perform("\(base)/puestos/\(id)/ocupar", method: .put)
    }

    func liberarPuesto(id: Int) async throws -> PuestoParqueo {
        try await perform("\(base)/puestos/\(id)/liberar", method: .put)
    }

    func forzarLiberacion(id: Int) async throws -> PuestoParqueo {
        try await perform("\(base)/puestos/\(id)/forzar-liberacion", method: .put)
    }

    func forzarOcupacion(id: Int, placa: String) async throws -> PuestoParqueo {
        let body: [String: Any] = ["placaVehiculo": placa]
        return try await perform("\(base)/puestos/\(id)/forzar-ocupacion", method: .put,
                                 parameters: body, encoding: JSONEncoding.default)
    }

    func getPerfil() async throws -> PerfilUsuario {
        try await perform("\(base)/perfil/me")
    }

    func getPerfilEstado() async throws -> PerfilEstado {
        try await perform("\(base)/perfil/me/estado")
    }

    func updatePerfil(nombreCompleto: String, placaVehiculo: String, numeroPermiso: String, modoOscuro: Bool) async throws -> PerfilUsuario {
        let body: [String: Any] = ["nombreCompleto": nombreCompleto, "placaVehiculo": placaVehiculo,
                                    "numeroPermiso": numeroPermiso, "modoOscuro": modoOscuro]
        return try await perform("\(base)/perfil/me", method: .put,
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
