import SwiftUI

struct ContentView: View {
    @StateObject private var authVC   = AuthViewController()
    @StateObject private var perfilVC = PerfilViewController()
    @State private var selectedTab    = 0

    var body: some View {
        Group {
            if authVC.session == nil {
                LoginView(authVC: authVC)
            } else if perfilVC.estado?.completo == false {
                OnboardingView(perfilVC: perfilVC)
            } else {
                MainTabView(authVC: authVC, perfilVC: perfilVC, selectedTab: $selectedTab)
                    .environment(\.authSession, authVC.session)
            }
        }
        .preferredColorScheme(perfilVC.editModoOscuro ? .dark : .light)
        .onChange(of: authVC.session?.username) { _, username in
            if username != nil { Task { await perfilVC.loadPerfil() } }
            else { perfilVC.estado = nil }
        }
        .task {
            if authVC.session != nil { await perfilVC.loadPerfil() }
        }
    }
}

private struct MainTabView: View {
    @ObservedObject var authVC: AuthViewController
    @ObservedObject var perfilVC: PerfilViewController
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            ZonasListView()
                .tabItem { Label("Zonas",    systemImage: "map.fill") }
                .tag(0)
            HistorialView()
                .tabItem { Label("Historial", systemImage: "clock.fill") }
                .tag(1)
            RankingView()
                .tabItem { Label("Ranking",  systemImage: "trophy.fill") }
                .tag(2)
            PerfilView(authVC: authVC, perfilVC: perfilVC)
                .tabItem { Label("Perfil",   systemImage: "person.fill") }
                .tag(3)
        }
        .tint(ParkTheme.Color.accentLight)
    }
}
