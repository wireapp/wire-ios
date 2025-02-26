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

import Combine
import Foundation
import SwiftUI
import WireAuthenticationAPI

@MainActor
public final class RootViewModel: ObservableObject, Router {

    @Published var path = NavigationPath()
    @Published var modalDestination: RootView.ModalDestination? = .authFlow
    @Published var showSSOFailureAlert: Bool = false

    public init() {}

    public func popToRoot() {
        path.removeLast(path.count)
    }

    public func navigate(to destination: some Hashable) {
        path.append(destination)
    }

    public func presentSheet(_ modalDestination: some Hashable) {
        self.modalDestination = modalDestination as? RootView.ModalDestination
    }

}
