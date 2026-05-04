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

extension MockWireMessagingFactoryProtocol {

    static func makeDefault() -> MockWireMessagingFactoryProtocol {
        let mock = MockWireMessagingFactoryProtocol()
        mock.makeClearPublishedDraftsUseCaseCellName_MockValue = WireDriveClearPublishedDraftsUseCaseProtocolMock()
        mock.makeDeleteDraftUseCaseCellName_MockValue = WireDriveDeleteDraftUseCaseProtocolMock()
        mock.makeObserveDraftsUseCaseCellName_MockValue = WireDriveObserveDraftsUseCaseProtocolMock()
        mock.makePublishDraftsUseCaseCellName_MockValue = WireDrivePublishDraftsUseCaseProtocolMock()
        mock.makeRetryUploadDraftUseCaseCellName_MockValue = WireDriveRetryUploadDraftUseCaseProtocolMock()
        mock.makeUploadDraftUseCaseCellName_MockValue = WireDriveUploadDraftUseCaseProtocolMock()
        mock.makeConversationCellProviderInsetsProvider_MockValue = MockConversationCellProviderProtocol()
        return mock
    }

}
