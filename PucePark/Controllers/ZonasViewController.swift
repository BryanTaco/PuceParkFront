import Foundation
import Combine

@MainActor
class ZonasViewController: ObservableObject {
    @Published var zonas: [ZonaParqueo] = []
    @Published var isLoading = false
    @Published var errorMsg: String?
    @Published var didLoadOnce = false

    // silent = true → refresca sin spinner ni borrar datos previos (para recarga entre tabs)
    func loadZonas(silent: Bool = false) async {
        if !silent { isLoading = true }
        errorMsg = nil
        do { zonas = try await ParkService.shared.getZonas(); didLoadOnce = true }
        catch { if !silent { errorMsg = error.localizedDescription } }
        if !silent { isLoading = false }
    }
}
