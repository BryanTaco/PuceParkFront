import SwiftUI

struct GuardiaActividadView: View {
    @StateObject private var guardiaVC = GuardiaActividadViewController()

    var body: some View {
        NavigationStack {
            ZStack {
                ParkTheme.Color.background.ignoresSafeArea()

                if guardiaVC.isLoading {
                    ProgressView().tint(ParkTheme.Color.accentLight)
                } else if let err = guardiaVC.errorMsg {
                    VStack(spacing: 12) {
                        Text(err).foregroundStyle(ParkTheme.Color.ocupado).multilineTextAlignment(.center)
                        Button("Reintentar") { Task { await guardiaVC.loadRegistros() } }
                            .foregroundStyle(ParkTheme.Color.accentLight)
                    }.padding()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            GuardiaHero(total: guardiaVC.registros.count, activas: guardiaVC.activas.count)

                            VStack(spacing: 16) {
                                if guardiaVC.registros.isEmpty {
                                    ContentUnavailableView(
                                        "Sin registros",
                                        systemImage: "shield",
                                        description: Text("Aún no has registrado ninguna entrada.")
                                    )
                                } else {
                                    if !guardiaVC.activas.isEmpty {
                                        GuardiaSectionBlock(title: "Entradas activas") {
                                            ForEach(guardiaVC.activas) { r in
                                                GuardiaRegistroRow(registro: r)
                                            }
                                        }
                                    }
                                    if !guardiaVC.cerradas.isEmpty {
                                        GuardiaSectionBlock(title: "Historial") {
                                            ForEach(guardiaVC.cerradas) { r in
                                                GuardiaRegistroRow(registro: r)
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
                    .refreshable { await guardiaVC.loadRegistros() }
                    .ignoresSafeArea(edges: .top)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await guardiaVC.loadRegistros() }
    }
}

// ── HERO ──────────────────────────────────────────────────────────────────────
private struct GuardiaHero: View {
    let total: Int
    let activas: Int
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black.ignoresSafeArea(edges: .top)

            CinematicBackground(
                accent:  Color(hex: "#B45309"),
                accent2: Color(hex: "#DC2626")
            )
            .ignoresSafeArea(edges: .top)

            LinearGradient(
                colors: [.black.opacity(0.38), .black.opacity(0.72)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

            Text("GUARDIA")
                .font(.system(size: 75, weight: .black))
                .foregroundStyle(.white.opacity(0.038))
                .kerning(-4)
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

                Text("PUCE · CONTROL DE ACCESO")
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

                HStack(spacing: 28) {
                    GuardiaHeroStat(value: "\(total)", label: "registros", color: ParkTheme.Color.gold)
                    GuardiaHeroStat(value: "\(activas)", label: "activos", color: ParkTheme.Color.disponible)
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

private struct GuardiaHeroStat: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 26, weight: .bold)).foregroundStyle(color)
            Text(label).font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
        }
    }
}

// ── ROW ───────────────────────────────────────────────────────────────────────
private struct GuardiaRegistroRow: View {
    let registro: HistorialParqueo

    private var hora: String {
        let parts = registro.fechaIngreso.split(separator: "T")
        guard parts.count > 1 else { return registro.fechaIngreso }
        return String(parts[1].prefix(5))
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(registro.estaActivo ? ParkTheme.Color.disponible.opacity(0.2) : ParkTheme.Color.textSecond.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: registro.estaActivo ? "car.fill" : "car")
                        .font(.system(size: 18))
                        .foregroundStyle(registro.estaActivo ? ParkTheme.Color.disponible : ParkTheme.Color.textSecond)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(registro.placaVehiculo ?? "—")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ParkTheme.Color.textPrimary)
                    if registro.estaActivo {
                        Text("Activo")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(ParkTheme.Color.disponible)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(ParkTheme.Color.disponible.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Text("\(registro.puesto.zona.nombre) · Puesto \(registro.puesto.numeroPuesto) · \(hora)")
                    .font(.system(size: 12))
                    .foregroundStyle(ParkTheme.Color.textSecond)
            }

            Spacer()
        }
        .padding(12)
        .glassCard()
    }
}

private struct GuardiaSectionBlock<Content: View>: View {
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
