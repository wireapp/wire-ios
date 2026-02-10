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

import Foundation

extension FilesFilterByTypeView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var selectedTypes: Set<FileType> = []

        var presentedTypes: [FileType] = [
            .pdf,
            .document,
            .image,
            .spreadsheet,
            .presentation,
            .video,
            .audio,
            //.code,
            //.archive,
            .folder,
            .other
        ]

        private let initiallySelectedTypes: Set<FileType>

        init(selectedTypes: some Collection<FileType>, includeFolders: Bool) {
            let types = Set(selectedTypes)
            self.selectedTypes = types
            self.initiallySelectedTypes = types
            if !includeFolders {
                presentedTypes.removeAll { $0 == .folder }
            }
        }

        var hasChanges: Bool {
            selectedTypes != initiallySelectedTypes
        }

        func isTypeSelected(_ type: FileType) -> Bool {
            selectedTypes.contains(type)
        }

        func toggleTypeSelection(_ type: FileType) {
            if selectedTypes.contains(type) {
                selectedTypes.remove(type)
            } else {
                selectedTypes.insert(type)
            }
        }

        func clearAll() {
            selectedTypes = []
        }
    }
}
