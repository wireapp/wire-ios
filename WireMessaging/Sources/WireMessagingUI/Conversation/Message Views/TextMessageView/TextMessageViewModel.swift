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
package import Foundation

package class TextMessageViewModel: ObservableObject, Hashable, @unchecked Sendable {

    package let id = UUID()

    @Published var content: AttributedString

    @Published var senderViewModel: SenderViewModel

    init(
        content: AttributedString,
        senderViewModel: SenderViewModel
    ) {
        self.content = content
        self.senderViewModel = senderViewModel
    }

    package static func == (lhs: TextMessageViewModel, rhs: TextMessageViewModel) -> Bool {
        lhs.id == rhs.id
    }

    package func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}
