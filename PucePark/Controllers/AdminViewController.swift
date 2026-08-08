import Foundation
import Combine

@MainActor
class AdminViewController: ObservableObject {
    @Published var zonas: [ZonaParqueo] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMsg: String?
    @Published var successMsg: String?

    func loadZonas() async {
        isLoading = true; errorMsg = nil
        do { zonas = try await ParkService.shared.getZonas() }
        catch { errorMsg = error.localizedDescription }
        isLoading = false
    }

    func crearZona(name: String, description: String, maxCapacity: Int, location: String) async -> Bool {
        isSaving = true; errorMsg = nil; successMsg = nil
        defer { isSaving = false }
        do {
            _ = try await ParkService.shared.crearZona(name: name, description: description,
                                                       maxCapacity: maxCapacity, location: location)
            await loadZonas(); successMsg = "Zona '\(name)' creada"; return true
        } catch { errorMsg = error.localizedDescription; return false }
    }

    func eliminarZona(_ zona: ZonaParqueo) async {
        errorMsg = nil; successMsg = nil
        do {
            try await ParkService.shared.eliminarZona(id: zona.id)
            await loadZonas(); successMsg = "Zona '\(zona.name)' eliminada"
        } catch { errorMsg = error.localizedDescription }
    }

    func crearPuesto(zoneId: Int, spaceNumber: String, row: String, order: Int) async -> Bool {
        isSaving = true; errorMsg = nil; successMsg = nil
        defer { isSaving = false }
        do {
            _ = try await ParkService.shared.crearPuesto(zoneId: zoneId, spaceNumber: spaceNumber,
                                                         row: row, order: order)
            await loadZonas(); successMsg = "Puesto '\(spaceNumber)' creado"; return true
        } catch { errorMsg = error.localizedDescription; return false }
    }
}
