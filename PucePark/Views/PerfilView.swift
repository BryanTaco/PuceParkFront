import SwiftUI

struct PerfilView: View {
    @ObservedObject var authVC:   AuthViewController
    @ObservedObject var perfilVC: PerfilViewController

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
                                FormCard(perfilVC: perfilVC, isGuard: authVC.session?.isGuard ?? false)
                                LogoutButton { authVC.logout() }
                            }
                            .padding(16)
                            .padding(.bottom, 24)
                        }
                    }
                    .refreshable { await perfilVC.loadPerfil() }
                    .ignoresSafeArea(edges: .top)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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

                // Avatar circle
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Text(inicial)
                        .font(.system(size: 22, weight: .bold))
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

// ── FORM CARD ─────────────────────────────────────────────────────────────────
private struct FormCard: View {
    @ObservedObject var perfilVC: PerfilViewController
    let isGuard: Bool
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
                Task { await perfilVC.savePerfil() }
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
                .frame(maxWidth: .infinity).frame(height: 50)
        }
        .buttonStyle(.bordered)
        .tint(ParkTheme.Color.ocupado)
        .clipShape(RoundedRectangle(cornerRadius: ParkTheme.Radius.button))
    }
}
