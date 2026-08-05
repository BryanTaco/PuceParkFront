import SwiftUI

struct ZonaCard: View {
    let zona: ZonaParqueo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(zona.name)
                        .font(.headline).foregroundStyle(ParkTheme.Color.textPrimary)
                    Text(zona.location)
                        .font(.caption).foregroundStyle(ParkTheme.Color.textSecond)
                }
                Spacer()
                Image(systemName: "car.fill")
                    .foregroundStyle(ParkTheme.Color.accentLight)
                    .font(.title2)
            }
            if !zona.description.isEmpty {
                Text(zona.description)
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
