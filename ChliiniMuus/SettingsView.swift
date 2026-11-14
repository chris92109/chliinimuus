import PhotosUI
import SwiftUI

struct SettingsView: View {
    let onSave: (ProfileStore.Profile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var birthDate: Date

    // Widget background
    @State private var background: UIImage? = BackgroundImageStore.load()
    @State private var backgroundChanged = false
    @State private var photoItem: PhotosPickerItem?
    @State private var loadingPhoto = false

    init(initial: ProfileStore.Profile?, onSave: @escaping (ProfileStore.Profile) -> Void) {
        self.onSave = onSave
        _name = State(initialValue: initial?.name ?? "")
        _birthDate = State(initialValue: initial?.birthDate
                           ?? Calendar.current.date(byAdding: .year, value: -1, to: .now)!)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                Section("Geburtstag") {
                    DatePicker("Geburtsdatum",
                               selection: $birthDate,
                               in: ...Date.now,
                               displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                backgroundSection
                Section {
                    Text("Das Widget zeigt das Alter in Tagen. Füge es auf dem Home-Bildschirm oder Sperrbildschirm hinzu.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profil bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        if backgroundChanged { BackgroundImageStore.save(background) }
                        onSave(.init(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                     birthDate: birthDate))
                        dismiss()
                    }
                    .disabled(loadingPhoto)
                }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                loadingPhoto = true
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        background = BackgroundImageStore.downscaled(image)
                        backgroundChanged = true
                    }
                    photoItem = nil
                    loadingPhoto = false
                }
            }
        }
    }

    private var backgroundSection: some View {
        Section {
            WidgetPreview(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                          birthDate: birthDate,
                          image: background,
                          loading: loadingPhoto)
                .listRowInsets(EdgeInsets())

            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                Label(background == nil ? "Foto auswählen" : "Foto ändern", systemImage: "photo")
            }
            if background != nil {
                Button("Foto entfernen", systemImage: "trash", role: .destructive) {
                    background = nil
                    backgroundChanged = true
                }
            }
        } header: {
            Text("Widget-Hintergrund")
        } footer: {
            Text("Das Foto wird leicht abgedunkelt, damit die Zahlen gut lesbar bleiben.")
        }
    }
}

/// Live preview of the medium Home Screen widget, using the same view the
/// widget itself renders, so it updates as the name, date or photo change.
private struct WidgetPreview: View {
    let name: String
    let birthDate: Date
    let image: UIImage?
    let loading: Bool

    var body: some View {
        ZStack {
            WidgetBackground(image: image)
            if loading {
                ProgressView().tint(.white)
            } else {
                WidgetContentView(family: .systemMedium,
                                  profile: .init(name: name, birthDate: birthDate),
                                  date: .now)
                    .padding(16)
            }
        }
        // Size of a medium widget on a 6.3" iPhone.
        .frame(width: 338, height: 158)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}
