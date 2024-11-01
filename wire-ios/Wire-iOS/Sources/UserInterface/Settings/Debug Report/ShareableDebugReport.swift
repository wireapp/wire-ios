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

import WireDataModel
import WireDesign
import WireSyncEngine

struct ShareableDebugReport: Shareable {

    // MARK: - Types

    typealias I = ZMConversation

    // MARK: - Properties

    private(set) var logFileMetadata: ZMFileMetadata
    private(set) var shareFile: ShareFileUseCaseProtocol

    // MARK: - Interface

    func share<I>(to: [I]) {
        guard let conversations = to as? [ZMConversation] else {
            return
        }

        shareFile.invoke(
            fileMetadata: logFileMetadata,
            conversations: conversations
        )
    }

    func previewView() -> UIView? {
        let view = ShareableDebugReportView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = SemanticColors.View.backgroundUserCell
        view.configure(with: logFileMetadata)
        return view
    }

}

extension ShareableDebugReport: Equatable {
    static func == (lhs: ShareableDebugReport, rhs: ShareableDebugReport) -> Bool {
        lhs.logFileMetadata == rhs.logFileMetadata
    }
}
