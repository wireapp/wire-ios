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

/// A button whose action is asynchronous.
struct AsyncButton<Label: View>: View {

    private let action: () async -> Void
    private let label: Label

    init(action: @escaping () async -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            label
        }
        .buttonStyle(.plain)
    }
}

extension AsyncButton where Label == Text {

    init(_ title: String, action: @escaping () async -> Void) {
        self.init(action: action) { Text(title) }
    }
}
