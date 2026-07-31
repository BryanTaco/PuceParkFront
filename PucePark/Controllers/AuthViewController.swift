import Foundation
import Combine

@MainActor
class AuthViewController: ObservableObject {
    @Published var session: AuthSession?
    @Published var isLoading = false
    @Published var errorMsg: String?

    init() { session = AuthService.shared.currentSession() }

    func login(username: String, password: String) async {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !password.isEmpty else {
            errorMsg = "Ingresa tu usuario y contraseña"; return
        }
        isLoading = true; errorMsg = nil
        do { session = try await AuthService.shared.login(username: username, password: password) }
        catch { errorMsg = error.localizedDescription }
        isLoading = false
    }

    func logout() { AuthService.shared.logout(); session = nil }
}
