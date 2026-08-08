import SwiftUI

struct AdminView: View {
    @StateObject private var vc = AdminViewController()
    @State private var showNuevaZona = false
    @State private var zonaParaPuesto: ZonaParqueo?

    var body: some View {
        NavigationStack {
            ZStack {
                ParkTheme.Color.background.ignoresSafeArea()

                if vc.isLoading && vc.zonas.isEmpty {
                    ProgressView().tint(ParkTheme.Color.accentLight)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Administración")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.top, 8)
                            Text("Gestiona zonas y puestos de parqueo")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))

                            if let ok = vc.successMsg {
                                mensaje(ok, color: ParkTheme.Color.disponible)
                            }
                            if let err = vc.errorMsg {
                                mensaje(err, color: ParkTheme.Color.ocupado)
                            }

                            Button { showNuevaZona = true } label: {
                                Label("Nueva zona", systemImage: "plus.circle.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity).frame(height: 46)
                                    .background(ParkTheme.Color.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.top, 4)

                            ForEach(vc.zonas) { zona in
                                zonaCard(zona)
                            }
                        }
                        .padding(16)
                    }
                    .refreshable { await vc.loadZonas() }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await vc.loadZonas() }
        .sheet(isPresented: $showNuevaZona) {
            NuevaZonaSheet(vc: vc)
        }
        .sheet(item: $zonaParaPuesto) { zona in
            NuevoPuestoSheet(vc: vc, zona: zona)
        }
    }

    private func mensaje(_ txt: String, color: Color) -> some View {
        Text(txt).font(.caption).foregroundStyle(color)
            .padding(10).frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func zonaCard(_ zona: ZonaParqueo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(zona.name).font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                    Text(zona.location).font(.caption).foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                Text("\(zona.occupiedSpaces)/\(zona.totalSpaces)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ParkTheme.Color.accentLight)
            }
            HStack(spacing: 10) {
                Button { zonaParaPuesto = zona } label: {
                    Label("Agregar puesto", systemImage: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ParkTheme.Color.accentLight)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(ParkTheme.Color.accent.opacity(0.15))
                        .clipShape(Capsule())
                }
                Spacer()
                Button(role: .destructive) {
                    Task { await vc.eliminarZona(zona) }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ParkTheme.Color.ocupado)
                        .padding(9)
                        .background(ParkTheme.Color.ocupado.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(ParkTheme.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// ── Sheet: nueva zona ─────────────────────────────────────────────────────────
private struct NuevaZonaSheet: View {
    @ObservedObject var vc: AdminViewController
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var location = ""
    @State private var maxCapacity = ""

    private var puedeGuardar: Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 2 && (Int(maxCapacity) ?? 0) >= 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ParkTheme.Color.surface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        campo("Nombre de la zona", text: $name)
                        campo("Descripción", text: $description)
                        campo("Ubicación", text: $location)
                        campo("Capacidad máxima", text: $maxCapacity, keyboard: .numberPad)

                        if let err = vc.errorMsg {
                            Text(err).font(.caption).foregroundStyle(ParkTheme.Color.ocupado)
                        }

                        Button {
                            Task {
                                let ok = await vc.crearZona(
                                    name: name.trimmingCharacters(in: .whitespaces),
                                    description: description, maxCapacity: Int(maxCapacity) ?? 0,
                                    location: location)
                                if ok { dismiss() }
                            }
                        } label: {
                            Group {
                                if vc.isSaving { ProgressView().tint(.white) }
                                else { Text("Crear zona").fontWeight(.semibold) }
                            }
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(puedeGuardar ? ParkTheme.Color.accent : ParkTheme.Color.card)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!puedeGuardar || vc.isSaving)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Nueva zona")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) {
                Button("Cancelar") { dismiss() }.foregroundStyle(ParkTheme.Color.textSecond)
            } }
        }
    }

    private func campo(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.4)))
            .keyboardType(keyboard)
            .foregroundStyle(.white)
            .padding(14)
            .background(ParkTheme.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// ── Sheet: nuevo puesto ───────────────────────────────────────────────────────
private struct NuevoPuestoSheet: View {
    @ObservedObject var vc: AdminViewController
    let zona: ZonaParqueo
    @Environment(\.dismiss) private var dismiss
    @State private var spaceNumber = ""
    @State private var row = ""
    @State private var order = ""

    private var puedeGuardar: Bool {
        !spaceNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        !row.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Int(order) ?? 0) >= 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ParkTheme.Color.surface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Text("Zona: \(zona.name)")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        campo("Número (ej. A-31)", text: $spaceNumber)
                        campo("Fila (ej. A)", text: $row)
                        campo("Orden (ej. 31)", text: $order, keyboard: .numberPad)

                        if let err = vc.errorMsg {
                            Text(err).font(.caption).foregroundStyle(ParkTheme.Color.ocupado)
                        }

                        Button {
                            Task {
                                let ok = await vc.crearPuesto(
                                    zoneId: zona.id,
                                    spaceNumber: spaceNumber.trimmingCharacters(in: .whitespaces).uppercased(),
                                    row: row.trimmingCharacters(in: .whitespaces).uppercased(),
                                    order: Int(order) ?? 0)
                                if ok { dismiss() }
                            }
                        } label: {
                            Group {
                                if vc.isSaving { ProgressView().tint(.white) }
                                else { Text("Crear puesto").fontWeight(.semibold) }
                            }
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(puedeGuardar ? ParkTheme.Color.accent : ParkTheme.Color.card)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!puedeGuardar || vc.isSaving)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Nuevo puesto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) {
                Button("Cancelar") { dismiss() }.foregroundStyle(ParkTheme.Color.textSecond)
            } }
        }
    }

    private func campo(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.4)))
            .keyboardType(keyboard)
            .foregroundStyle(.white)
            .padding(14)
            .background(ParkTheme.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
