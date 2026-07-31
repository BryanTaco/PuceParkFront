import Foundation
import Combine

@MainActor
class RankingViewController: ObservableObject {
    @Published var ranking: [RankingEntrada] = []
    @Published var isLoading = false
    @Published var errorMsg: String?
    @Published var year: Int
    @Published var month: Int

    init() {
        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        year = now.year ?? 2026; month = now.month ?? 1
    }

    var mesTexto: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "es_EC"); f.dateFormat = "MMMM yyyy"
        let d = Calendar.current.date(from: DateComponents(year: year, month: month)) ?? Date()
        return f.string(from: d).capitalized
    }

    func loadRanking() async {
        isLoading = true; errorMsg = nil
        do { ranking = try await ParkService.shared.getRankingMensual(year: year, month: month) }
        catch { errorMsg = error.localizedDescription }
        isLoading = false
    }

    func mesAnterior() { if month == 1 { month = 12; year -= 1 } else { month -= 1 }; Task { await loadRanking() } }
    func mesSiguiente() {
        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        guard year < (now.year ?? 2026) || month < (now.month ?? 1) else { return }
        if month == 12 { month = 1; year += 1 } else { month += 1 }; Task { await loadRanking() }
    }
}
