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

@MainActor
protocol KMPNavigationEffectDispatching {
    associatedtype NavigationEffect

    func dispatch(_ effect: NavigationEffect)
}

@MainActor
struct AnyKMPNavigationEffectDispatcher<NavigationEffect>: KMPNavigationEffectDispatching {

    private let dispatchEffect: (NavigationEffect) -> Void

    init<Dispatcher: KMPNavigationEffectDispatching>(
        _ dispatcher: Dispatcher
    ) where Dispatcher.NavigationEffect == NavigationEffect {
        self.dispatchEffect = { dispatcher.dispatch($0) }
    }

    init(dispatch: @escaping (NavigationEffect) -> Void) {
        self.dispatchEffect = dispatch
    }

    func dispatch(_ effect: NavigationEffect) {
        dispatchEffect(effect)
    }
}
