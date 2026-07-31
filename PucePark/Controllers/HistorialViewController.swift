import Foundation
import Combine

@MainActor
class HistorialViewController: ObservableObject {
    @Published var historial: [HistorialParqueo] = []
    @Published var estadisticas: EstadisticasPersonales?
    @Published var isLoading = false
    @Published var errorMsg: String?

    var sesionesActivas:     [HistorialParqueo] { historial.filter { $0.estaActivo } }
    var sesionesCompletadas: [HistorialParqueo] { historial.filter { !$0.estaActivo } }

    func loadHistorial() async {
        isLoading = true; errorMsg = nil
        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        do {
            async let h = ParkService.shared.getHistorialMe()
            async let e = ParkService.shared.getEstadisticasMe(year: now.year ?? 2026, month: now.month ?? 1)
            let (h2, e2) = try await (h, e)
            historial = h2; estadisticas = e2
        } catch { errorMsg = error.localizedDescription }
        isLoading = false
    }
}
