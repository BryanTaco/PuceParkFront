import SwiftUI

struct ContentView: View {
    @StateObject private var authVC   = AuthViewController()
    @StateObject private var perfilVC = PerfilViewController()
    @State private var selectedTab    = 0

    var body: some View {
        Group {
            if authVC.session == nil {
                LoginView(authVC: authVC)
            } else if perfilVC.perfilCargado && shouldShowOnboarding(session: authVC.session, perfilVC: perfilVC) {
                OnboardingView(authVC: authVC, perfilVC: perfilVC)
            } else {
                MainTabView(authVC: authVC, perfilVC: perfilVC, selectedTab: $selectedTab)
                    .environment(\.authSession, authVC.session)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: authVC.session?.username) { _, username in
            if username != nil {
                perfilVC.isGuard = authVC.session?.isGuard ?? false
                Task { await perfilVC.loadPerfil() }
            } else {
                perfilVC.estado = nil
                perfilVC.perfilCargado = false
                perfilVC.isGuard = false
            }
        }
        .task {
            if authVC.session != nil {
                perfilVC.isGuard = authVC.session?.isGuard ?? false
                await perfilVC.loadPerfil()
            }
        }
    }
}

@MainActor
private func shouldShowOnboarding(session: AuthSession?, perfilVC: PerfilViewController) -> Bool {
    if session?.isGuard == true || session?.isAdmin == true {
        return !perfilVC.nombreValido
    }
    return perfilVC.estado?.completo == false
}

private struct MainTabView: View {
    @ObservedObject var authVC: AuthViewController
    @ObservedObject var perfilVC: PerfilViewController
    @Binding var selectedTab: Int

    private var isGuard: Bool { authVC.session?.isGuard == true || authVC.session?.isAdmin == true }

    var body: some View {
        TabView(selection: $selectedTab) {
            ZonasListView()
                .tabItem { Label("Zonas", systemImage: "map.fill") }
                .tag(0)
            if isGuard {
                GuardiaActividadView()
                    .tabItem { Label("Actividad", systemImage: "shield.fill") }
                    .tag(1)
            } else {
                HistorialView()
                    .tabItem { Label("Historial", systemImage: "clock.fill") }
                    .tag(1)
            }
            if isGuard {
                GuardiaRankingView()
                    .tabItem { Label("Ranking", systemImage: "trophy.fill") }
                    .tag(2)
            } else {
                RankingView()
                    .tabItem { Label("Ranking", systemImage: "trophy.fill") }
                    .tag(2)
            }
            PerfilView(authVC: authVC, perfilVC: perfilVC)
                .tabItem { Label("Perfil", systemImage: "person.fill") }
                .tag(3)
        }
        .tint(ParkTheme.Color.accentLight)
    }
}
