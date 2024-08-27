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

@available(iOS 16.0, *)
struct AppShortcuts: AppShortcutsProvider {

    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {

            AppShortcut(
                intent: SendQuickResponseIntent(),
                phrases: [],
                shortTitle: LocalizedStringResource(stringLiteral: "New Feature"),
                systemImageName: "apple.logo"
//                parameterPresentation: .init(
//                    for: \.$conversation,
//                    summary: Summary("Get \(\.$conversation) conversations"),
//                    optionsCollections: {
//                        OptionsCollection(ConversationEntityQuery(), title: "Conversations", systemImageName: "cloud.rainbow.half")
//                    }
//                )
            )

            AppShortcut(
                intent: OpenWireIntent(),
                phrases: [],
                shortTitle: LocalizedStringResource(stringLiteral: "sdfa"),
                systemImageName: "gears"
            )

    }
}

// TODO: read https://arctouch.com/blog/implementing-app-shortcuts-intents
