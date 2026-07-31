import Foundation

struct HistorialParqueo: Identifiable, Decodable, Sendable {
    let id: Int
    let codigoTicket: String
    let username: String
    let fechaIngreso: String
    let fechaSalida: String?
    let puesto: PuestoParqueo

    var estaActivo: Bool { fechaSalida == nil }

    var duracionTexto: String {
        guard let salida = fechaSalida else { return "En curso" }
        return "\(fechaIngreso.horaCorta) → \(salida.horaCorta)"
    }
}

private extension String {
    var horaCorta: String {
        let parts = self.split(separator: "T")
        guard parts.count > 1 else { return self }
        return String(parts[1].prefix(5))
    }
}
