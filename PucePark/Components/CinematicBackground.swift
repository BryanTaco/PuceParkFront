import SwiftUI

// Animated blob background — used in all tab heroes
// accent / accent2 drive the blob colors (different per tab)
struct CinematicBackground: View {
    var accent:  Color
    var accent2: Color

    @State private var phase = false

    var body: some View {
        ZStack {
            // Blob 1 — large, slow drift
            Circle()
                .fill(accent.opacity(0.60))
                .frame(width: 400, height: 400)
                .offset(x: phase ? -110 : 70, y: phase ? -130 : 30)
                .blur(radius: 90)
                .animation(
                    .easeInOut(duration: 9).repeatForever(autoreverses: true),
                    value: phase
                )

            // Blob 2 — medium, counter-drift
            Circle()
                .fill(accent2.opacity(0.45))
                .frame(width: 320, height: 320)
                .offset(x: phase ? 130 : -80, y: phase ? 70 : -110)
                .blur(radius: 75)
                .animation(
                    .easeInOut(duration: 7).repeatForever(autoreverses: true).delay(2),
                    value: phase
                )

            // Blob 3 — small, fast accent highlight
            Circle()
                .fill(accent.opacity(0.25))
                .frame(width: 210, height: 210)
                .offset(x: phase ? 20 : -130, y: phase ? -90 : 130)
                .blur(radius: 55)
                .animation(
                    .easeInOut(duration: 5.2).repeatForever(autoreverses: true).delay(4.5),
                    value: phase
                )

            // Blob 4 — subtle warm fill at bottom-right
            Circle()
                .fill(accent2.opacity(0.18))
                .frame(width: 280, height: 280)
                .offset(x: phase ? 90 : -20, y: phase ? 120 : -40)
                .blur(radius: 65)
                .animation(
                    .easeInOut(duration: 6).repeatForever(autoreverses: true).delay(1),
                    value: phase
                )

            // Dot grid texture — radiates from center
            Canvas { ctx, size in
                let spacing: CGFloat = 26
                let dotR:    CGFloat = 1.1
                let cols = Int(size.width  / spacing) + 2
                let rows = Int(size.height / spacing) + 2
                let cx = size.width  * 0.5
                let cy = size.height * 0.35
                let maxD = hypot(size.width * 0.6, size.height * 0.6)

                for col in 0...cols {
                    for row in 0...rows {
                        let x = CGFloat(col) * spacing
                        let y = CGFloat(row) * spacing
                        let dist = hypot(x - cx, y - cy)
                        let op   = max(0, Double(1 - dist / maxD) * 0.20)
                        ctx.fill(
                            Path(ellipseIn: CGRect(
                                x: x - dotR, y: y - dotR,
                                width: dotR * 2, height: dotR * 2
                            )),
                            with: .color(.white.opacity(op))
                        )
                    }
                }
            }
        }
        .onAppear { phase = true }
    }
}
