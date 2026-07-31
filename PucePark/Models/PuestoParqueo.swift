import Foundation

enum EstadoPuesto: String, Decodable, Sendable {
    case DISPONIBLE
    case OCUPADO
}

struct PuestoParqueo: Identifiable, Decodable, Sendable {
    let id: Int
    let numeroPuesto: String
    let fila: String
    let orden: Int
    let estado: EstadoPuesto
    let zona: ZonaParqueo
}
