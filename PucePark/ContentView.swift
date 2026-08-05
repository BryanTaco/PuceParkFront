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
            } else if perfilVC.perfilCargado && noEstaRegistrado(session: authVC.session, perfilVC: perfilVC) {
                NoRegistradoView { authVC.logout() }
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
    return perfilVC.estado?.complete == false
}

// Estudiante autenticado pero sin cuenta en el sistema de parqueo
@MainActor
private func noEstaRegistrado(session: AuthSession?, perfilVC: PerfilViewController) -> Bool {
    guard session?.isGuard == false, session?.isAdmin == false else { return false }
    return perfilVC.perfil == nil
}

// ── Vista: estudiante no registrado en el sistema ─────────────────────────────
private struct NoRegistradoView: View {
    let onLogout: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            ParkTheme.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(ParkTheme.Color.gold.opacity(0.12))
                            .frame(width: 110, height: 110)
                        Circle()
                            .fill(ParkTheme.Color.gold.opacity(0.08))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 44))
                            .foregroundStyle(ParkTheme.Color.gold)
                    }
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.7, bounce: 0.4).delay(0.1), value: appeared)

                    VStack(spacing: 10) {
                        Text("No estás registrado")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(ParkTheme.Color.textPrimary)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(.easeOut(duration: 0.5).delay(0.25), value: appeared)

                        Text("Tu usuario no tiene una cuenta activa en el sistema de parqueo de la PUCE.")
                            .font(.system(size: 15))
                            .foregroundStyle(ParkTheme.Color.textSecond)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(.easeOut(duration: 0.45).delay(0.35), value: appeared)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(ParkTheme.Color.accentLight)
                        Text("Dirígete a Secretaría\npara activar tu acceso.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(ParkTheme.Color.textPrimary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(ParkTheme.Color.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.45), value: appeared)
                }

                Spacer()

                Button(action: onLogout) {
                    Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ParkTheme.Color.textSecond)
                        .frame(maxWidth: .infinity).frame(height: 50)
                }
                .buttonStyle(.bordered)
                .tint(ParkTheme.Color.textSecond.opacity(0.4))
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.55), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
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
