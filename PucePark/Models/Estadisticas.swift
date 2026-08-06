import Foundation

struct EstadisticasPersonales: Decodable, Sendable {
    let month: String
    let totalSessions: Int
    let totalHours: Double
    let avgHoursPerSession: Double
}

struct RankingEntrada: Identifiable, Decodable, Sendable {
    let position: Int
    let username: String
    let fullName: String
    let totalHours: Double
    let totalSessions: Int
    var id: Int { position }
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
        return "Estudiante"
    }
}
