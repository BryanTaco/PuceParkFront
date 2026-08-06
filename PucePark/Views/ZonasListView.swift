import SwiftUI

struct ZonasListView: View {
    @StateObject private var zonasVC    = ZonasViewController()
    @StateObject private var historialVC = HistorialViewController()
    @State private var isLiberando = false

    var totalDisponibles: Int { zonasVC.zonas.reduce(0) { $0 + $1.availableSpaces } }
    var totalOcupados:    Int { zonasVC.zonas.reduce(0) { $0 + $1.occupiedSpaces  } }

    private var sesionActiva: HistorialParqueo? { historialVC.sesionesActivas.first }
    @State private var zonaSeleccionada: ZonaParqueo?

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

                            if let sesion = sesionActiva {
                                DesocuparBanner(
                                    sesion: sesion,
                                    isLiberando: $isLiberando,
                                    onDesocupar: {
                                        Task {
                                            isLiberando = true
                                            _ = try? await ParkService.shared.liberarPuesto(id: sesion.space.id)
                                            await historialVC.loadHistorial()
                                            await zonasVC.loadZonas()
                                            isLiberando = false
                                        }
                                    }
                                )
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                            }

                            LazyVStack(spacing: 12) {
                                if zonasVC.zonas.isEmpty {
                                    ContentUnavailableView(
                                        "Sin zonas",
                                        systemImage: "map",
                                        description: Text("No hay zonas de parqueo disponibles.")
                                    )
                                } else {
                                    ForEach(zonasVC.zonas) { zona in
                                        Button { zonaSeleccionada = zona } label: {
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
        .task {
            await zonasVC.loadZonas()
            await historialVC.loadHistorial()
        }
        .onAppear {
            // Recarga silenciosa al volver al tab — refleja cambios hechos en otras pantallas
            if zonasVC.didLoadOnce {
                Task {
                    await zonasVC.loadZonas(silent: true)
                    await historialVC.loadHistorial(silent: true)
                }
            }
        }
        .fullScreenCover(item: $zonaSeleccionada) { zona in
            ZonaMapView(
                zona: zona,
                onEstadoCambiado: { Task { await zonasVC.loadZonas(); await historialVC.loadHistorial() } },
                miPuestoId: sesionActiva?.space.id
            )
        }
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

// ── Banner de puesto activo con botón desocupar ───────────────────────────────
private struct DesocuparBanner: View {
    let sesion: HistorialParqueo
    @Binding var isLiberando: Bool
    let onDesocupar: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ParkTheme.Color.disponible.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "car.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(ParkTheme.Color.disponible)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Tienes un puesto activo")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ParkTheme.Color.textPrimary)
                Text("\(sesion.space.zone.name) · \(sesion.space.spaceNumber)")
                    .font(.system(size: 12))
                    .foregroundStyle(ParkTheme.Color.textSecond)
            }

            Spacer()

            Button(action: onDesocupar) {
                Group {
                    if isLiberando {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    } else {
                        Text("Desocupar")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 88, height: 34)
                .background(ParkTheme.Color.ocupado)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(isLiberando)
        }
        .padding(14)
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: ParkTheme.Radius.card)
                .strokeBorder(ParkTheme.Color.disponible.opacity(0.4), lineWidth: 1)
        )
    }
}
