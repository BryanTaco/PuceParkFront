import SwiftUI

struct PerfilView: View {
    @ObservedObject var authVC:   AuthViewController
    @ObservedObject var perfilVC: PerfilViewController
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            ZStack {
                ParkTheme.Color.background.ignoresSafeArea()

                if perfilVC.isLoading {
                    ProgressView().tint(ParkTheme.Color.accentLight)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            PerfilHero(perfil: perfilVC.perfil, session: authVC.session)

                            VStack(spacing: 16) {
                                if isEditing {
                                    FormCard(
                                        perfilVC: perfilVC,
                                        isGuard: authVC.session?.isGuard ?? false,
                                        onGuardado: { isEditing = false }
                                    )
                                } else {
                                    PerfilInfoCard(perfil: perfilVC.perfil, isGuard: authVC.session?.isGuard ?? false)
                                }
                                LogoutButton { authVC.logout() }
                            }
                            .padding(16)
                            .padding(.bottom, 24)
                        }
                    }
                    .refreshable { await perfilVC.loadPerfil() }
                    .ignoresSafeArea(edges: .top)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            if !isEditing {
                                Button {
                                    isEditing = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(ParkTheme.Color.accentLight)
                                }
                            } else {
                                Button("Cancelar") {
                                    perfilVC.errorMsg = nil
                                    perfilVC.successMsg = nil
                                    if let p = perfilVC.perfil {
                                        perfilVC.editNombre = p.fullName
                                        perfilVC.editPlaca = p.vehiclePlate
                                        perfilVC.editPermiso = p.permitNumber
                                    }
                                    isEditing = false
                                }
                                .foregroundStyle(ParkTheme.Color.textSecond)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// ── CINEMATIC HERO ────────────────────────────────────────────────────────────
private struct PerfilHero: View {
    let perfil:  PerfilUsuario?
    let session: AuthSession?
    @State private var appeared = false

    private var nombre: String {
        if let n = perfil?.fullName, !n.isEmpty { return n }
        return session?.username ?? "Usuario"
    }
    private var inicial: String { String(nombre.prefix(1)).uppercased() }

    private var esGuardia: Bool { session?.isGuard == true || session?.isAdmin == true }
    // SF Symbols no tiene gorra de guardia → uso figura con insignia de seguridad
    private var avatarSymbol: String {
        if esGuardia { return "person.badge.shield.checkmark.fill" }
        return esFemenino ? "figure.stand.dress" : "figure.stand"
    }
    // Heurística de género por nombre (español: termina en "a" → femenino). Solo para el avatar.
    private var esFemenino: Bool {
        let primer = nombre.split(separator: " ").first.map(String.init)?.lowercased() ?? ""
        return primer.hasSuffix("a")
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            Color.black.ignoresSafeArea(edges: .top)

            // Animated blobs — purple / violet
            CinematicBackground(
                accent:  Color(hex: "#6D28D9"),
                accent2: Color(hex: "#4338CA")
            )
            .ignoresSafeArea(edges: .top)

            LinearGradient(
                colors: [.black.opacity(0.38), .black.opacity(0.72)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

            // Background initial letter
            Text(inicial)
                .font(.system(size: 220, weight: .black))
                .foregroundStyle(.white.opacity(0.04))
                .kerning(-5)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 8)
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

                Text("PUCE · MI CUENTA")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .kerning(2.5)
                    .padding(.bottom, 16)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)

                // Avatar circle — muñeco según rol/género
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.14))
                        .frame(width: 68, height: 68)
                    Image(systemName: avatarSymbol)
                        .font(.system(size: 34))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 12)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.7)
                .animation(.spring(duration: 0.6, bounce: 0.4).delay(0.15), value: appeared)

                // Name
                Text(nombre)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .kerning(-0.5)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)
                    .animation(.easeOut(duration: 0.55).delay(0.25), value: appeared)

                // Role badge
                if let rol = session?.rolPrincipal {
                    Text(rol)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(.white.opacity(0.12))
                        .clipShape(Capsule())
                        .padding(.top, 8)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.38), value: appeared)
                }

                Spacer().frame(height: 52)
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 330)
        .onAppear { appeared = true }
    }
}

// ── INFO CARD (modo lectura) ───────────────────────────────────────────────────
private struct PerfilInfoCard: View {
    let perfil: PerfilUsuario?
    let isGuard: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Información personal")
                .font(.headline).fontWeight(.semibold).foregroundStyle(ParkTheme.Color.textPrimary)

            InfoRow(icon: "person.fill", label: "Nombre", value: perfil?.fullName ?? "—")

            if isGuard {
                InfoRow(icon: "creditcard.fill", label: "Cédula", value: perfil?.permitNumber ?? "—")
            } else {
                InfoRow(icon: "car.fill", label: "Placa", value: perfil?.vehiclePlate ?? "—")
                InfoRow(icon: "doc.fill", label: "Permiso", value: perfil?.permitNumber ?? "—")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

private struct InfoRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(ParkTheme.Color.accentLight)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(ParkTheme.Color.textSecond)
                Text(value).font(.system(size: 19, weight: .semibold)).foregroundStyle(ParkTheme.Color.textPrimary)
            }
        }
        .padding(.vertical, 4)
    }
}

// ── FORM CARD (modo edición) ───────────────────────────────────────────────────
private struct FormCard: View {
    @ObservedObject var perfilVC: PerfilViewController
    let isGuard: Bool
    var onGuardado: () -> Void = {}
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Información personal")
                .font(.subheadline).fontWeight(.semibold).foregroundStyle(ParkTheme.Color.textSecond)

            PerfilValidatedField(
                label: "Nombre completo",
                text: $perfilVC.editNombre,
                hint: "Mínimo 3 caracteres",
                isValid: perfilVC.nombreValido
            )

            if isGuard {
                PerfilValidatedField(
                    label: "Cédula de guardia",
                    text: $perfilVC.editPermiso,
                    hint: "10 dígitos (cédula ecuatoriana)",
                    isValid: perfilVC.cedulaValida
                )
                .keyboardType(.numberPad)
                .onChange(of: perfilVC.editPermiso) { _, new in
                    let limited = String(new.filter(\.isNumber).prefix(10))
                    if limited != new { perfilVC.editPermiso = limited }
                }
            } else {
                PerfilValidatedField(
                    label: "Placa del vehículo",
                    text: $perfilVC.editPlaca,
                    hint: "Formato: 3 letras + 4 dígitos (ej. PDY-1234)",
                    isValid: perfilVC.placaValida
                )
                .textInputAutocapitalization(.characters)
                .onChange(of: perfilVC.editPlaca) { _, new in
                    let filtered = new.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
                    if filtered != new { perfilVC.editPlaca = filtered }
                }

                PerfilValidatedField(
                    label: "Número de permiso",
                    text: $perfilVC.editPermiso,
                    hint: "Solo dígitos, entre 5 y 10 caracteres",
                    isValid: perfilVC.permisoValido
                )
                .keyboardType(.numberPad)
                .onChange(of: perfilVC.editPermiso) { _, new in
                    let limited = String(new.filter(\.isNumber).prefix(10))
                    if limited != new { perfilVC.editPermiso = limited }
                }
            }

            if let err = perfilVC.errorMsg {
                Text(err).font(.caption).foregroundStyle(ParkTheme.Color.ocupado).multilineTextAlignment(.leading)
            }
            if let ok = perfilVC.successMsg {
                Text(ok).font(.caption).foregroundStyle(ParkTheme.Color.disponible)
            }

            PrimaryButton(title: "Guardar cambios", isLoading: perfilVC.isSaving) {
                Task {
                    await perfilVC.savePerfil()
                    if perfilVC.errorMsg == nil { onGuardado() }
                }
            }
            .disabled(!perfilVC.canSave)
        }
        .padding(16).glassCard()
    }
}

// ── VALIDATED FIELD ───────────────────────────────────────────────────────────
private struct PerfilValidatedField: View {
    let label: String
    @Binding var text: String
    let hint: String
    let isValid: Bool

    private var showError: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isValid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(ParkTheme.Color.textSecond)
            TextField("", text: $text)
                .foregroundStyle(ParkTheme.Color.textPrimary)
                .padding(12)
                .background(ParkTheme.Color.card)
                .clipShape(RoundedRectangle(cornerRadius: ParkTheme.Radius.chip))
                .overlay(
                    RoundedRectangle(cornerRadius: ParkTheme.Radius.chip)
                        .strokeBorder(
                            showError ? ParkTheme.Color.ocupado :
                            isValid   ? ParkTheme.Color.disponible :
                                        Color.clear,
                            lineWidth: 1.5
                        )
                )
            if showError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(hint)
                }
                .font(.caption2).foregroundStyle(ParkTheme.Color.ocupado)
            } else if isValid {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Formato correcto")
                }
                .font(.caption2).foregroundStyle(ParkTheme.Color.disponible)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: showError)
        .animation(.easeInOut(duration: 0.15), value: isValid)
    }
}

// ── LOGOUT BUTTON ─────────────────────────────────────────────────────────────
private struct LogoutButton: View {
    let action: () -> Void
    var body: some View {
        Button(role: .destructive, action: action) {
            Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity).frame(height: 42)
        }
        .buttonStyle(.bordered)
        .tint(ParkTheme.Color.ocupado)
        .clipShape(RoundedRectangle(cornerRadius: ParkTheme.Radius.button))
        .padding(.top, 4)
    }
}
