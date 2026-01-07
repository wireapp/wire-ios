//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import SwiftUI

public extension View {

    /// Presents an alert with a message and title based on the provided `item`.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional value that determines whether to present the alert. When the user presses or
    /// taps one of the alert’s actions, the system sets this value to false and dismisses the alert.
    ///   - title: A closure that returns the title of the alert.
    ///   - message: A closure that returns the message of the alert.
    ///   - actions: A closure that returns the actions of the alert.

    nonisolated func alert<Item>(
        item: Binding<Item?>,
        title: (Item) -> Text,
        @ViewBuilder message: (Item) -> some View,
        @ViewBuilder actions: (Item) -> some View
    ) -> some View where Item: Sendable {
        alert(
            item.wrappedValue.map { title($0) } ?? Text(verbatim: ""),
            isPresented: .init(
                get: { item.wrappedValue != nil },
                set: { if !$0 { item.wrappedValue = nil } }
            ),
            presenting: item.wrappedValue,
            actions: actions,
            message: message
        )
    }

}
