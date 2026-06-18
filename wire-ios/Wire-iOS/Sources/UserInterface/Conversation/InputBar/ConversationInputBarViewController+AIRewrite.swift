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

import UIKit
import WireLogging
import WireMessagingDomain

// MARK: - Edit-menu AI rewrite actions

extension ConversationInputBarViewController {

    // UITextViewDelegate — available from iOS 16, guarded to iOS 26 for Foundation Models.
    @available(iOS 16.0, *)
    func textView(
        _ textView: UITextView,
        editMenuForTextIn range: NSRange,
        suggestedActions: [UIMenuElement]
    ) -> UIMenu? {
        guard #available(iOS 26.0, *), TextRewriter.isAvailable else {
            return UIMenu(children: suggestedActions)
        }
        guard !(textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return UIMenu(children: suggestedActions)
        }
        let aiActions = TextRewriter.Style.allCases.map { style in
            UIAction(title: style.label, image: UIImage(systemName: "sparkles")) { [weak self] _ in
                self?.rewrite(style: style)
            }
        }
        let aiMenu = UIMenu(title: "", options: .displayInline, children: aiActions)
        return UIMenu(children: suggestedActions + [aiMenu])
    }

    // MARK: - Private

    @available(iOS 26.0, *)
    func rewrite(style: TextRewriter.Style) {
        let original = inputBar.textView.text ?? ""
        guard !original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        WireLogger.conversation.info("AI rewrite requested: \(style.label)")
        inputBar.textView.isEditable = false

        Task { @MainActor in
            defer { inputBar.textView.isEditable = true }
            do {
                let rewritten = try await TextRewriter().rewrite(original, style: style)
                inputBar.textView.text = rewritten
                inputBar.textView.delegate?.textViewDidChange?(inputBar.textView)
                WireLogger.conversation.info("AI rewrite complete")
            } catch {
                WireLogger.conversation.error("AI rewrite failed: \(error)")
            }
        }
    }
}
