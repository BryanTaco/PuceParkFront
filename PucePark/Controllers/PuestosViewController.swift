import Foundation
import Combine

@MainActor
class PuestosViewController: ObservableObject {
    @Published var puestos: [PuestoParqueo] = []
    @Published var puestoSeleccionado: PuestoParqueo?
    @Published var isLoading = false
    @Published var isActualizando = false
    @Published var errorMsg: String?
    @Published var successMsg: String?

    var filas: [String] {
        var seen = Set<String>()
        return puestos.compactMap { p in seen.insert(p.fila).inserted ? p.fila : nil }
    }
    func puestosEnFila(_ fila: String) -> [PuestoParqueo] {
        puestos.filter { $0.fila == fila }.sorted { $0.orden < $1.orden }
    }

    func loadPuestosDeZona(zonaId: Int) async {
        isLoading = true; errorMsg = nil
        do { puestos = try await ParkService.shared.getPuestosByZona(zonaId: zonaId) }
        catch { errorMsg = error.localizedDescription }
        isLoading = false
    }
    func ocupar(puestoId: Int) async {
        isActualizando = true; errorMsg = nil; successMsg = nil
        do { let u = try await ParkService.shared.ocuparPuesto(id: puestoId); patch(u); puestoSeleccionado = u; successMsg = "Puesto ocupado." }
        catch { errorMsg = error.localizedDescription }
        isActualizando = false
    }
    func liberar(puestoId: Int) async {
        isActualizando = true; errorMsg = nil; successMsg = nil
        do { let u = try await ParkService.shared.liberarPuesto(id: puestoId); patch(u); puestoSeleccionado = u; successMsg = "Puesto liberado." }
        catch { errorMsg = error.localizedDescription }
        isActualizando = false
    }
    func forzarLiberacion(puestoId: Int) async {
        isActualizando = true; errorMsg = nil; successMsg = nil
        do { let u = try await ParkService.shared.forzarLiberacion(id: puestoId); patch(u); puestoSeleccionado = u; successMsg = "Liberado por guardia." }
        catch { errorMsg = error.localizedDescription }
        isActualizando = false
    }
    func forzarOcupacion(puestoId: Int, placa: String) async {
        isActualizando = true; errorMsg = nil; successMsg = nil
        do { let u = try await ParkService.shared.forzarOcupacion(id: puestoId, placa: placa); patch(u); puestoSeleccionado = u; successMsg = "Entrada registrada." }
        catch { errorMsg = error.localizedDescription }
        isActualizando = false
    }
    private func patch(_ u: PuestoParqueo) {
        if let i = puestos.firstIndex(where: { $0.id == u.id }) { puestos[i] = u }
    }
}
