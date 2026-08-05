import SwiftUI

struct HistorialRow: View {
    let entrada: HistorialParqueo

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(entrada.estaActivo ? ParkTheme.Color.disponible.opacity(0.2) : ParkTheme.Color.surface)
                    .frame(width: 44, height: 44)
                Image(systemName: entrada.estaActivo ? "car.fill" : "checkmark.circle.fill")
                    .foregroundStyle(entrada.estaActivo ? ParkTheme.Color.disponible : ParkTheme.Color.textSecond)
                    .font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entrada.space.zone.name)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(ParkTheme.Color.textPrimary)
                    Spacer()
                    Text(entrada.estaActivo ? "Activo" : "Finalizado")
                        .font(.caption2).fontWeight(.medium)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(entrada.estaActivo ? ParkTheme.Color.disponible.opacity(0.2) : ParkTheme.Color.surface)
                        .foregroundStyle(entrada.estaActivo ? ParkTheme.Color.disponible : ParkTheme.Color.textSecond)
                        .clipShape(Capsule())
                }
                Text("Puesto \(entrada.space.spaceNumber) · Fila \(entrada.space.row)")
                    .font(.caption).foregroundStyle(ParkTheme.Color.textSecond)
                Text(entrada.duracionTexto)
                    .font(.caption).foregroundStyle(ParkTheme.Color.textSecond)
                Text("Ticket: \(entrada.ticketCode)")
                    .font(.caption2)
                    .foregroundStyle(ParkTheme.Color.accentLight)
                    .fontDesign(.monospaced)
            }
        }
        .padding(14)
        .glassCard()
    }
}
