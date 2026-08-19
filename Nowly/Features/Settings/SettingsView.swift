import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    let eventRepository: any ActivityEventRepository
    let definitionRepository: any ActivityDefinitionRepository
    let onSelectActivity: (ActivityDefinition) -> Void

    @State private var exportDocument: ActivityHistoryExportDocument?
    @State private var isExporting = false
    @State private var exportErrorMessage: String?
    @AppStorage(ThemePreference.storageKey) private var themePreferenceRawValue = ThemePreference.system.rawValue

    var body: some View {
        Form {
            Section {
                NavigationLink {
                    PersonalInformationView()
                } label: {
                    Label("Информация о себе", systemImage: "person.crop.circle")
                }

            }

            Section("Оформление") {
                Picker("Тема", selection: $themePreferenceRawValue) {
                    ForEach(ThemePreference.allCases) { preference in
                        Text(preference.title).tag(preference.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Данные") {
                Button {
                    Task { await prepareExport() }
                } label: {
                    Label("Выгрузить историю", systemImage: "square.and.arrow.up")
                }
                .accessibilityHint("Откроет выбор папки для сохранения JSON-файла")

                NavigationLink {
                    DeleteHistoryView(
                        eventRepository: eventRepository
                    )
                } label: {
                    Label("Удалить историю", systemImage: "trash")
                }

                if let exportErrorMessage {
                    Text(exportErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Настройки")
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "history-export"
        ) { result in
            if case let .failure(error) = result {
                exportErrorMessage = "Не удалось выгрузить историю: \(error.localizedDescription)"
            }
        }
    }

    private func prepareExport() async {
        do {
            async let eventsLoad = eventRepository.events(in: DateInterval(start: .distantPast, end: .distantFuture))
            async let definitionsLoad = definitionRepository.allDefinitions()
            let (events, definitions) = try await (eventsLoad, definitionsLoad)
            let activityNames = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0.displayName) })

            exportDocument = ActivityHistoryExportDocument(
                data: try ActivityHistoryExport(events: events, activityNames: activityNames).encodedData()
            )
            isExporting = true
        } catch {
            exportErrorMessage = "Не удалось подготовить выгрузку: \(error.localizedDescription)"
        }
    }
}
