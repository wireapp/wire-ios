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

import Foundation

extension TagsEditView {
    @MainActor
    final class ViewModel: ObservableObject {
        private let fileItem: FilesViewItem
        
        let invalidCharacters: [Character] = [",", ";", "/", "\\", "\"", "'", "<", ">"]
        
        init(fileItem: FilesViewItem) {
            self.fileItem = fileItem
        }
        
        var invalidCharactersErrorMessage: String {
            let message = L10n.Localizable.Conversation.WireCells.Tags.Error.specialCharacters
            let nonBreakingSpace = "\u{A0}"
            let invalidCharactersFormatted = invalidCharacters.map { String($0) }.joined(separator: nonBreakingSpace)
            return message.replacing("{0}", with: invalidCharactersFormatted)
        }
        
        func save() {
            //TODO: ...
        }
    }
}
