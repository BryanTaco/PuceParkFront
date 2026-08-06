import SwiftUI
import Combine

struct HistorialView: View {
    @StateObject private var historialVC = HistorialViewController()
    @State private var now = Date()
    private let ticker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                ParkTheme.Color.background.ignoresSafeArea()

                if historialVC.isLoading {
                    ProgressView().tint(ParkTheme.Color.accentLight)
                } else if let err = historialVC.errorMsg {
                    VStack(spacing: 12) {
                        Text(err).foregroundStyle(ParkTheme.Color.ocupado).multilineTextAlignment(.center)
                        Button("Reintentar") { Task { await historialVC.loadHistorial() } }
                            .foregroundStyle(ParkTheme.Color.accentLight)
                    }.padding()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            HistorialHero(
                                stats:  historialVC.estadisticas,
                                racha:  racha,
                                activa: historialVC.sesionesActivas.first,
                                now:    now
                            )

                            VStack(spacing: 16) {
                                if historialVC.historial.isEmpty {
                                    ContentUnavailableView(
                                        "Sin registros",
                                        systemImage: "clock",
                                        description: Text("Aún no tienes sesiones de parqueo.")
                                    )
                                } else {
                                    if !historialVC.sesionesCompletadas.isEmpty {
                                        SectionBlock(title: "Historial") {
                                            ForEach(historialVC.sesionesCompletadas) { h in
                                                HistorialRow(entrada: h)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                            .padding(.bottom, 24)
                        }
                    }
                    .refreshable { await historialVC.loadHistorial() }
                    .ignoresSafeArea(edges: .top)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onReceive(ticker) { now = $0 }
        .task { await historialVC.loadHistorial() }
        .onAppear {
            // Recarga silenciosa al volver al tab — refleja parqueos hechos en otras pantallas
            if historialVC.didLoadOnce {
                Task { await historialVC.loadHistorial(silent: true) }
            }
        }
    }

    private var racha: Int {
        let cal = Calendar.current
        let dias = Set(historialVC.historial.compactMap { h -> Date? in
            guard let d = parseISO(h.entryDate) else { return nil }
            return cal.startOfDay(for: d)
        }).sorted(by: >)
        var streak = 0
        var cursor = cal.startOfDay(for: Date())
        for dia in dias {
            if dia == cursor { streak += 1; cursor = cal.date(byAdding: .day, value: -1, to: cursor)! }
            else if dia < cursor { break }
        }
        return streak
    }
}

// ── CINEMATIC HERO ────────────────────────────────────────────────────────────
private struct HistorialHero: View {
    let stats:  EstadisticasPersonales?
    let racha:  Int
    let activa: HistorialParqueo?
    let now:    Date
    @State private var appeared = false

    private var duracion: String {
        guard let a = activa, let start = parseISO(a.entryDate) else { return "—" }
        let secs = max(0, Int(now.timeIntervalSince(start)))
        let h = secs / 3600; let m = (secs % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            Color.black.ignoresSafeArea(edges: .top)

            // Animated blobs — green / teal
            CinematicBackground(
                accent:  Color(hex: "#15803D"),
                accent2: Color(hex: "#0D9488")
            )
            .ignoresSafeArea(edges: .top)

            LinearGradient(
                colors: [.black.opacity(0.38), .black.opacity(0.72)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

            Text("TIEMPO")
                .font(.system(size: 75, weight: .black))
                .foregroundStyle(.white.opacity(0.05))
                .kerning(-3)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, -10)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, ParkTheme.Color.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 28)
            }

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 64)

                Text("PUCE · REGISTRO DE ACTIVIDAD")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .kerning(2.5)
                    .padding(.bottom, 14)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Mi")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(.white.opacity(0.48))
                        .kerning(-1)
                    Text("Actividad.")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .kerning(-1)
                        .padding(.top, -8)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.55).delay(0.2), value: appeared)

                Spacer().frame(height: 20)

                // Stats or active session
                if let activa {
                    HStack(spacing: 6) {
                        PulsingDot()
                        Text("Activo · \(activa.space.zone.name) · \(duracion)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(ParkTheme.Color.disponible)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(ParkTheme.Color.disponible.opacity(0.15))
                    .clipShape(Capsule())
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)
                } else if let s = stats {
                    HStack(spacing: 28) {
                        HeroStatSmall(value: String(format: "%.1fh", s.totalHours), label: "este mes", color: ParkTheme.Color.accentLight)
                        HeroStatSmall(value: "\(s.totalSessions)", label: "sesiones", color: ParkTheme.Color.disponible)
                        if racha > 0 {
                            HeroStatSmall(value: "\(racha)d", label: "racha", color: ParkTheme.Color.gold)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.5).delay(0.38), value: appeared)
                }

                Spacer().frame(height: 52)
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 310)
        .onAppear { appeared = true }
    }
}

private struct HeroStatSmall: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 26, weight: .bold)).foregroundStyle(color)
            Text(label).font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
        }
    }
}

private struct PulsingDot: View {
    @State private var pulse = false
    var body: some View {
        Circle().fill(ParkTheme.Color.disponible).frame(width: 7, height: 7)
            .scaleEffect(pulse ? 1.4 : 1).opacity(pulse ? 0.5 : 1)
            .animation(.easeInOut(duration: 1).repeatForever(), value: pulse)
            .onAppear { pulse = true }
    }
}

// ── Section block ─────────────────────────────────────────────────────────────
private struct SectionBlock<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(ParkTheme.Color.textSecond).padding(.leading, 4)
            content()
        }
    }
}

// ── ISO date parser ───────────────────────────────────────────────────────────
private func parseISO(_ s: String) -> Date? {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = f.date(from: s) { return d }
    f.formatOptions = [.withInternetDateTime]
    return f.date(from: s)
}
