//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import AppIntents
import WireDesign

struct NotifyAboutDelay: AppIntent {
    static var title: LocalizedStringResource { "NotifyAboutDelay" }

    static var description = IntentDescription("Opens the app and goes to your favorite trails.")

    static var openAppWhenRun: Bool = true

    //@MainActor
    func perform() async throws -> some IntentResult {
//        navigationModel.selectedCollection = trailManager.favoritesCollection

        return .result()
    }

//    @Dependency
//    private var navigationModel: NavigationModel
//
//    @Dependency
//    private var trailManager: TrailDataManager
}

struct AppShortcuts: AppShortcutsProvider {

    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NotifyAboutDelay(),
            phrases: ["Make a New \(.applicationName)"],
            shortTitle: LocalizedStringResource(stringLiteral: "New Feature"),
            systemImageName: "apple.logo"
        )
    }

}
