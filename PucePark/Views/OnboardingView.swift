import SwiftUI

struct OnboardingView: View {
    @ObservedObject var perfilVC: PerfilViewController

    var body: some View {
        ZStack {
            ParkTheme.Color.background.ignoresSafeArea()
            Image("bg_campus")
                .resizable().scaledToFill().ignoresSafeArea().opacity(0.12)
            VStack(spacing: 0) {
                Spacer()

                // ── Header ────────────────────────────────────────────
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundStyle(ParkTheme.Color.gold)
                    Text("Completa tu perfil")
                        .font(.title2).fontWeight(.bold)
                        .foregroundStyle(ParkTheme.Color.textPrimary)
                    Text("Necesitas completar tu información para usar el sistema de parqueo.")
                        .font(.subheadline)
                        .foregroundStyle(ParkTheme.Color.textSecond)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 36)

                // ── Campos ────────────────────────────────────────────
                VStack(spacing: 10) {
                    // Nombre
                    ValidatedField(
                        placeholder: "Nombre completo",
                        text: $perfilVC.editNombre,
                        hint: "Mínimo 3 caracteres",
                        isValid: perfilVC.nombreValido
                    )

                    // Placa
                    ValidatedField(
                        placeholder: "Placa del vehículo (ej. PDY-1234)",
                        text: $perfilVC.editPlaca,
                        hint: "Formato: 3 letras + 4 dígitos (ABC-1234)",
                        isValid: perfilVC.placaValida
                    )
                    .textInputAutocapitalization(.characters)
                    .onChange(of: perfilVC.editPlaca) { _, new in
                        // Solo letras y dígitos, máx 7 caracteres sin guion
                        let filtered = new.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
                        if filtered != new { perfilVC.editPlaca = filtered }
                    }

                    // Número de permiso
                    ValidatedField(
                        placeholder: "Número de permiso (5-10 dígitos)",
                        text: $perfilVC.editPermiso,
                        hint: "Solo dígitos, entre 5 y 10 caracteres",
                        isValid: perfilVC.permisoValido
                    )
                    .keyboardType(.numberPad)
                    .onChange(of: perfilVC.editPermiso) { _, new in
                        let filtered = new.filter(\.isNumber)
                        let limited  = String(filtered.prefix(10))
                        if limited != new { perfilVC.editPermiso = limited }
                    }

                    // Mensajes del servidor
                    if let err = perfilVC.errorMsg {
                        Text(err).font(.caption).foregroundStyle(ParkTheme.Color.ocupado)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 4)
                    }
                    if let ok = perfilVC.successMsg {
                        Text(ok).font(.caption).foregroundStyle(ParkTheme.Color.disponible)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 4)
                    }

                    PrimaryButton(title: "Guardar y continuar", isLoading: perfilVC.isSaving) {
                        Task { await perfilVC.savePerfil() }
                    }
                    .disabled(!perfilVC.canSave)
                    .padding(.top, 6)
                }
                .padding(.horizontal, 28)
                Spacer()
            }
        }
        .task { await perfilVC.loadPerfil() }
    }
}

// ── Campo con hint de validación ──────────────────────────────────────────────
private struct ValidatedField: View {
    let placeholder: String
    @Binding var text: String
    let hint: String
    let isValid: Bool

    private var showError: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isValid }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("", text: $text,
                      prompt: Text(placeholder).foregroundStyle(ParkTheme.Color.textSecond))
                .foregroundStyle(ParkTheme.Color.textPrimary)
                .padding(14)
                .background(ParkTheme.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: ParkTheme.Radius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: ParkTheme.Radius.button)
                        .strokeBorder(
                            showError ? ParkTheme.Color.ocupado :
                            isValid   ? ParkTheme.Color.disponible :
                                        ParkTheme.Color.accent.opacity(0.3),
                            lineWidth: showError || isValid ? 1.5 : 1
                        )
                )

            if showError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(hint)
                }
                .font(.caption2)
                .foregroundStyle(ParkTheme.Color.ocupado)
                .padding(.horizontal, 4)
                .transition(.opacity)
            } else if isValid {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Formato correcto")
                }
                .font(.caption2)
                .foregroundStyle(ParkTheme.Color.disponible)
                .padding(.horizontal, 4)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showError)
        .animation(.easeInOut(duration: 0.2), value: isValid)
    }
}
