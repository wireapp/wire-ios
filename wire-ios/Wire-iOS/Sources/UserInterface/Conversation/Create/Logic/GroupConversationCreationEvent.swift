//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireDataModel

enum GroupConversationCreationEvent {
    enum FailureType {
        case missingLegalHoldConsent
        case nonFederatingBackends
        case other
    }
    enum PopupType {
        case missingLegalHoldConsent(completionHandler: () -> Void)
        case nonFederatingBackends(backends: NonFederatingBackendsTuple, actionHandler: (NonFullyConnectedGraphAction) -> Void)
    }
    case success(conversation: ZMConversation)
    case failure(failureType: FailureType)
    case hideLoader
    case showLoader
    case presentPopup(popupType: PopupType)
    case openURL(url: URL)
}
