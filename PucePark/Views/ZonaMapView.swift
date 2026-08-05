import SwiftUI

struct ZonaMapView: View {
    let zona: ZonaParqueo
    @ObservedObject var puestosVC: PuestosViewController
    var onEstadoCambiado: (() -> Void)? = nil
    @Environment(\.authSession) private var session
    @State private var sheetPuesto: PuestoParqueo?

    private let columns = [GridItem(.flexible()), GridItem(.flexible()),
                           GridItem(.flexible()), GridItem(.flexible())]

    private var disponibles: Int { puestosVC.puestos.filter { $0.status == .DISPONIBLE }.count }
    private var ocupados:    Int { puestosVC.puestos.filter { $0.status == .OCUPADO  }.count }

    private func esAcceso(_ msg: String) -> Bool {
        let low = msg.lowercased()
        return low.contains("401") || low.contains("403")
            || low.contains("permiso") || low.contains("autorizado")
            || low.contains("unauthorized") || low.contains("forbidden")
    }

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
                } else if let err = puestosVC.errorMsg, esAcceso(err) {
                    AccesoDenegadoView(
                        titulo: "Sin Permiso",
                        descripcion: err,
                        accion: nil
                    )
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
        .navigationTitle(zona.name)
        .navigationBarTitleDisplayMode(.inline)
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
                .fill(puesto.status == .DISPONIBLE ? ParkTheme.Color.disponible.opacity(0.2) : ParkTheme.Color.ocupado.opacity(0.2))
                .frame(height: 52)
                .overlay(
                    VStack(spacing: 2) {
                        Image(systemName: puesto.status == .DISPONIBLE ? "car" : "car.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(puesto.status == .DISPONIBLE ? ParkTheme.Color.disponible : ParkTheme.Color.ocupado)
                        Text(puesto.spaceNumber)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(puesto.status == .DISPONIBLE ? ParkTheme.Color.disponible : ParkTheme.Color.ocupado)
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(puesto.status == .DISPONIBLE ? ParkTheme.Color.disponible.opacity(0.4) : ParkTheme.Color.ocupado.opacity(0.4), lineWidth: 1))
        }
    }
}

private struct PuestoSheet: View {
    let puesto: PuestoParqueo
    @ObservedObject var puestosVC: PuestosViewController
    let session: AuthSession?
    let onActualizado: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var placaGuardia = ""

    private var isGuard: Bool { session?.isGuard == true || session?.isAdmin == true }

    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 4)

            // Header
            VStack(spacing: 6) {
                Text("Puesto \(puesto.spaceNumber)")
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(ParkTheme.Color.textPrimary)
                Text("Zona \(puesto.zone.name) · Fila \(puesto.row) · Orden \(puesto.order)")
                    .font(.caption).foregroundStyle(ParkTheme.Color.textSecond)
                Label(puesto.status == .DISPONIBLE ? "Disponible" : "Ocupado",
                      systemImage: puesto.status == .DISPONIBLE ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(puesto.status == .DISPONIBLE ? ParkTheme.Color.disponible : ParkTheme.Color.ocupado)
                    .font(.subheadline).fontWeight(.semibold)
            }

            if let err = puestosVC.errorMsg {
                Text(err).font(.caption).foregroundStyle(ParkTheme.Color.ocupado).multilineTextAlignment(.center).padding(.horizontal)
            }
            if let ok = puestosVC.successMsg {
                Text(ok).font(.caption).foregroundStyle(ParkTheme.Color.disponible)
            }

            VStack(spacing: 12) {
                if isGuard {
                    // ── GUARD / ADMIN ACTIONS ─────────────────────────
                    if puesto.status == .DISPONIBLE {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Registrar entrada manual")
                                .font(.caption).fontWeight(.semibold)
                                .foregroundStyle(ParkTheme.Color.textSecond)
                            TextField("Placa del vehículo (ej. ABC-1234)", text: $placaGuardia)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .foregroundStyle(ParkTheme.Color.textPrimary)
                                .padding(12)
                                .background(ParkTheme.Color.card)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onChange(of: placaGuardia) { _, new in
                                    let f = new.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
                                    if f != new { placaGuardia = f }
                                }
                        }
                        PrimaryButton(title: "Registrar entrada", isLoading: puestosVC.isActualizando) {
                            Task { await puestosVC.forzarOcupacion(puestoId: puesto.id, placa: placaGuardia); onActualizado() }
                        }
                        .disabled(placaGuardia.trimmingCharacters(in: .whitespaces).count < 3 || puestosVC.isActualizando)
                    } else {
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
                } else {
                    // ── DRIVER ACTIONS ────────────────────────────────
                    if puesto.status == .DISPONIBLE {
                        PrimaryButton(title: "Ocupar este puesto", isLoading: puestosVC.isActualizando) {
                            Task { await puestosVC.ocupar(puestoId: puesto.id); onActualizado() }
                        }
                    } else {
                        PrimaryButton(title: "Liberar puesto", isLoading: puestosVC.isActualizando) {
                            Task { await puestosVC.liberar(puestoId: puesto.id); onActualizado() }
                        }
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
