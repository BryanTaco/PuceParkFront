import Foundation

struct ZonaParqueo: Identifiable, Decodable, Sendable {
    let id: Int
    let nombre: String
    let descripcion: String
    let ubicacion: String
    let capacidadMaxima: Int
    let puestosDisponibles: Int
    let puestosOcupados: Int
    let totalPuestos: Int

    var porcentajeOcupacion: Double {
        guard totalPuestos > 0 else { return 0 }
        return Double(puestosOcupados) / Double(totalPuestos)
    }
}
