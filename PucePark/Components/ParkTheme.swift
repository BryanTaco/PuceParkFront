import SwiftUI

enum ParkTheme {
    enum Color {
        static let background  = SwiftUI.Color(hex: "#0B1120")
        static let surface     = SwiftUI.Color(hex: "#141E35")
        static let card        = SwiftUI.Color(hex: "#1C2A4A")
        static let accent      = SwiftUI.Color(hex: "#2563EB")
        static let accentLight = SwiftUI.Color(hex: "#3B82F6")
        static let disponible  = SwiftUI.Color(hex: "#22C55E")
        static let ocupado     = SwiftUI.Color(hex: "#EF4444")
        static let gold        = SwiftUI.Color(hex: "#F59E0B")
        static let textPrimary = SwiftUI.Color.white
        static let textSecond  = SwiftUI.Color(white: 1, opacity: 0.55)
    }
    enum Radius {
        static let card: CGFloat   = 16
        static let button: CGFloat = 12
        static let chip: CGFloat   = 8
    }
}

extension SwiftUI.Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0; Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ParkTheme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: ParkTheme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: ParkTheme.Radius.card)
                    .strokeBorder(SwiftUI.Color.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
}

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading { ProgressView().tint(.white) }
                else { Text(title).fontWeight(.semibold) }
            }
            .frame(maxWidth: .infinity).frame(height: 50)
        }
        .background(ParkTheme.Color.accent)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: ParkTheme.Radius.button))
        .disabled(isLoading)
    }
}

struct OcupacionBar: View {
    let zona: ZonaParqueo
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(zona.availableSpaces) disponibles")
                    .font(.caption).foregroundStyle(ParkTheme.Color.disponible)
                Spacer()
                Text("\(zona.occupiedSpaces)/\(zona.totalSpaces)")
                    .font(.caption).foregroundStyle(ParkTheme.Color.textSecond)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(ParkTheme.Color.card).frame(height: 6)
                    Capsule()
                        .fill(zona.porcentajeOcupacion > 0.8 ? ParkTheme.Color.ocupado : ParkTheme.Color.disponible)
                        .frame(width: geo.size.width * zona.porcentajeOcupacion, height: 6)
                }
            }.frame(height: 6)
        }
    }
}
