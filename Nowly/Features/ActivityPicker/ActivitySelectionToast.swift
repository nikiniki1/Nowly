import SwiftUI

struct ActivitySelectionToast: View {
    let activityName: String

    var body: some View {
        Label(String(localized: "Выбрано: \(activityName)"), systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .foregroundStyle(.primary)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
            .accessibilityAddTraits(.isStaticText)
    }
}
