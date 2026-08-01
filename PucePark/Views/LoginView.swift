import SwiftUI

struct LoginView: View {
    @ObservedObject var authVC: AuthViewController
    // nil = role picker, false = student, true = guard
    @State private var selectedRole: Bool? = nil

    var body: some View {
        ZStack {
            // ── Background ───────────────────────────────────────────────
            Image(selectedRole == true ? "bg_guardia" : "bg_campus")
                .resizable().scaledToFill().ignoresSafeArea()
                .blur(radius: 5)
                .animation(.easeInOut(duration: 0.5), value: selectedRole)

            LinearGradient(stops: [
                .init(color: Color(hex: "#0A1628").opacity(0.05), location: 0),
                .init(color: Color(hex: "#060E1E").opacity(0.40), location: 0.50),
                .init(color: Color(hex: "#040A14").opacity(0.88), location: 1)
            ], startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            if selectedRole == nil {
                RolePickerContent(onSelect: { role in
                    withAnimation(.easeInOut(duration: 0.35)) { selectedRole = role }
                })
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            } else {
                LoginFormContent(
                    authVC: authVC,
                    isGuardMode: selectedRole == true,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            selectedRole = nil
                            authVC.errorMsg = nil
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
    }
}

// ── ROLE PICKER ──────────────────────────────────────────────────────────────
private struct RolePickerContent: View {
    let onSelect: (Bool) -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image("logo_puce")
                    .resizable().scaledToFit().frame(width: 32, height: 32).clipShape(Circle())
                Text("PucePark")
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 28).padding(.top, 60)

            Spacer()

            VStack(spacing: 0) {
                Text("PUCE · PARQUEO INTELIGENTE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55)).kerning(2.5).padding(.bottom, 18)
                VStack(spacing: 0) {
                    Text("Bienvenido")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(.white.opacity(0.50)).kerning(-1.5)
                    Text("al Campus.")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(.white).kerning(-1.5).padding(.top, -10)
                }
                .padding(.bottom, 16)
                Text("¿Cómo deseas ingresar?")
                    .font(.system(size: 16)).foregroundStyle(.white.opacity(0.60))
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.easeOut(duration: 0.55).delay(0.1), value: appeared)

            Spacer(minLength: 44)

            VStack(spacing: 14) {
                RoleCard(
                    icon: "graduationcap.fill",
                    title: "Estudiante",
                    subtitle: "Gestiona tu espacio de parqueo",
                    accentColor: Color(hex: "#4A90D9"),
                    delay: 0.25, appeared: appeared,
                    action: { onSelect(false) }
                )
                RoleCard(
                    icon: "shield.lefthalf.filled",
                    title: "Guardia",
                    subtitle: "Administra y supervisa el parqueo",
                    accentColor: Color(hex: "#7EB8D4"),
                    delay: 0.35, appeared: appeared,
                    action: { onSelect(true) }
                )
            }
            .padding(.horizontal, 28).padding(.bottom, 60)
        }
        .onAppear { appeared = true }
    }
}

private struct RoleCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let delay: Double
    let appeared: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(accentColor.opacity(0.2)).frame(width: 52, height: 52)
                    Image(systemName: icon).font(.system(size: 22)).foregroundStyle(accentColor)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 13)).foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white.opacity(0.35))
            }
            .padding(18)
            .glassEffect(in: RoundedRectangle(cornerRadius: 16))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .animation(.easeOut(duration: 0.5).delay(delay), value: appeared)
    }
}

// ── LOGIN FORM ────────────────────────────────────────────────────────────────
private struct LoginFormContent: View {
    @ObservedObject var authVC: AuthViewController
    let isGuardMode: Bool
    let onBack: () -> Void

    @State private var username = ""
    @State private var password = ""
    @State private var showPass = false
    @FocusState private var focused: FormField?
    private enum FormField { case user, pass }

    private var accent: Color { isGuardMode ? Color(hex: "#7EB8D4") : Color(hex: "#4A90D9") }

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                        Text("Roles").font(.system(size: 15))
                    }
                    .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                Text(isGuardMode ? "Guardia" : "Estudiante")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(.white.opacity(0.12)).clipShape(Capsule())
            }
            .padding(.horizontal, 28).padding(.top, 60)

            Spacer(minLength: 36)

            // Hero
            VStack(spacing: 0) {
                Text(isGuardMode ? "PUCE · SEGURIDAD" : "PUCE · PARQUEO INTELIGENTE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55)).kerning(2.5).padding(.bottom, 18)
                VStack(spacing: 0) {
                    Text(isGuardMode ? "Turno." : "Campus.")
                        .font(.system(size: 58, weight: .light))
                        .foregroundStyle(.white.opacity(0.50)).kerning(-1.5)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(isGuardMode ? "Activo." : "Parking.")
                        .font(.system(size: 58, weight: .light))
                        .foregroundStyle(.white).kerning(-1.5).padding(.top, -12)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.bottom, 18)
                Text(isGuardMode ? "Accede a tu turno de control." : "Tu espacio, reservado para ti.")
                    .font(.system(size: 16)).foregroundStyle(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 44)

            // Fields
            VStack(spacing: 10) {
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
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 28).padding(.bottom, 14)

            // CTA
            Button(action: doLogin) {
                Group {
                    if authVC.isLoading {
                        ProgressView().tint(.white).scaleEffect(0.85)
                    } else {
                        Text(isGuardMode ? "Verificar Turno" : "Ingresar").fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity).frame(height: 50)
            }
            .background(accent)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .disabled(authVC.isLoading)
            .padding(.horizontal, 28).padding(.bottom, 52)
        }
    }

    private func doLogin() {
        focused = nil
        Task { await authVC.login(username: username, password: password) }
    }
}
