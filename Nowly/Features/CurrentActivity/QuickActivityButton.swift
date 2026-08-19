import SwiftUI

struct QuickActivityButton: View {
    private enum Layout {
        static let buttonHeight: CGFloat = 52
        static let rowHeight: CGFloat = 44
        static let cardPadding: CGFloat = 8
        static let cardSpacing: CGFloat = 12
    }

    let activity: ActivityDefinition
    let definitionRepository: any ActivityDefinitionRepository
    @Binding var activeRefinementID: UUID?
    let onSelect: (ActivityDefinition) -> Void

    @State private var children: [ActivityDefinition] = []
    @State private var isShowingRefinement = false
    @State private var highlightedChildID: UUID?
    @GestureState private var isPressing = false

    var body: some View {
        VStack(alignment: .center, spacing: Layout.cardSpacing) {
            activityLabel
                .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 44) {
                    showRefinement()
                }
                .simultaneousGesture(dragGesture)

            if isShowingRefinement, !children.isEmpty {
                refinementCard
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            }
        }
            .zIndex(isShowingRefinement ? 1 : 0)
            .task(id: activity.id) {
                children = (try? await definitionRepository.children(of: activity.id)) ?? []
            }
            .onChange(of: activeRefinementID) { _, newValue in
                if newValue != activity.id {
                    dismissRefinement()
                }
            }
            .animation(.snappy(duration: 0.2), value: isShowingRefinement)
    }

    private var activityLabel: some View {
        Text(activity.displayName)
        .font(.body.weight(.medium))
        .frame(maxWidth: .infinity, minHeight: Layout.buttonHeight)
        .padding(.horizontal)
        .multilineTextAlignment(.center)
        .foregroundStyle(.tint)
        .background(.tint.opacity(isPressing ? 0.18 : 0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture {
            guard !isShowingRefinement else { return }
            onSelect(activity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Начать: \(activity.displayName)"))
        .accessibilityHint("Двойное касание начинает активность. Доступно действие «Уточнить».")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onSelect(activity) }
        .accessibilityAction(named: Text("Уточнить")) { showRefinement() }
        .accessibilityIdentifier("quick-activity")
    }

    private var refinementCard: some View {
        VStack(spacing: 0) {
            ForEach(children) { child in
                Button {
                    select(child)
                } label: {
                    Text(child.displayName)
                    .frame(maxWidth: .infinity, minHeight: Layout.rowHeight)
                    .padding(.horizontal, 12)
                    .multilineTextAlignment(.center)
                    .background(rowBackground(isHighlighted: highlightedChildID == child.id))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Начать: \(child.displayName)"))
            }
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.separator.opacity(0.5))
        }
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("activity-refinement-card")
    }

    @ViewBuilder
    private func rowBackground(isHighlighted: Bool) -> some View {
        if isHighlighted {
            Color.accentColor.opacity(0.16)
        } else {
            Color.clear
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isPressing) { _, state, _ in state = true }
            .onChanged { value in
                guard isShowingRefinement else { return }
                highlightedChildID = child(at: value.location)
            }
            .onEnded { value in
                guard isShowingRefinement else { return }
                if let childID = child(at: value.location), let child = children.first(where: { $0.id == childID }) {
                    select(child)
                } else {
                    dismissRefinement()
                }
            }
    }

    private func child(at location: CGPoint) -> UUID? {
        let cardTop = Layout.buttonHeight + Layout.cardSpacing
        let relativeY = location.y - cardTop - Layout.cardPadding
        let index = Int(relativeY / Layout.rowHeight)
        guard children.indices.contains(index) else { return nil }
        return children[index].id
    }

    private func showRefinement() {
        guard !children.isEmpty else { return }
        activeRefinementID = activity.id
        isShowingRefinement = true
    }

    private func select(_ child: ActivityDefinition) {
        dismissRefinement()
        onSelect(child)
    }

    private func dismissRefinement() {
        isShowingRefinement = false
        highlightedChildID = nil
        if activeRefinementID == activity.id {
            activeRefinementID = nil
        }
    }
}
