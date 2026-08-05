import SwiftUI

struct GuardiaRankingView: View {
    @StateObject private var guardiaVC = GuardiaActividadViewController()
    @State private var now = Date()

    private var mesActual: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "es_EC"); f.dateFormat = "MMMM yyyy"
        return f.string(from: now).capitalized
    }

    private var registrosMes: [HistorialParqueo] {
        let cal = Calendar.current
        let year = cal.component(.year, from: now)
        let month = cal.component(.month, from: now)
        return guardiaVC.registros.filter { r in
            guard let d = parseISODate(r.entryDate) else { return false }
            return cal.component(.year, from: d) == year && cal.component(.month, from: d) == month
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ParkTheme.Color.background.ignoresSafeArea()

                if guardiaVC.isLoading {
                    ProgressView().tint(ParkTheme.Color.accentLight)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            GuardiaRankingHero(mesTexto: mesActual,
                                              totalMes: registrosMes.count,
                                              activasMes: registrosMes.filter(\.estaActivo).count)

                            VStack(spacing: 16) {
                                // Stats card
                                HStack(spacing: 0) {
                                    GuardiaStatChip(label: "Registradas", value: registrosMes.count, color: ParkTheme.Color.gold)
                                    Spacer()
                                    GuardiaStatChip(label: "Activas", value: registrosMes.filter(\.estaActivo).count, color: ParkTheme.Color.disponible)
                                    Spacer()
                                    GuardiaStatChip(label: "Cerradas", value: registrosMes.filter { !$0.estaActivo }.count, color: ParkTheme.Color.textSecond)
                                }
                                .padding(14).glassCard()

                                if registrosMes.isEmpty {
                                    ContentUnavailableView(
                                        "Sin actividad",
                                        systemImage: "shield",
                                        description: Text("No registraste entradas este mes.")
                                    )
                                } else {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Entradas del mes")
                                            .font(.subheadline).fontWeight(.semibold)
                                            .foregroundStyle(ParkTheme.Color.textSecond).padding(.leading, 4)
                                        ForEach(registrosMes.prefix(10)) { r in
                                            GuardiaMesRow(registro: r)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                            .padding(.bottom, 24)
                        }
                    }
                    .refreshable { await guardiaVC.loadRegistros() }
                    .ignoresSafeArea(edges: .top)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await guardiaVC.loadRegistros() }
    }

    private func parseISODate(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: s) ?? ISO8601DateFormatter().date(from: s)
    }
}

// ── HERO ──────────────────────────────────────────────────────────────────────
private struct GuardiaRankingHero: View {
    let mesTexto: String
    let totalMes: Int
    let activasMes: Int
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black.ignoresSafeArea(edges: .top)
            CinematicBackground(accent: Color(hex: "#B45309"), accent2: Color(hex: "#C2410C"))
                .ignoresSafeArea(edges: .top)
            LinearGradient(colors: [.black.opacity(0.38), .black.opacity(0.72)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)

            Text("MES")
                .font(.system(size: 75, weight: .black))
                .foregroundStyle(.white.opacity(0.05))
                .kerning(-3)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 8)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()
                LinearGradient(colors: [.clear, ParkTheme.Color.background],
                               startPoint: .top, endPoint: .bottom).frame(height: 28)
            }

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 64)
                Text("PUCE · ACTIVIDAD DE GUARDIA")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45)).kerning(2.5).padding(.bottom, 14)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Resumen")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(.white.opacity(0.48)).kerning(-1)
                    Text(mesTexto + ".")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white).kerning(-1).padding(.top, -6)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.55).delay(0.2), value: appeared)

                Spacer().frame(height: 20)

                HStack(spacing: 28) {
                    GuardiaHeroStatMini(value: "\(totalMes)", label: "registros", color: ParkTheme.Color.gold)
                    GuardiaHeroStatMini(value: "\(activasMes)", label: "activas", color: ParkTheme.Color.disponible)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.easeOut(duration: 0.5).delay(0.38), value: appeared)

                Spacer().frame(height: 52)
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 310)
        .onAppear { appeared = true }
    }
}

private struct GuardiaHeroStatMini: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 26, weight: .bold)).foregroundStyle(color)
            Text(label).font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
        }
    }
}

private struct GuardiaStatChip: View {
    let label: String; let value: Int; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.title2).fontWeight(.bold).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(ParkTheme.Color.textSecond)
        }
    }
}

private struct GuardiaMesRow: View {
    let registro: HistorialParqueo
    private var hora: String {
        let parts = registro.entryDate.split(separator: "T")
        guard parts.count > 1 else { return "" }
        return String(parts[1].prefix(5))
    }
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(registro.estaActivo ? ParkTheme.Color.disponible.opacity(0.2) : ParkTheme.Color.surface)
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: registro.estaActivo ? "car.fill" : "car")
                    .font(.system(size: 14))
                    .foregroundStyle(registro.estaActivo ? ParkTheme.Color.disponible : ParkTheme.Color.textSecond))
            VStack(alignment: .leading, spacing: 2) {
                Text(registro.vehiclePlate ?? "—")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ParkTheme.Color.textPrimary)
                Text("\(registro.space.zone.name) · \(registro.space.spaceNumber) · \(hora)")
                    .font(.system(size: 11)).foregroundStyle(ParkTheme.Color.textSecond)
            }
            Spacer()
            if registro.estaActivo {
                Text("Activo").font(.caption2).fontWeight(.semibold)
                    .foregroundStyle(ParkTheme.Color.disponible)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(ParkTheme.Color.disponible.opacity(0.15)).clipShape(Capsule())
            }
        }
        .padding(12).glassCard()
    }
}
