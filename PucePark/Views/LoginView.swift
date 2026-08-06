import SwiftUI

struct LoginView: View {
    @ObservedObject var authVC: AuthViewController

    @State private var username  = ""
    @State private var password  = ""
    @State private var showPass  = false
    @FocusState private var focused: Field?
    private enum Field { case user, pass }

    var body: some View {
        ZStack {
            Image("bg_campus")
                .resizable().scaledToFill().ignoresSafeArea()
                .blur(radius: 6)

            LinearGradient(stops: [
                .init(color: Color(hex: "#0A1628").opacity(0.05), location: 0),
                .init(color: Color(hex: "#060E1E").opacity(0.45), location: 0.50),
                .init(color: Color(hex: "#040A14").opacity(0.90), location: 1)
            ], startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo
                HStack(spacing: 10) {
                    Image("logo_puce")
                        .resizable().scaledToFit()
                        .frame(width: 32, height: 32).clipShape(Circle())
                    Text("PucePark")
                        .font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 28).padding(.top, 60)

                Spacer()

                // Hero
                VStack(spacing: 0) {
                    Text("PUCE · PARQUEO INTELIGENTE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55)).kerning(2.5)
                        .padding(.bottom, 18)
                    VStack(spacing: 0) {
                        Text("Bienvenido")
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(.white.opacity(0.50)).kerning(-1.5)
                        Text("al Campus.")
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(.white).kerning(-1.5).padding(.top, -10)
                    }
                    .padding(.bottom, 12)
                    Text("Ingresa con tu cuenta PUCE")
                        .font(.system(size: 15)).foregroundStyle(.white.opacity(0.55))
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 44)

                // Fields
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.white.opacity(0.7)).frame(width: 20)
                        TextField("", text: $username,
                                  prompt: Text("Usuario PUCE").foregroundStyle(.white.opacity(0.5)))
                            .foregroundStyle(.white)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .focused($focused, equals: .user)
                            .submitLabel(.next)
                            .onSubmit { focused = .pass }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14))

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
                        Text(err).font(.caption)
                            .foregroundStyle(Color(hex: "#EF4444"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 14)

                // CTA
                Button(action: doLogin) {
                    Group {
                        if authVC.isLoading {
                            ProgressView().tint(.white).scaleEffect(0.85)
                        } else {
                            Text("Iniciar sesión").fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                }
                .background(Color(hex: "#2563EB"))
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .disabled(authVC.isLoading || username.isEmpty || password.isEmpty)
                .padding(.horizontal, 28).padding(.bottom, 52)
            }
        }
        .onTapGesture { focused = nil }
    }

    private func doLogin() {
        focused = nil
        Task { await authVC.login(username: username, password: password) }
    }
}
