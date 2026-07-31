import SwiftUI

struct LoginView: View {
    @ObservedObject var authVC: AuthViewController
    @State private var username    = ""
    @State private var password    = ""
    @State private var showPass    = false
    @State private var isGuardMode = false
    @FocusState private var focused: Field?
    private enum Field { case user, pass }

    private var accent: Color { isGuardMode ? Color(hex: "#7EB8D4") : Color(hex: "#4A90D9") }

    var body: some View {
        ZStack {
            // ── Background photo ──────────────────────────────────────
            Image(isGuardMode ? "bg_guardia" : "bg_campus")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: isGuardMode)

            // Dark scrim — heavier at bottom for form legibility
            LinearGradient(stops: [
                .init(color: Color(hex: "#0A1628").opacity(0.1), location: 0),
                .init(color: Color(hex: "#060E1E").opacity(0.45), location: 0.55),
                .init(color: Color(hex: "#040A14").opacity(0.82), location: 1)
            ], startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            // ── Form + buttons pinned to bottom ───────────────────────
            VStack(spacing: 0) {
                Spacer()

                // ── Glass form ────────────────────────────────────────
                VStack(spacing: 10) {
                    // Username field
                    HStack(spacing: 12) {
                        Image(systemName: isGuardMode ? "person.badge.shield.checkmark.fill" : "person.fill")
                            .foregroundStyle(.white.opacity(0.7)).frame(width: 20)
                        TextField("", text: $username,
                                  prompt: Text(isGuardMode ? "ID Guardia" : "Usuario PUCE")
                                    .foregroundStyle(.white.opacity(0.5)))
                            .foregroundStyle(.white)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .focused($focused, equals: .user)
                            .submitLabel(.next)
                            .onSubmit { focused = .pass }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14))

                    // Password field
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.white.opacity(0.7)).frame(width: 20)
                        Group {
                            if showPass {
                                TextField("", text: $password,
                                          prompt: Text("Contraseña").foregroundStyle(.white.opacity(0.5)))
                            } else {
                                SecureField("", text: $password,
                                            prompt: Text("Contraseña").foregroundStyle(.white.opacity(0.5)))
                            }
                        }
                        .foregroundStyle(.white)
                        .focused($focused, equals: .pass)
                        .submitLabel(.go)
                        .onSubmit { doLogin() }
                        Button { showPass.toggle() } label: {
                            Image(systemName: showPass ? "eye.slash" : "eye")
                                .foregroundStyle(.white.opacity(0.5)).font(.system(size: 14))
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14))

                    if let err = authVC.errorMsg {
                        Text(err).font(.caption).foregroundStyle(Color(hex: "#EF4444"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 14)

                // ── CTA buttons ───────────────────────────────────────
                VStack(spacing: 10) {
                    // Primary — solid accent color
                    Button(action: doLogin) {
                        Group {
                            if authVC.isLoading { ProgressView().tint(.white).scaleEffect(0.85) }
                            else { Text(isGuardMode ? "Verificar Turno" : "Ingresar").fontWeight(.semibold) }
                        }
                        .frame(maxWidth: .infinity).frame(height: 50)
                    }
                    .background(accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .disabled(authVC.isLoading)
                    .animation(.easeInOut(duration: 0.25), value: isGuardMode)

                    // Secondary — liquid glass
                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) { isGuardMode.toggle() }
                        username = ""; password = ""; authVC.errorMsg = nil
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isGuardMode ? "person.fill" : "shield.fill")
                                .font(.system(size: 13))
                            Text(isGuardMode ? "Acceso Estudiante" : "¿Eres guardia? Verificar turno")
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(maxWidth: .infinity).frame(height: 44)
                    }
                    .glassEffect(in: Capsule())
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 52)
            }
        }
    }

    private func doLogin() {
        focused = nil
        Task { await authVC.login(username: username, password: password) }
    }
}
