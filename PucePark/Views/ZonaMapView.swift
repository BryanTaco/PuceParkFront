import SwiftUI

struct ZonaMapView: View {
    let zona: ZonaParqueo
    @ObservedObject var puestosVC: PuestosViewController
    var onEstadoCambiado: (() -> Void)? = nil
    @Environment(\.authSession) private var session
    @State private var sheetPuesto: PuestoParqueo?

    private let columns = [GridItem(.flexible()), GridItem(.flexible()),
                           GridItem(.flexible()), GridItem(.flexible())]

    private var disponibles: Int { puestosVC.puestos.filter { $0.estado == .DISPONIBLE }.count }
    private var ocupados:    Int { puestosVC.puestos.filter { $0.estado == .OCUPADO  }.count }

    var body: some View {
        ZStack {
            // Campus map background
            ZStack {
                ParkTheme.Color.background.ignoresSafeArea()
                Image("bg_mapa")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.18)
            }
            Group {
                if puestosVC.isLoading {
                    ProgressView().tint(ParkTheme.Color.accentLight)
                } else if let err = puestosVC.errorMsg {
                    VStack(spacing: 12) {
                        Text(err).foregroundStyle(ParkTheme.Color.ocupado).multilineTextAlignment(.center)
                        Button("Reintentar") { Task { await puestosVC.loadPuestosDeZona(zonaId: zona.id) } }
                            .foregroundStyle(ParkTheme.Color.accentLight)
                    }.padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Stats banner — computed live from puestosVC so it updates instantly
                            HStack(spacing: 0) {
                                StatChip(label: "Disponibles", value: disponibles, color: ParkTheme.Color.disponible)
                                Spacer()
                                StatChip(label: "Ocupados",    value: ocupados,    color: ParkTheme.Color.ocupado)
                                Spacer()
                                StatChip(label: "Total",       value: disponibles + ocupados, color: ParkTheme.Color.accentLight)
                            }
                            .padding(14).glassCard()

                            // Grid per fila
                            ForEach(puestosVC.filas, id: \.self) { fila in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Fila \(fila)")
                                        .font(.caption).fontWeight(.semibold)
                                        .foregroundStyle(ParkTheme.Color.textSecond)
                                    LazyVGrid(columns: columns, spacing: 8) {
                                        ForEach(puestosVC.puestosEnFila(fila)) { puesto in
                                            PuestoCell(puesto: puesto)
                                                .onTapGesture { sheetPuesto = puesto }
                                        }
                                    }
                                }
                            }

                            // Legend
                            HStack(spacing: 20) {
                                LegendDot(color: ParkTheme.Color.disponible, label: "Disponible")
                                LegendDot(color: ParkTheme.Color.ocupado,    label: "Ocupado")
                            }
                            .padding(.top, 4)
                        }
                        .padding(16)
                    }
                    .refreshable { await puestosVC.loadPuestosDeZona(zonaId: zona.id) }
                }
            }
        }
        .navigationTitle(zona.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await puestosVC.loadPuestosDeZona(zonaId: zona.id) }
        .sheet(item: $sheetPuesto) { p in
            PuestoSheet(puesto: p, puestosVC: puestosVC, session: session) {
                sheetPuesto = puestosVC.puestoSeleccionado
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(ParkTheme.Color.surface)
            .onDisappear { onEstadoCambiado?() }
        }
    }
}

private struct PuestoCell: View {
    let puesto: PuestoParqueo
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(puesto.estado == .DISPONIBLE ? ParkTheme.Color.disponible.opacity(0.2) : ParkTheme.Color.ocupado.opacity(0.2))
                .frame(height: 52)
                .overlay(
                    VStack(spacing: 2) {
                        Image(systemName: puesto.estado == .DISPONIBLE ? "car" : "car.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(puesto.estado == .DISPONIBLE ? ParkTheme.Color.disponible : ParkTheme.Color.ocupado)
                        Text(puesto.numeroPuesto)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(puesto.estado == .DISPONIBLE ? ParkTheme.Color.disponible : ParkTheme.Color.ocupado)
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(puesto.estado == .DISPONIBLE ? ParkTheme.Color.disponible.opacity(0.4) : ParkTheme.Color.ocupado.opacity(0.4), lineWidth: 1))
        }
    }
}

private struct PuestoSheet: View {
    let puesto: PuestoParqueo
    @ObservedObject var puestosVC: PuestosViewController
    let session: AuthSession?
    let onActualizado: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 4)
            VStack(spacing: 8) {
                Text("Puesto \(puesto.numeroPuesto)")
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(ParkTheme.Color.textPrimary)
                Text("Zona \(puesto.zona.nombre) · Fila \(puesto.fila) · Orden \(puesto.orden)")
                    .font(.caption).foregroundStyle(ParkTheme.Color.textSecond)
                Label(puesto.estado == .DISPONIBLE ? "Disponible" : "Ocupado",
                      systemImage: puesto.estado == .DISPONIBLE ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(puesto.estado == .DISPONIBLE ? ParkTheme.Color.disponible : ParkTheme.Color.ocupado)
                    .font(.subheadline).fontWeight(.semibold)
            }

            if let err = puestosVC.errorMsg {
                Text(err).font(.caption).foregroundStyle(ParkTheme.Color.ocupado).multilineTextAlignment(.center)
            }
            if let ok = puestosVC.successMsg {
                Text(ok).font(.caption).foregroundStyle(ParkTheme.Color.disponible)
            }

            VStack(spacing: 12) {
                if puesto.estado == .DISPONIBLE {
                    PrimaryButton(title: "Ocupar este puesto", isLoading: puestosVC.isActualizando) {
                        Task { await puestosVC.ocupar(puestoId: puesto.id); onActualizado() }
                    }
                } else {
                    PrimaryButton(title: "Liberar puesto", isLoading: puestosVC.isActualizando) {
                        Task { await puestosVC.liberar(puestoId: puesto.id); onActualizado() }
                    }
                    if session?.isAdmin == true || session?.isGuard == true {
                        Button {
                            Task { await puestosVC.forzarLiberacion(puestoId: puesto.id); onActualizado() }
                        } label: {
                            Label("Forzar liberación", systemImage: "exclamationmark.triangle.fill")
                                .frame(maxWidth: .infinity).frame(height: 50)
                        }
                        .buttonStyle(.bordered)
                        .tint(ParkTheme.Color.gold)
                        .disabled(puestosVC.isActualizando)
                    }
                }
                Button("Cerrar") { dismiss() }
                    .foregroundStyle(ParkTheme.Color.textSecond)
            }
            .padding(.horizontal, 28)
            Spacer()
        }
    }
}

private struct StatChip: View {
    let label: String; let value: Int; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.title2).fontWeight(.bold).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(ParkTheme.Color.textSecond)
        }
    }
}

private struct LegendDot: View {
    let color: Color; let label: String
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.caption).foregroundStyle(ParkTheme.Color.textSecond)
        }
    }
}

// Environment key for AuthSession
private struct AuthSessionKey: EnvironmentKey {
    static let defaultValue: AuthSession? = nil
}
extension EnvironmentValues {
    var authSession: AuthSession? {
        get { self[AuthSessionKey.self] }
        set { self[AuthSessionKey.self] = newValue }
    }
}
