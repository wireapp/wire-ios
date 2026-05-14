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

struct KMPViewModelEnvironment {

    let sessionBoundaryContext: SessionBoundaryContext
    let sessionBoundaryModeResolver: any SessionBoundaryModeResolving
    let viewModelFactory: any KMPViewModelFactory

    init(
        sessionBoundaryContext: SessionBoundaryContext,
        sessionBoundaryModeResolver: any SessionBoundaryModeResolving,
        viewModelFactory: any KMPViewModelFactory
    ) {
        self.sessionBoundaryContext = sessionBoundaryContext
        self.sessionBoundaryModeResolver = sessionBoundaryModeResolver
        self.viewModelFactory = viewModelFactory
    }

    @MainActor
    static func legacyOnly(
        sessionBoundaryContext: SessionBoundaryContext
    ) -> KMPViewModelEnvironment {
        KMPViewModelEnvironment(
            sessionBoundaryContext: sessionBoundaryContext,
            sessionBoundaryModeResolver: SessionBoundaryModeResolverFactory.makeDefaultResolver(),
            viewModelFactory: DefaultKMPViewModelFactory()
        )
    }

    var sessionBoundaryMode: SessionBoundaryMode {
        sessionBoundaryModeResolver.mode(for: sessionBoundaryContext)
    }

    @MainActor
    func makeViewModel<State, Effect, Intent>(
        for descriptor: KMPViewModelDescriptor<State, Effect, Intent>
    ) -> KMPViewModelAdapter<State, Effect, Intent> {
        viewModelFactory.makeViewModel(for: descriptor)
    }

    func usesKMPViewModel(
        for screenID: KMPViewModelScreenID,
        isKMPImplementationAvailable: Bool
    ) -> Bool {
        sessionBoundaryMode.usesKaliumViewModels && isKMPImplementationAvailable
    }
}

enum KMPViewModelScreenID: String, Equatable {
    case appLockChangeWarning
    case archivedList
    case blocker
    case changeEmail
    case changeHandle
    case connectRequests
    case confirmEmail
    case createGroupConversation
    case folderPicker
    case networkStatus
    case noConversationPlaceholder
    case permissionDenied
    case searchUser
    case sidebar
    case settingsAbout
    case settingsAccount
    case settingsAdvanced
    case settingsClientList
    case settingsDeveloper
    case settingsDevices
    case settingsOptions
    case settingsRoot
    case settingsSupport
    case selfClientList
    case selfProfile
    case startUI
    case successfulCertificateEnrollment
    case userStatus
    case wipeCompletion
}
