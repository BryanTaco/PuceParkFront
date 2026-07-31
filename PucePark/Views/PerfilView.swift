import SwiftUI

struct PerfilView: View {
    @ObservedObject var authVC: AuthViewController
    @ObservedObject var perfilVC: PerfilViewController

    var body: some View {
        NavigationStack {
            ZStack {
                ParkTheme.Color.background.ignoresSafeArea()
                Group {
                    if perfilVC.isLoading {
                        ProgressView().tint(ParkTheme.Color.accentLight)
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {
                                AvatarHeader(perfil: perfilVC.perfil, session: authVC.session)
                                FormCard(perfilVC: perfilVC)
                                LogoutButton { authVC.logout() }
                            }
                            .padding(16)
                        }
                        .refreshable { await perfilVC.loadPerfil() }
                    }
                }
            }
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

private struct AvatarHeader: View {
    let perfil: PerfilUsuario?; let session: AuthSession?
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(ParkTheme.Color.accent.opacity(0.2)).frame(width: 80, height: 80)
                Image(systemName: "person.fill").font(.system(size: 36)).foregroundStyle(ParkTheme.Color.accentLight)
            }
            Text(perfil?.nombreCompleto.isEmpty == false ? perfil!.nombreCompleto : (session?.username ?? "Usuario"))
                .font(.headline).foregroundStyle(ParkTheme.Color.textPrimary)
            if let rol = session?.rolPrincipal {
                Text(rol)
                    .font(.caption).padding(.horizontal, 12).padding(.vertical, 4)
                    .background(ParkTheme.Color.accent.opacity(0.2))
                    .foregroundStyle(ParkTheme.Color.accentLight)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity).padding(20).glassCard()
    }
}

private struct FormCard: View {
    @ObservedObject var perfilVC: PerfilViewController
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Información personal")
                .font(.subheadline).fontWeight(.semibold).foregroundStyle(ParkTheme.Color.textSecond)

            PerfilValidatedField(label: "Nombre completo", text: $perfilVC.editNombre,
                                 hint: "Mínimo 3 caracteres", isValid: perfilVC.nombreValido)

            PerfilValidatedField(label: "Placa del vehículo", text: $perfilVC.editPlaca,
                                 hint: "Formato: 3 letras + 4 dígitos (ej. PDY-1234)",
                                 isValid: perfilVC.placaValida)
                .textInputAutocapitalization(.characters)
                .onChange(of: perfilVC.editPlaca) { _, new in
                    let filtered = new.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
                    if filtered != new { perfilVC.editPlaca = filtered }
                }

            PerfilValidatedField(label: "Número de permiso", text: $perfilVC.editPermiso,
                                 hint: "Solo dígitos, entre 5 y 10 caracteres",
                                 isValid: perfilVC.permisoValido)
                .keyboardType(.numberPad)
                .onChange(of: perfilVC.editPermiso) { _, new in
                    let limited = String(new.filter(\.isNumber).prefix(10))
                    if limited != new { perfilVC.editPermiso = limited }
                }

            Toggle(isOn: $perfilVC.editModoOscuro) {
                Text("Modo oscuro").foregroundStyle(ParkTheme.Color.textPrimary).font(.subheadline)
            }.tint(ParkTheme.Color.accent)

            if let err = perfilVC.errorMsg {
                Text(err).font(.caption).foregroundStyle(ParkTheme.Color.ocupado)
                    .multilineTextAlignment(.leading)
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

private struct PerfilValidatedField: View {
    let label: String
    @Binding var text: String
    let hint: String
    let isValid: Bool

    private var showError: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isValid }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(ParkTheme.Color.textSecond)
            TextField("", text: $text)
                .foregroundStyle(ParkTheme.Color.textPrimary)
                .padding(12)
                .background(ParkTheme.Color.background)
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
