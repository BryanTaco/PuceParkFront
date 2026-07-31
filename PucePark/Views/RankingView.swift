import SwiftUI

struct RankingView: View {
    @StateObject private var rankingVC = RankingViewController()
    @Environment(\.authSession) private var session

    var body: some View {
        NavigationStack {
            ZStack {
                ParkTheme.Color.background.ignoresSafeArea()
                Group {
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
                            VStack(spacing: 12) {
                                // Month nav
                                HStack {
                                    Button { rankingVC.mesAnterior() } label: {
                                        Image(systemName: "chevron.left").foregroundStyle(ParkTheme.Color.accentLight)
                                    }
                                    Spacer()
                                    Text(rankingVC.mesTexto)
                                        .font(.subheadline).fontWeight(.semibold)
                                        .foregroundStyle(ParkTheme.Color.textPrimary)
                                    Spacer()
                                    Button { rankingVC.mesSiguiente() } label: {
                                        Image(systemName: "chevron.right").foregroundStyle(ParkTheme.Color.accentLight)
                                    }
                                }
                                .padding(.horizontal, 8)

                                if rankingVC.ranking.isEmpty {
                                    ContentUnavailableView("Sin datos", systemImage: "trophy",
                                        description: Text("No hay ranking para este mes."))
                                } else {
                                    ForEach(rankingVC.ranking) { entry in
                                        RankingRow(entry: entry, currentUsername: session?.username)
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .refreshable { await rankingVC.loadRanking() }
                    }
                }
            }
            .navigationTitle("Ranking Mensual")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { await rankingVC.loadRanking() }
    }
}
