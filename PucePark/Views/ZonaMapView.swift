import SwiftUI

struct ZonaMapView: View {
    let zona: ZonaParqueo
    var onEstadoCambiado: (() -> Void)? = nil
    var miPuestoId: Int? = nil
    @StateObject private var puestosVC = PuestosViewController()
    @Environment(\.authSession) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var sheetPuesto: PuestoParqueo?
    @State private var showAlto = false

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
        ZStack(alignment: .top) {
            ParkTheme.Color.background.ignoresSafeArea()
            // Color.clear fija el ancho a la pantalla; la imagen llena por overlay
            // y .clipped() recorta el sobrante — así scaledToFill NO estira el layout.
            Color.clear
                .overlay(
                    Image("bg_mapa")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.18)
                )
                .clipped()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header — sin glass iOS 26
                ZStack {
                    Color(hex: "#141E35")
                    HStack {
                        // onTapGesture en lugar de Button — Button aplica glass al label en iOS 26
                        Text("‹ Zonas")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.leading, 16)
                            .contentShape(Rectangle())
                            .onTapGesture { dismiss() }
                        Spacer()
                        Text(zona.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Color.clear.frame(width: 60, height: 1)
                    }
                }
                .frame(height: 52)
                .padding(.top, 56)

                if puestosVC.isLoading {
                    Spacer()
                    ProgressView().tint(ParkTheme.Color.accentLight)
                    Spacer()
                } else if let err = puestosVC.errorMsg, esAcceso(err), puestosVC.puestos.isEmpty {
                    AccesoDenegadoView(titulo: "Sin Permiso", descripcion: err, accion: nil)
                } else if let err = puestosVC.errorMsg, puestosVC.puestos.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text(err).foregroundColor(ParkTheme.Color.ocupado).multilineTextAlignment(.center)
                        Button("Reintentar") { Task { await puestosVC.loadPuestosDeZona(zonaId: zona.id) } }
                            .foregroundColor(ParkTheme.Color.accentLight)
                    }.padding()
                    Spacer()
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Stats banner — solid background, foregroundStyle
                                HStack(spacing: 0) {
                                    StatChip(label: "Disponibles", value: disponibles, color: ParkTheme.Color.disponible)
                                    Spacer()
                                    StatChip(label: "Ocupados",    value: ocupados,    color: ParkTheme.Color.ocupado)
                                    Spacer()
                                    StatChip(label: "Total",       value: disponibles + ocupados, color: ParkTheme.Color.accentLight)
                                }
                                .padding(14)
                                .background(ParkTheme.Color.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                // Grid per fila — 4 columnas
                                ForEach(puestosVC.filas, id: \.self) { fila in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Fila \(fila)")
                                            .font(.caption).fontWeight(.semibold)
                                            .foregroundStyle(ParkTheme.Color.textSecond)
                                        LazyVGrid(columns: columns, spacing: 8) {
                                            ForEach(puestosVC.puestosEnFila(fila)) { puesto in
                                                PuestoCell(puesto: puesto, miPuestoId: puestosVC.miPuestoId)
                                                    .onTapGesture { sheetPuesto = puesto }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                        }
                        .refreshable { await puestosVC.loadPuestosDeZona(zonaId: zona.id) }

                        // ── Leyenda fija — siempre visible, no hace falta scroll ──
                        HStack(spacing: 0) {
                            LegendDot(color: ParkTheme.Color.disponible, label: "Disponible")
                            Spacer()
                            LegendDot(color: ParkTheme.Color.gold,       label: "Mi puesto")
                            Spacer()
                            LegendDot(color: ParkTheme.Color.ocupado,    label: "Ocupado")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#141E35"))
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            // Botón "Liberar mi puesto" — arriba a la derecha, solo si tengo un puesto
            if let mid = puestosVC.miPuestoId {
                Group {
                    if puestosVC.isActualizando {
                        ProgressView().tint(Color(hex: "#0B1120")).scaleEffect(0.7)
                            .frame(width: 56, height: 18)
                    } else {
                        Text("Liberar")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "#0B1120"))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(ParkTheme.Color.gold)
                .clipShape(Capsule())
                .contentShape(Capsule())
                .onTapGesture {
                    Task { await puestosVC.liberar(puestoId: mid); onEstadoCambiado?() }
                }
                .padding(.top, 60)
                .padding(.trailing, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)   // elimina el glass nav bar de iOS 26
        .task {
            if puestosVC.miPuestoId == nil { puestosVC.miPuestoId = miPuestoId }
            await puestosVC.loadPuestosDeZona(zonaId: zona.id)
        }
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


// Estructura original: RoundedRectangle + .overlay() con .foregroundStyle()
private struct PuestoCell: View {
    let puesto: PuestoParqueo
    var miPuestoId: Int? = nil

    var body: some View {
        let disp  = puesto.status == .DISPONIBLE
        let esMio = !disp && puesto.id == miPuestoId
        let accent: Color = disp  ? ParkTheme.Color.disponible
                          : esMio ? ParkTheme.Color.gold
                          :         ParkTheme.Color.ocupado
        let icon  = disp ? "car" : esMio ? "star.fill" : "car.fill"

        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(accent.opacity(0.2))
                .frame(height: 52)
                .overlay(
                    VStack(spacing: 2) {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundStyle(accent)
                        Text(puesto.spaceNumber)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(accent.opacity(0.4), lineWidth: 1)
                )
        }
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
                    } else if puesto.id == puestosVC.miPuestoId {
                        // Solo el dueño puede liberar su propio puesto
                        PrimaryButton(title: "Liberar puesto", isLoading: puestosVC.isActualizando) {
                            Task { await puestosVC.liberar(puestoId: puesto.id); onActualizado() }
                        }
                    } else {
                        // Puesto ocupado por otro usuario → no permitido
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(ParkTheme.Color.gold)
                            Text("Este puesto está ocupado por otro usuario. Solo su dueño o un guardia puede liberarlo.")
                                .font(.system(size: 13))
                                .foregroundStyle(ParkTheme.Color.textSecond)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ParkTheme.Color.gold.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
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
            Text("\(value)").font(.title2).fontWeight(.bold).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LegendDot: View {
    let color: Color; let label: String
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
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
