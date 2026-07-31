import SwiftUI

struct RankingRow: View {
    let entry: RankingEntrada
    let currentUsername: String?

    private var isMe: Bool { entry.username == currentUsername }

    private var medalColor: Color {
        switch entry.posicion {
        case 1: return ParkTheme.Color.gold
        case 2: return Color(hex: "#94A3B8")
        case 3: return Color(hex: "#CD7F32")
        default: return ParkTheme.Color.textSecond
        }
    }
    private var medalIcon: String {
        switch entry.posicion {
        case 1: return "medal.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isMe ? ParkTheme.Color.accent.opacity(0.2) : ParkTheme.Color.surface)
                    .frame(width: 40, height: 40)
                if entry.posicion <= 3 {
                    Image(systemName: medalIcon)
                        .foregroundStyle(medalColor)
                        .font(.system(size: 18))
                } else {
                    Text("\(entry.posicion)")
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundStyle(ParkTheme.Color.textSecond)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.nombreCompleto.isEmpty ? entry.username : entry.nombreCompleto)
                    .font(.subheadline).fontWeight(isMe ? .bold : .regular)
                    .foregroundStyle(isMe ? ParkTheme.Color.accentLight : ParkTheme.Color.textPrimary)
                Text("@\(entry.username)")
                    .font(.caption2).foregroundStyle(ParkTheme.Color.textSecond)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.1f h", entry.totalHoras))
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(ParkTheme.Color.textPrimary)
                Text("\(entry.totalSesiones) sesiones")
                    .font(.caption2).foregroundStyle(ParkTheme.Color.textSecond)
            }
        }
        .padding(14)
        .background(isMe ? ParkTheme.Color.accent.opacity(0.1) : .clear)
        .glassCard()
    }
}
