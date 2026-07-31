import Foundation
import Combine

@MainActor
class ZonasViewController: ObservableObject {
    @Published var zonas: [ZonaParqueo] = []
    @Published var isLoading = false
    @Published var errorMsg: String?

    func loadZonas() async {
        isLoading = true; errorMsg = nil
        do { zonas = try await ParkService.shared.getZonas() }
        catch { errorMsg = error.localizedDescription }
        isLoading = false
    }
}
