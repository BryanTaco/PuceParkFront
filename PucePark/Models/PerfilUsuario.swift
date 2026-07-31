import Foundation

struct PerfilUsuario: Decodable, Sendable {
    let id: Int
    let username: String
    let nombreCompleto: String
    let placaVehiculo: String
    let numeroPermiso: String
    let modoOscuro: Bool
}

struct PerfilEstado: Decodable, Sendable {
    let completo: Bool
    let faltante: [String]
}
