import Foundation
import Combine

@MainActor
class PerfilViewController: ObservableObject {
    @Published var perfil: PerfilUsuario?
    @Published var estado: PerfilEstado?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMsg: String?
    @Published var successMsg: String?
    @Published var editNombre     = ""
    @Published var editPlaca      = ""
    @Published var editPermiso    = ""
    @Published var editModoOscuro = true

    // Placa Ecuador: 3 letras + 4 dígitos (con o sin guion)
    var placaValida: Bool {
        let clean = editPlaca.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased().replacingOccurrences(of: "-", with: "")
        return clean.range(of: #"^[A-Z]{3}[0-9]{4}$"#, options: .regularExpression) != nil
    }

    // Número de permiso: solo dígitos, entre 5 y 10 caracteres
    var permisoValido: Bool {
        let clean = editPermiso.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.range(of: #"^\d{5,10}$"#, options: .regularExpression) != nil
    }

    var nombreValido: Bool {
        editNombre.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    var canSave: Bool {
        nombreValido && placaValida && permisoValido && !isSaving
    }

    func loadPerfil() async {
        isLoading = true; errorMsg = nil
        do {
            async let p = ParkService.shared.getPerfil()
            async let e = ParkService.shared.getPerfilEstado()
            let (perfil, estado) = try await (p, e)
            self.perfil = perfil; self.estado = estado; fill(from: perfil)
        } catch { errorMsg = error.localizedDescription }
        isLoading = false
    }

    func savePerfil() async {
        guard canSave else { return }
        isSaving = true; errorMsg = nil; successMsg = nil
        do {
            let u = try await ParkService.shared.updatePerfil(
                nombreCompleto: editNombre.trimmingCharacters(in: .whitespacesAndNewlines),
                placaVehiculo:  editPlaca.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
                numeroPermiso:  editPermiso.trimmingCharacters(in: .whitespacesAndNewlines),
                modoOscuro:     editModoOscuro)
            perfil = u; estado = try await ParkService.shared.getPerfilEstado()
            successMsg = "Perfil actualizado"
        } catch { errorMsg = "No se pudo guardar el perfil." }
        isSaving = false
    }

    private func fill(from p: PerfilUsuario) {
        editNombre = p.nombreCompleto; editPlaca = p.placaVehiculo
        editPermiso = p.numeroPermiso; editModoOscuro = p.modoOscuro
    }
}
