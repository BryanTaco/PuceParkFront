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
                Group {
                    if historialVC.isLoading {
                        ProgressView().tint(ParkTheme.Color.accentLight)
                    } else if let err = historialVC.errorMsg {
                        VStack(spacing: 12) {
                            Text(err).foregroundStyle(ParkTheme.Color.ocupado).multilineTextAlignment(.center)
                            Button("Reintentar") { Task { await historialVC.loadHistorial() } }
                                .foregroundStyle(ParkTheme.Color.accentLight)
                        }.padding()
                    } else if historialVC.historial.isEmpty {
                        ContentUnavailableView("Sin registros", systemImage: "clock",
                            description: Text("Aún no tienes sesiones de parqueo."))
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                // Active session banner
                                if let activa = historialVC.sesionesActivas.first {
                                    ActiveSessionBanner(sesion: activa, now: now)
                                }
                                // Monthly stats
                                if let stats = historialVC.estadisticas {
                                    StatsCard(stats: stats, racha: racha)
                                }
                                // Historial list
                                if !historialVC.sesionesCompletadas.isEmpty {
                                    SectionBlock(title: "Historial") {
                                        ForEach(historialVC.sesionesCompletadas) { h in HistorialRow(entrada: h) }
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .refreshable { await historialVC.loadHistorial() }
                    }
                }
            }
            .navigationTitle("Actividad")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onReceive(ticker) { now = $0 }
        .task { await historialVC.loadHistorial() }
    }

    private var racha: Int {
        let cal = Calendar.current
        let dias = Set(historialVC.historial.compactMap { h -> Date? in
            guard let d = parseISO(h.fechaIngreso) else { return nil }
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

// ── Active session banner ─────────────────────────────────────────────────
private struct ActiveSessionBanner: View {
    let sesion: HistorialParqueo
    let now: Date

    private var duracion: String {
        guard let start = parseISO(sesion.fechaIngreso) else { return "En curso" }
        let secs = max(0, Int(now.timeIntervalSince(start)))
        let h = secs / 3600; let m = (secs % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Sesión activa", systemImage: "car.fill")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(ParkTheme.Color.disponible)
                Spacer()
                PulsingDot()
            }
            Text("Llevas \(duracion)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("en \(sesion.puesto.zona.nombre) · Puesto \(sesion.puesto.numeroPuesto)")
                .font(.subheadline).foregroundStyle(ParkTheme.Color.textSecond)
            Text("Ticket: \(sesion.codigoTicket)")
                .font(.caption2).fontDesign(.monospaced)
                .foregroundStyle(ParkTheme.Color.accentLight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(colors: [ParkTheme.Color.disponible.opacity(0.15), ParkTheme.Color.card],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .glassCard()
    }
}

// ── Stats ─────────────────────────────────────────────────────────────────
private struct StatsCard: View {
    let stats: EstadisticasPersonales
    let racha: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Este mes").font(.caption).fontWeight(.semibold).foregroundStyle(ParkTheme.Color.textSecond)
            HStack(spacing: 0) {
                StatItem(icon: "clock.fill",     value: String(format: "%.1f h", stats.totalHoras),              label: "Horas",    color: ParkTheme.Color.accentLight)
                Spacer()
                StatItem(icon: "car.fill",       value: "\(stats.totalSesiones)",                                 label: "Sesiones", color: ParkTheme.Color.disponible)
                Spacer()
                StatItem(icon: "flame.fill",     value: racha > 0 ? "\(racha) días" : "—",                       label: "Racha",    color: ParkTheme.Color.gold)
            }
        }
        .padding(16).glassCard()
    }
}

private struct StatItem: View {
    let icon: String; let value: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color).font(.subheadline)
            Text(value).font(.title3).fontWeight(.bold).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(ParkTheme.Color.textSecond)
        }
    }
}

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

private struct PulsingDot: View {
    @State private var pulse = false
    var body: some View {
        Circle().fill(ParkTheme.Color.disponible).frame(width: 8, height: 8)
            .scaleEffect(pulse ? 1.4 : 1).opacity(pulse ? 0.5 : 1)
            .animation(.easeInOut(duration: 1).repeatForever(), value: pulse)
            .onAppear { pulse = true }
    }
}

private func parseISO(_ s: String) -> Date? {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = f.date(from: s) { return d }
    f.formatOptions = [.withInternetDateTime]
    return f.date(from: s)
}
