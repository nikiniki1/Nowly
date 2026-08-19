//
//  ContentView.swift
//  Nowly
//
//  Created by Nikita Demianchuk on 19.08.2026.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var viewModel: CurrentActivityViewModel
    private let eventRepository: any ActivityEventRepository
    private let definitionRepository: any ActivityDefinitionRepository

    init(
        eventRepository: any ActivityEventRepository,
        definitionRepository: any ActivityDefinitionRepository,
        switchingService: ActivitySwitchingService
    ) {
        self.eventRepository = eventRepository
        self.definitionRepository = definitionRepository
        _viewModel = State(initialValue: CurrentActivityViewModel(
            eventRepository: eventRepository,
            definitionRepository: definitionRepository,
            switchingService: switchingService,
            onActivityChanged: { WidgetCenter.shared.reloadTimelines(ofKind: "ActivityWidget") }
        ))
    }

    var body: some View {
        TabView {
            CurrentActivityView(
                viewModel: viewModel,
                eventRepository: eventRepository,
                definitionRepository: definitionRepository
            )
            .tabItem {
                Label("Сейчас", systemImage: "circle.fill")
            }

            NavigationStack {
                RootActivityPickerView(definitionRepository: definitionRepository) { activity in
                    Task { await viewModel.select(activity) }
                }
            }
            .tabItem {
                Label("Активности", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                TimelineView(eventRepository: eventRepository, definitionRepository: definitionRepository)
            }
            .tabItem {
                Label("История", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                SettingsView(
                    eventRepository: eventRepository,
                    definitionRepository: definitionRepository
                ) { activity in
                    Task { await viewModel.select(activity) }
                }
            }
            .tabItem {
                Label("Настройки", systemImage: "gearshape")
            }
        }
    }
}
