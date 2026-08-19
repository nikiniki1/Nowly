import SwiftUI

struct ActivityRefinementPickerView: View {
    let root: ActivityDefinition
    let definitions: [ActivityDefinition]
    @Binding var selectedActivityID: UUID?

    @State private var destination: ActivityDefinition?
    @Environment(\.dismiss) private var dismiss

    private var children: [ActivityDefinition] {
        definitions
            .filter { $0.parentID == root.id && !$0.isArchived }
            .sorted { $0.sortOrder == $1.sortOrder ? $0.id.uuidString < $1.id.uuidString : $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            Button("Без уточнения") {
                selectedActivityID = nil
                dismiss()
            }
            .buttonStyle(.plain)

            ForEach(children) { activity in
                HStack {
                    Button(activity.displayName) {
                        selectedActivityID = activity.id
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if hasChildren(activity) {
                        Button { destination = activity } label: {
                            Image(systemName: "chevron.right")
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Уточнить: \(activity.displayName)"))
                    }
                }
            }
        }
        .navigationTitle(root.displayName)
        .navigationDestination(item: $destination) { activity in
            ActivityRefinementPickerView(root: activity, definitions: definitions, selectedActivityID: $selectedActivityID)
        }
    }

    private func hasChildren(_ activity: ActivityDefinition) -> Bool {
        definitions.contains { $0.parentID == activity.id && !$0.isArchived }
    }
}
