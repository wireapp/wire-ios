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

@testable import Wire

// MARK: - ActiveCallRouterMock
class ActiveCallRouterProtocolMock: ActiveCallRouterProtocol {

    var presentActiveCallIsCalled: Bool = false
    func presentActiveCall(for voiceChannel: VoiceChannel, animated: Bool) {
        presentActiveCallIsCalled = true
    }

    var dismissActiveCallIsCalled: Bool = false
    func dismissActiveCall(animated: Bool, completion: Completion?) {
        dismissActiveCallIsCalled = true
        hideCallTopOverlay()
    }

    var minimizeCallIsCalled: Bool = false
    func minimizeCall(animated: Bool, completion: (() -> Void)?) {
        minimizeCallIsCalled = true
    }

    var showCallTopOverlayIsCalled: Bool = false
    func showCallTopOverlay(for conversation: ZMConversation) {
        showCallTopOverlayIsCalled = true
    }

    var hideCallTopOverlayIsCalled: Bool = false
    func hideCallTopOverlay() {
        hideCallTopOverlayIsCalled = true
    }

    var presentSecurityDegradedAlertIsCalled: Bool = false
    func presentSecurityDegradedAlert(degradedUser: UserType?) {
        presentSecurityDegradedAlertIsCalled = true
    }

    var presentUnsupportedVersionAlertIsCalled: Bool = false
    func presentUnsupportedVersionAlert() {
        presentUnsupportedVersionAlertIsCalled = true
    }
}
