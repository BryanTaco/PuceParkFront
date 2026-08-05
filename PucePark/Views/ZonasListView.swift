import SwiftUI

struct ZonasListView: View {
    @StateObject private var zonasVC = ZonasViewController()

    var totalDisponibles: Int { zonasVC.zonas.reduce(0) { $0 + $1.availableSpaces } }
    var totalOcupados:    Int { zonasVC.zonas.reduce(0) { $0 + $1.occupiedSpaces  } }

    var body: some View {
        NavigationStack {
            ZStack {
                ParkTheme.Color.background.ignoresSafeArea()

                if zonasVC.isLoading {
                    ProgressView().tint(ParkTheme.Color.accentLight)

                } else if let err = zonasVC.errorMsg {
                    VStack(spacing: 12) {
                        Text(err).foregroundStyle(ParkTheme.Color.ocupado).multilineTextAlignment(.center)
                        Button("Reintentar") { Task { await zonasVC.loadZonas() } }
                            .foregroundStyle(ParkTheme.Color.accentLight)
                    }.padding()

                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ZonasHero(
                                totalDisponibles: totalDisponibles,
                                totalOcupados: totalOcupados
                            )

                            LazyVStack(spacing: 12) {
                                if zonasVC.zonas.isEmpty {
                                    ContentUnavailableView(
                                        "Sin zonas",
                                        systemImage: "map",
                                        description: Text("No hay zonas de parqueo disponibles.")
                                    )
                                } else {
                                    ForEach(zonasVC.zonas) { zona in
                                        NavigationLink(
                                            destination: ZonaMapView(
                                                zona: zona,
                                                onEstadoCambiado: { Task { await zonasVC.loadZonas() } }
                                            )
                                        ) {
                                            ZonaCard(zona: zona)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(16)
                            .padding(.bottom, 24)
                        }
                    }
                    .refreshable { await zonasVC.loadZonas() }
                    .ignoresSafeArea(edges: .top)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await zonasVC.loadZonas() }
    }
}

// ── CINEMATIC HERO ────────────────────────────────────────────────────────────
private struct ZonasHero: View {
    let totalDisponibles: Int
    let totalOcupados: Int
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            // Base
            Color.black.ignoresSafeArea(edges: .top)

            // Animated blobs — blue / cyan
            CinematicBackground(
                accent:  Color(hex: "#1D4ED8"),
                accent2: Color(hex: "#0891B2")
            )
            .ignoresSafeArea(edges: .top)

            // Dark scrim — keeps text readable
            LinearGradient(
                colors: [.black.opacity(0.38), .black.opacity(0.72)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

            // Background large text (cinematic)
            Text("PARK")
                .font(.system(size: 75, weight: .black))
                .foregroundStyle(.white.opacity(0.05))
                .kerning(-3)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 8)
                .allowsHitTesting(false)

            // Bottom gradient fade → ParkTheme.Color.background
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, ParkTheme.Color.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 28)
            }

            // Hero content
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 64)     // status bar clearance

                // Upper label
                Text("PUCE · PARQUEO INTELIGENTE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .kerning(2.5)
                    .padding(.bottom, 14)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)

                // Overlapping headings (TinyTrails style)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Zonas de")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(.white.opacity(0.48))
                        .kerning(-1)
                    Text("Parqueo.")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .kerning(-1)
                        .padding(.top, -8)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.55).delay(0.2), value: appeared)

                Spacer().frame(height: 22)

                // Stats row
                HStack(spacing: 28) {
                    HeroStat(value: "\(totalDisponibles)", label: "disponibles", color: ParkTheme.Color.disponible)
                    HeroStat(value: "\(totalOcupados)",    label: "ocupados",    color: ParkTheme.Color.ocupado)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
                .animation(.easeOut(duration: 0.5).delay(0.38), value: appeared)

                Spacer().frame(height: 52)
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 310)
        .onAppear { appeared = true }
    }
}

private struct HeroStat: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.55))
        }
    }
}
