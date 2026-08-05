import SwiftUI

struct ZonaMapView: View {
    let zona: ZonaParqueo
    var onEstadoCambiado: (() -> Void)? = nil
    @StateObject private var puestosVC = PuestosViewController()
    @Environment(\.authSession) private var session
    @State private var sheetPuesto: PuestoParqueo?
    @State private var showAlto = false

    private var disponibles: Int { puestosVC.puestos.filter { $0.status == .DISPONIBLE }.count }
    private var ocupados:    Int { puestosVC.puestos.filter { $0.status == .OCUPADO  }.count }

    private func rows(for fila: String) -> [[PuestoParqueo]] {
        let items = puestosVC.puestosEnFila(fila)
        return stride(from: 0, to: items.count, by: 2).map {
            Array(items[$0..<min($0 + 2, items.count)])
        }
    }

    private func esAcceso(_ msg: String) -> Bool {
        let low = msg.lowercased()
        return low.contains("401") || low.contains("403")
            || low.contains("permiso") || low.contains("autorizado")
            || low.contains("unauthorized") || low.contains("forbidden")
    }

    var body: some View {
        ZStack {
            ParkTheme.Color.background.ignoresSafeArea()
            Image("bg_mapa")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.18)

            if puestosVC.isLoading {
                ProgressView().tint(ParkTheme.Color.accentLight)
            } else if let err = puestosVC.errorMsg, esAcceso(err), puestosVC.puestos.isEmpty {
                AccesoDenegadoView(
                    titulo: "Sin Permiso",
                    descripcion: err,
                    accion: nil
                )
            } else if let err = puestosVC.errorMsg, puestosVC.puestos.isEmpty {
                VStack(spacing: 12) {
                    Text(err).foregroundColor(ParkTheme.Color.ocupado).multilineTextAlignment(.center)
                    Button("Reintentar") { Task { await puestosVC.loadPuestosDeZona(zonaId: zona.id) } }
                        .foregroundColor(ParkTheme.Color.accentLight)
                }.padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Stats banner
                        HStack(spacing: 0) {
                            StatChip(label: "Disponibles", value: disponibles, color: ParkTheme.Color.disponible)
                            StatChip(label: "Ocupados",    value: ocupados,    color: ParkTheme.Color.ocupado)
                            StatChip(label: "Total",       value: disponibles + ocupados, color: ParkTheme.Color.accentLight)
                        }
                        .padding(.vertical, 14)
                        .glassCard()

                        // Grid per fila
                        ForEach(puestosVC.filas, id: \.self) { fila in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Fila \(fila)")
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.7))
                                ForEach(rows(for: fila), id: \.first!.id) { row in
                                    HStack(spacing: 8) {
                                        ForEach(row) { puesto in
                                            PuestoCell(puesto: puesto)
                                                .onTapGesture { sheetPuesto = puesto }
                                        }
                                        if row.count == 1 { Color.clear.frame(height: 68) }
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
        .navigationTitle(zona.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await puestosVC.loadPuestosDeZona(zonaId: zona.id) }
        .sheet(item: $sheetPuesto) { p in
            PuestoSheet(
                puesto: p,
                puestosVC: puestosVC,
                session: session,
                onActualizado: { sheetPuesto = puestosVC.puestoSeleccionado },
                onError: { sheetPuesto = nil; puestosVC.errorMsg = nil; showAlto = true }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(ParkTheme.Color.surface)
            .onDisappear { onEstadoCambiado?() }
        }
        .fullScreenCover(isPresented: $showAlto) {
            AltoView { showAlto = false }
        }
    }
}

private struct PuestoCell: View {
    let puesto: PuestoParqueo
    var body: some View {
        let _ = print("⚡️ PuestoCell: \(puesto.spaceNumber) status=\(puesto.status)")
        let disp = puesto.status == .DISPONIBLE
        return VStack(spacing: 3) {
            Image(systemName: disp ? "car.fill" : "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
            Text(puesto.spaceNumber)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ParkTheme.Color.card)
                RoundedRectangle(cornerRadius: 10)
                    .fill(disp ? Color.green.opacity(0.28) : Color.red.opacity(0.28))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(disp ? Color.green.opacity(0.55) : Color.red.opacity(0.55), lineWidth: 1.5)
        )
    }
}

private struct PuestoSheet: View {
    let puesto: PuestoParqueo
    @ObservedObject var puestosVC: PuestosViewController
    let session: AuthSession?
    let onActualizado: () -> Void
    var onError: () -> Void = {}
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

            if let err = puestosVC.errorMsg, !isAltoError(err) {
                Text(err).font(.caption).foregroundStyle(ParkTheme.Color.ocupado)
                    .multilineTextAlignment(.center).padding(.horizontal)
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
                            Task {
                                await puestosVC.ocupar(puestoId: puesto.id)
                                if let err = puestosVC.errorMsg, isAltoError(err) { onError() }
                                else { onActualizado() }
                            }
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

private func isAltoError(_ msg: String) -> Bool {
    let low = msg.lowercased()
    return low.contains("active") || low.contains("activo") || low.contains("ya tiene")
}

private struct StatChip: View {
    let label: String; let value: Int; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.title2).fontWeight(.bold).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(ParkTheme.Color.textSecond)
        }
        .frame(maxWidth: .infinity)
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

// ── ALTO VIEW — pantalla completa de advertencia ──────────────────────────────
private struct AltoView: View {
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color(hex: "#0D0000").ignoresSafeArea()
            CinematicBackground(accent: Color(hex: "#DC2626"), accent2: Color(hex: "#7F1D1D"))
                .ignoresSafeArea().opacity(0.55)
            LinearGradient(colors: [.black.opacity(0.25), .black.opacity(0.65)],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            // Background mega-text
            Text("ALTO")
                .font(.system(size: 180, weight: .black))
                .foregroundStyle(.white.opacity(0.04))
                .kerning(-6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                // Animated warning icon
                ZStack {
                    Circle().fill(.white.opacity(0.07)).frame(width: 150, height: 150)
                    Circle().fill(.white.opacity(0.07)).frame(width: 110, height: 110)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 62))
                        .foregroundStyle(ParkTheme.Color.gold)
                }
                .scaleEffect(appeared ? 1 : 0.35)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.7, bounce: 0.5).delay(0.08), value: appeared)

                Spacer().frame(height: 36)

                Text("¡Alto!")
                    .font(.system(size: 58, weight: .black))
                    .foregroundStyle(.white)
                    .kerning(-2)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 28)
                    .animation(.easeOut(duration: 0.55).delay(0.28), value: appeared)

                Spacer().frame(height: 14)

                Text("Ya tienes un espacio ocupado.")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)
                    .animation(.easeOut(duration: 0.5).delay(0.36), value: appeared)

                Spacer().frame(height: 10)

                Text("Libera tu puesto activo antes\nde ocupar otro.")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.45).delay(0.43), value: appeared)

                Spacer()

                Button(action: onDismiss) {
                    Text("Entendido")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(ParkTheme.Color.ocupado)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 56)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.52), value: appeared)
            }
        }
        .onAppear { appeared = true }
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
