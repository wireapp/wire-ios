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

public final class ConversationMessagesViewController: UIViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        let label = UILabel()
        label.text = "The new conversation view \nfor messages displayed \nas chat bubbles."
        label.numberOfLines = 0
        label.sizeToFit()
        view.addSubview(label)
    }
}

private struct ConversationMessagesViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ConversationMessagesViewController {
        ConversationMessagesViewController()
    }

    func updateUIViewController(_ uiViewController: ConversationMessagesViewController, context: Context) {}
}

#Preview {
    ConversationMessagesViewControllerPreview()
}
