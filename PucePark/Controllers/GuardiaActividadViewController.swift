import Foundation
import Combine

@MainActor
class GuardiaActividadViewController: ObservableObject {
    @Published var registros: [HistorialParqueo] = []
    @Published var isLoading = false
    @Published var errorMsg: String?

    func loadRegistros() async {
        isLoading = true; errorMsg = nil
        do { registros = try await ParkService.shared.getHistorialGuardia() }
        catch { errorMsg = error.localizedDescription }
        isLoading = false
    }

    var activas: [HistorialParqueo] { registros.filter { $0.estaActivo } }
    var cerradas: [HistorialParqueo] { registros.filter { !$0.estaActivo } }
}
