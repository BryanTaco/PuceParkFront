import Foundation

struct ZonaParqueo: Identifiable, Decodable, Sendable {
    let id: Int
    let name: String
    let description: String
    let location: String
    let maxCapacity: Int
    let availableSpaces: Int
    let occupiedSpaces: Int
    let totalSpaces: Int

    var porcentajeOcupacion: Double {
        guard totalSpaces > 0 else { return 0 }
        return Double(occupiedSpaces) / Double(totalSpaces)
    }
}
