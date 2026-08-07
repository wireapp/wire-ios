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
import WireCoreCrypto

final class CoreCryptoMetadataViewModel {
    let sections: [DeveloperToolsViewModel.Section]

    init() {
        let metadata = WireCoreCrypto.buildMetadata()

        self.sections = [
            .init(
                header: "Build metadata",
                items: [
                    .text(.init(title: "Timestamp", value: metadata.timestamp)),
                    .text(.init(title: "Cargo debug", value: metadata.cargoDebug)),
                    .text(.init(title: "Cargo features", value: metadata.cargoFeatures)),
                    .text(.init(title: "Optimization level", value: metadata.optLevel)),
                    .text(.init(title: "Target triple", value: metadata.targetTriple)),
                    .text(.init(title: "Git branch", value: metadata.gitBranch)),
                    .text(.init(title: "Git describe", value: metadata.gitDescribe)),
                    .text(.init(title: "Git SHA", value: metadata.gitSha)),
                    .text(.init(title: "Git dirty", value: metadata.gitDirty))
                ]
            )
        ]
    }

    // MARK: - Events

    func handleEvent(_ event: DeveloperToolsViewModel.Event) {
        switch event {
        case let .itemCopyRequested(.text(textItem)):
            UIPasteboard.general.string = textItem.value

        default:
            break
        }
    }
}
