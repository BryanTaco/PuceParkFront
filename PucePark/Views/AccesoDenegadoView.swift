import SwiftUI

struct AccesoDenegadoView: View {
    var titulo: String      = "Acceso Denegado"
    var descripcion: String = "No tienes permiso para realizar esta acción."
    var accion: (() -> Void)? = nil
    var labelAccion: String = "Volver"

    @State private var aparecer = false
    @State private var girar    = false
    @State private var pulsar   = false
    @State private var temblar  = false

    var body: some View {
        ZStack {

            // ── GRADIENT BACKGROUND ───────────────────────────────────────
            LinearGradient(
                colors: [Color(hex: "#04080F"), ParkTheme.Color.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // ── LARGE "403" BACKGROUND TEXT ───────────────────────────────
            // Mask fades to transparent at the bottom (same trick as TinyTrails web)
            Text("403")
                .font(.system(size: 220, weight: .black))
                .foregroundStyle(.white.opacity(0.045))
                .kerning(-10)
                .scaleEffect(x: 1.15, y: 1.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.30),
                            .init(color: .clear, location: 0.90)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // ── STAR FIELD (subtle depth) ─────────────────────────────────
            StarField()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // ── MAIN CONTENT ──────────────────────────────────────────────
            VStack(spacing: 0) {
                Spacer()

                // ── ANIMATED LOCK ICON ────────────────────────────────────
                ZStack {
                    // Outermost pulsing rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .strokeBorder(
                                ParkTheme.Color.accentLight.opacity(0.10 - Double(i) * 0.025),
                                lineWidth: 1
                            )
                            .frame(
                                width: CGFloat(108 + i * 38),
                                height: CGFloat(108 + i * 38)
                            )
                            .scaleEffect(pulsar ? 1.08 : 0.92)
                            .animation(
                                .easeInOut(duration: 1.8 + Double(i) * 0.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.25),
                                value: pulsar
                            )
                    }

                    // Rotating gradient arc
                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    ParkTheme.Color.accentLight.opacity(0),
                                    ParkTheme.Color.accentLight.opacity(0.85)
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 86, height: 86)
                        .rotationEffect(.degrees(girar ? 360 : 0))
                        .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: girar)

                    // Center circle
                    Circle()
                        .fill(ParkTheme.Color.surface)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .strokeBorder(ParkTheme.Color.accentLight.opacity(0.22), lineWidth: 1)
                        )
                        .shadow(color: ParkTheme.Color.accent.opacity(0.3), radius: 16)

                    // Lock icon — shakes on tap
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(ParkTheme.Color.accentLight)
                        .offset(x: temblar ? -4 : 0)
                        .animation(
                            temblar
                                ? .interpolatingSpring(stiffness: 650, damping: 6)
                                    .repeatCount(6, autoreverses: true)
                                : .default,
                            value: temblar
                        )
                }
                .opacity(aparecer ? 1 : 0)
                .scaleEffect(aparecer ? 1 : 0.45)
                .animation(.spring(duration: 0.85, bounce: 0.45).delay(0.15), value: aparecer)
                .onTapGesture {
                    guard !temblar else { return }
                    temblar = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { temblar = false }
                }

                Spacer().frame(height: 44)

                // ── TITLE ─────────────────────────────────────────────────
                Text(titulo)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(ParkTheme.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(aparecer ? 1 : 0)
                    .offset(y: aparecer ? 0 : 24)
                    .animation(.easeOut(duration: 0.6).delay(0.40), value: aparecer)

                Spacer().frame(height: 10)

                // ── DESCRIPTION ───────────────────────────────────────────
                Text(descripcion)
                    .font(.system(size: 15))
                    .foregroundStyle(ParkTheme.Color.textSecond)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 44)
                    .opacity(aparecer ? 1 : 0)
                    .offset(y: aparecer ? 0 : 16)
                    .animation(.easeOut(duration: 0.6).delay(0.55), value: aparecer)

                Spacer().frame(height: 36)

                // ── ACTION BUTTON ─────────────────────────────────────────
                if let accion {
                    Button(action: accion) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text(labelAccion)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(height: 50)
                        .padding(.horizontal, 36)
                        .background(ParkTheme.Color.accent)
                        .clipShape(Capsule())
                    }
                    .opacity(aparecer ? 1 : 0)
                    .scaleEffect(aparecer ? 1 : 0.94)
                    .animation(.easeOut(duration: 0.5).delay(0.70), value: aparecer)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            aparecer = true
            girar    = true
            pulsar   = true
        }
    }
}

// ── STAR FIELD ─────────────────────────────────────────────────────────────
private struct StarField: View {
    private struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let delay: Double
        let opacityOff: Double
        let opacityOn: Double
        let duration: Double
    }

    private let stars: [Star] = (0..<40).map { i in
        Star(
            id: i,
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...0.65),
            size: CGFloat.random(in: 1...2.5),
            delay: Double.random(in: 0...3),
            opacityOff: Double.random(in: 0.08...0.35),
            opacityOn:  Double.random(in: 0.30...0.70),
            duration:   Double.random(in: 1.5...3.5)
        )
    }

    @State private var twinkle = false

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { star in
                Circle()
                    .fill(.white)
                    .frame(width: star.size, height: star.size)
                    .position(
                        x: star.x * geo.size.width,
                        y: star.y * geo.size.height
                    )
                    .opacity(twinkle ? star.opacityOn : star.opacityOff)
                    .animation(
                        .easeInOut(duration: star.duration)
                        .repeatForever(autoreverses: true)
                        .delay(star.delay),
                        value: twinkle
                    )
            }
        }
        .onAppear { twinkle = true }
    }
}
