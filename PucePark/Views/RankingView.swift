import SwiftUI

struct RankingView: View {
    @StateObject private var rankingVC = RankingViewController()
    @Environment(\.authSession) private var session

    var body: some View {
        NavigationStack {
            ZStack {
                ParkTheme.Color.background.ignoresSafeArea()

                if rankingVC.isLoading {
                    ProgressView().tint(ParkTheme.Color.accentLight)
                } else if let err = rankingVC.errorMsg {
                    VStack(spacing: 12) {
                        Text(err).foregroundStyle(ParkTheme.Color.ocupado).multilineTextAlignment(.center)
                        Button("Reintentar") { Task { await rankingVC.loadRanking() } }
                            .foregroundStyle(ParkTheme.Color.accentLight)
                    }.padding()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            RankingHero(
                                mesTexto: rankingVC.mesTexto,
                                onAnterior: { rankingVC.mesAnterior() },
                                onSiguiente: { rankingVC.mesSiguiente() }
                            )

                            VStack(spacing: 12) {
                                if rankingVC.ranking.isEmpty {
                                    ContentUnavailableView(
                                        "Sin datos",
                                        systemImage: "trophy",
                                        description: Text("No hay ranking para este mes.")
                                    )
                                } else {
                                    ForEach(rankingVC.ranking) { entry in
                                        RankingRow(entry: entry, currentUsername: session?.username)
                                    }
                                }
                            }
                            .padding(16)
                            .padding(.bottom, 24)
                        }
                    }
                    .refreshable { await rankingVC.loadRanking() }
                    .ignoresSafeArea(edges: .top)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await rankingVC.loadRanking() }
    }
}

// ── CINEMATIC HERO ────────────────────────────────────────────────────────────
private struct RankingHero: View {
    let mesTexto: String
    let onAnterior: () -> Void
    let onSiguiente: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            Color.black.ignoresSafeArea(edges: .top)

            // Animated blobs — amber / orange
            CinematicBackground(
                accent:  Color(hex: "#B45309"),
                accent2: Color(hex: "#C2410C")
            )
            .ignoresSafeArea(edges: .top)

            LinearGradient(
                colors: [.black.opacity(0.38), .black.opacity(0.72)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

            Text("TOP")
                .font(.system(size: 75, weight: .black))
                .foregroundStyle(.white.opacity(0.05))
                .kerning(-3)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 8)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, ParkTheme.Color.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 28)
            }

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 64)

                Text("PUCE · COMPETENCIA MENSUAL")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .kerning(2.5)
                    .padding(.bottom, 14)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Ranking")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(.white.opacity(0.48))
                        .kerning(-1)
                    Text("Mensual.")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .kerning(-1)
                        .padding(.top, -8)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.55).delay(0.2), value: appeared)

                Spacer().frame(height: 20)

                // Month navigator
                HStack(spacing: 16) {
                    Button(action: onAnterior) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    Text(mesTexto)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Button(action: onSiguiente) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.easeOut(duration: 0.5).delay(0.38), value: appeared)

                Spacer().frame(height: 52)
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 310)
        .onAppear { appeared = true }
    }
}
