import Foundation

enum EstadoPuesto: String, Decodable, Sendable {
    case DISPONIBLE
    case OCUPADO
}

struct PuestoParqueo: Identifiable, Decodable, Sendable {
    let id: Int
    let spaceNumber: String
    let row: String
    let order: Int
    let status: EstadoPuesto
    let zone: ZonaParqueo
}
