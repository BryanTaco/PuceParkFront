import SwiftUI

struct ZonaCard: View {
    let zona: ZonaParqueo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(zona.nombre)
                        .font(.headline).foregroundStyle(ParkTheme.Color.textPrimary)
                    Text(zona.ubicacion)
                        .font(.caption).foregroundStyle(ParkTheme.Color.textSecond)
                }
                Spacer()
                Image(systemName: "car.fill")
                    .foregroundStyle(ParkTheme.Color.accentLight)
                    .font(.title2)
            }
            if !zona.descripcion.isEmpty {
                Text(zona.descripcion)
                    .font(.caption)
                    .foregroundStyle(ParkTheme.Color.textSecond)
                    .lineLimit(2)
            }
            OcupacionBar(zona: zona)
        }
        .padding(16)
        .glassCard()
    }
}
