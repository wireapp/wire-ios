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

import SwiftUI
import WireAuthenticationAPI

// Ideally we are using Swift packages (instead of Xcode projects),
// which would allow us to use the `package` access modifier instead
// of `public`. This means that `RootView` would be accesible to the
// assembly but not outside of the assembly.

public protocol LandingBuilder {

    @MainActor
    var landingView: LandingView { get }

}

public struct RootView: View {

    @ObservedObject
    var router: Router

    let builder: LandingBuilder

    // so... views are called here... which means we need all components?
    // is navigation is always deterministic...
    // root to landing
    // landing to login
    // so here we need the root component.

    public init(
        router: Router,
        builder: LandingBuilder
    ) {
        self.router = router
        self.builder = builder
    }

    public var body: some View {
        NavigationStack(path: $router.path) {
            builder.landingView
        }
    }

}

#Preview {
    let dependencies = MockDependencies()
    return RootView(
        router: dependencies.router,
        builder: dependencies
    )
}
