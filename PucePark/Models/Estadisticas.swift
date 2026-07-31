import Foundation

struct EstadisticasPersonales: Decodable, Sendable {
    let mes: String
    let totalSesiones: Int
    let totalHoras: Double
    let promedioHorasPorSesion: Double
}

struct RankingEntrada: Identifiable, Decodable, Sendable {
    let posicion: Int
    let username: String
    let nombreCompleto: String
    let totalHoras: Double
    let totalSesiones: Int
    var id: Int { posicion }
}

struct AuthSession: Sendable {
    let idToken: String
    let accessToken: String
    let username: String
    let grupos: [String]

    var isAdmin: Bool { grupos.contains("ADMIN") }
    var isGuard: Bool { grupos.contains("GUARD") }
    var isUser:  Bool { grupos.contains("USER") }

    var rolPrincipal: String {
        if isAdmin { return "Admin" }
        if isGuard { return "Guardia" }
        return "Usuario"
    }
}
