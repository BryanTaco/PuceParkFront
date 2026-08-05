import Foundation

struct HistorialParqueo: Identifiable, Decodable, Sendable {
    let id: Int
    let ticketCode: String
    let username: String
    let entryDate: String
    let exitDate: String?
    let vehiclePlate: String?
    let space: PuestoParqueo

    var estaActivo: Bool { exitDate == nil }

    var duracionTexto: String {
        guard let salida = exitDate else { return "En curso" }
        return "\(entryDate.horaCorta) → \(salida.horaCorta)"
    }
}

private extension String {
    var horaCorta: String {
        let parts = self.split(separator: "T")
        guard parts.count > 1 else { return self }
        return String(parts[1].prefix(5))
    }
}
