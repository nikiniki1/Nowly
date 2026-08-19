//
//  NowlyApp.swift
//  Nowly
//
//  Created by Nikita Demianchuk on 19.08.2026.
//

import SwiftUI
import SwiftData

@main
@MainActor
struct NowlyApp: App {
    private let dependencies = AppDependencies.production()
    @State private var isReady = false
    @AppStorage(ThemePreference.storageKey) private var themePreferenceRawValue = ThemePreference.system.rawValue

    var body: some Scene {
        WindowGroup {
            Group {
                if isReady {
                    ContentView(
                        eventRepository: dependencies.repository,
                        definitionRepository: dependencies.repository,
                        switchingService: dependencies.switchingService
                    )
                } else {
                    ProgressView()
                }
            }
            .task {
                if !isReady {
                    try? await dependencies.repository.seedInitialDefinitions()
                    isReady = true
                }
            }
            .preferredColorScheme(ThemePreference(rawValue: themePreferenceRawValue)?.colorScheme)
        }
        .modelContainer(dependencies.modelContainer)
    }
}
