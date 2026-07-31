import SwiftUI

struct ZonasListView: View {
    @StateObject private var zonasVC   = ZonasViewController()
    @StateObject private var puestosVC = PuestosViewController()

    var totalDisponibles: Int { zonasVC.zonas.reduce(0) { $0 + $1.puestosDisponibles } }

    var body: some View {
        NavigationStack {
            ZStack {
                ParkTheme.Color.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    // ── Top availability banner ──────────────────────
                    if !zonasVC.zonas.isEmpty {
                        HStack {
                            Image(systemName: "parkingsign").font(.subheadline)
                            Text("\(totalDisponibles) plazas disponibles en el campus")
                                .font(.subheadline).fontWeight(.semibold)
                        }
                        .foregroundStyle(ParkTheme.Color.disponible)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(ParkTheme.Color.disponible.opacity(0.1))
                    }

                    Group {
                        if zonasVC.isLoading {
                            Spacer()
                            ProgressView().tint(ParkTheme.Color.accentLight)
                            Spacer()
                        } else if let err = zonasVC.errorMsg {
                            Spacer()
                            VStack(spacing: 16) {
                                Text(err).foregroundStyle(ParkTheme.Color.ocupado).multilineTextAlignment(.center)
                                Button("Reintentar") { Task { await zonasVC.loadZonas() } }
                                    .foregroundStyle(ParkTheme.Color.accentLight)
                            }.padding()
                            Spacer()
                        } else if zonasVC.zonas.isEmpty {
                            Spacer()
                            ContentUnavailableView("Sin zonas", systemImage: "map",
                                description: Text("No hay zonas de parqueo disponibles."))
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(zonasVC.zonas) { zona in
                                        NavigationLink(
                                            destination: ZonaMapView(
                                                zona: zona,
                                                puestosVC: puestosVC,
                                                onEstadoCambiado: { Task { await zonasVC.loadZonas() } }
                                            )
                                        ) {
                                            ZonaCard(zona: zona)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(16)
                            }
                            .refreshable { await zonasVC.loadZonas() }
                        }
                    }
                }
            }
            .navigationTitle("Zonas de Parqueo")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { await zonasVC.loadZonas() }
    }
}
