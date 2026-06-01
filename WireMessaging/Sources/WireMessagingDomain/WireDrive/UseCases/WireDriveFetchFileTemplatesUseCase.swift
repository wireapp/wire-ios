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

/// Fetches templates useable for document creation (.docx, .pptx, .xlsx. etc)
package struct WireDriveFetchFileTemplatesUseCase: WireDriveFetchFileTemplatesUseCaseProtocol {

    private let repository: any WireDriveNodesRepositoryProtocol

    package init(
        repository: any WireDriveNodesRepositoryProtocol,
    ) {
        self.repository = repository
    }

    package func invoke() async throws -> [WireDriveFileTemplate] {
        // TODO: [WPB-22926] Replace hard coded values with server values when GET/ templates endpoint ready.
        // Do `try await repository.getTemplates()`
        [
            .init(
                kind: .document,
                editable: true,
                label: "Microsoft Word",
                id: "01-Microsoft Word.docx"
            ),
            .init(
                kind: .spreadsheet,
                editable: true,
                label: "Microsoft Excel",
                id: "02-Microsoft Excel.xlsx"
            ),
            .init(
                kind: .presentation,
                editable: true,
                label: "Microsoft PowerPoint",
                id: "03-Microsoft PowerPoint.pptx"
            )
        ]
    }

}
