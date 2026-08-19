import SwiftUI
import Testing
@testable import Nowly

@Test func themePreferenceMapsToExpectedColorScheme() {
    #expect(ThemePreference.system.colorScheme == nil)
    #expect(ThemePreference.light.colorScheme == .light)
    #expect(ThemePreference.dark.colorScheme == .dark)
}
