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

public import WireCellsAPI
import Foundation
import WireCellsImplementation

public struct WireCellsAssembly {

    // TODO: [WPB-17769] Somehow inject secrets without storing them in the code base
    private static let credentials = WireCellsCredentials(
        serverURL: URL(string: "https://service.zeta.pydiocells.com")!,
        accessToken: "some-access-token",
        gatewaySecret: "some-gateway-secret"
    )

    private static let nodesRepository = WireCellsNodesDataSource(credentials: credentials)

    private static let draftsRepository = DraftsRepository(
        uploadManager: WireCellsNodeUploadManager(repository: nodesRepository)
    )

    public init() {}

    public func makeUploadFileUseCase(cellName: String) -> any WireCellsUploadFileUseCaseProtocol {
        WireCellsUploadFileUseCase(cellName: cellName, draftRepository: Self.draftsRepository)
    }

    public func makeObserveDraftsUseCase(cellName: String) -> any WireCellsObserveDraftsUseCaseProtocol {
        ObserveDraftsUseCase(cellName: cellName, draftRepository: Self.draftsRepository)
    }

}
