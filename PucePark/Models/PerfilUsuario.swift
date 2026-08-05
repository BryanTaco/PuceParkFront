import Foundation

struct PerfilUsuario: Decodable, Sendable {
    let id: Int
    let username: String
    let fullName: String
    let vehiclePlate: String
    let permitNumber: String
    let darkMode: Bool
}

struct PerfilEstado: Decodable, Sendable {
    let complete: Bool
    let missing: [String]
}
