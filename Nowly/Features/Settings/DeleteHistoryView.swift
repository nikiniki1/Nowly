import SwiftUI

struct DeleteHistoryView: View {
    let eventRepository: any ActivityEventRepository
    @State private var selectedDate = Date()
    @State private var deletion: Deletion?
    @State private var errorMessage: String?
    @State private var deletedCount: Int?

    var body: some View {
        Form {
            Section("Удаление") {
                DatePicker("День", selection: $selectedDate, displayedComponents: .date)

                Button("Удалить записи за этот день", role: .destructive) {
                    deletion = .day
                }

                Button("Удалить всю историю", role: .destructive) {
                    deletion = .all
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("Удалить историю")
        .confirmationDialog(deletion?.title ?? "", isPresented: Binding(
            get: { deletion != nil },
            set: { if !$0 { deletion = nil } }
        ), titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                guard let deletion else { return }
                Task { await confirmDeletion(deletion) }
            }
        } message: {
            Text(deletion?.message ?? "")
        }
        .alert("История удалена", isPresented: Binding(
            get: { deletedCount != nil },
            set: { if !$0 { deletedCount = nil } }
        )) {
            Button("Готово", role: .cancel) { }
        } message: {
            Text("Удалено записей: \(deletedCount ?? 0)")
        }
    }

    private func confirmDeletion(_ deletion: Deletion) async {
        self.deletion = nil
        do {
            let interval = deletion == .day ? Calendar.current.dateInterval(of: .day, for: selectedDate) : nil
            deletedCount = try await eventRepository.deleteEvents(in: interval)
            NotificationCenter.default.post(name: .activityHistoryDidChange, object: nil)
        } catch {
            errorMessage = "Не удалось удалить записи: \(error.localizedDescription)"
        }
    }

    private enum Deletion {
        case day, all

        var title: String { "Удалить историю?" }
        var message: String {
            switch self {
            case .day: "Будут удалены все записи, пересекающиеся с этим днём. Это действие нельзя отменить."
            case .all: "Будут удалены все записи истории. Активности и подкатегории останутся. Это действие нельзя отменить."
            }
        }
    }
}

extension Notification.Name {
    static let activityHistoryDidChange = Notification.Name("activityHistoryDidChange")
}
