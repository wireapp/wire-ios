//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

public import SwiftUI

/// The main conversation view, displaying messages as chat bubbles
public struct ConversationView: View {
    public init() {}

    public var body: some View {
        let text = "The new conversation view for messages displayed as chat bubbles."
        Text(text)
            .multilineTextAlignment(.center)
            .padding()
    }
}

public extension ConversationView {
    var viewController: UIViewController {
        let viewController = UIHostingController(rootView: Self())
        viewController.view.backgroundColor = .clear
        return viewController
    }
}

#Preview {
    ConversationView()
}
