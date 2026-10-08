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

import AppAuth
import Foundation

/// Wraps an `OIDExternalUserAgent` with callbacks fired around its presentation
/// lifecycle. `onPresented` runs after the wrapped agent has successfully presented
/// its UI; `onDismissed` runs after the wrapped agent's dismissal completes.
final class LifecycleAwareUserAgent: NSObject, OIDExternalUserAgent {

    private let wrapped: OIDExternalUserAgent
    private let onPresented: (@MainActor () -> Void)?
    private let onDismissed: (@MainActor () -> Void)?

    init(
        wrapping wrapped: OIDExternalUserAgent,
        onPresented: (@MainActor () -> Void)?,
        onDismissed: (@MainActor () -> Void)?
    ) {
        self.wrapped = wrapped
        self.onPresented = onPresented
        self.onDismissed = onDismissed
    }

    // `OIDExternalUserAgent` is an Obj-C protocol with no actor annotation, so Swift treats `present` and
    // `dismiss` as callable from any context.
    //
    // We can't annotate it `@MainActor`, but AppAuth always calls it on the main thread since it deals with UI.
    //
    // `assumeIsolated` is tells the compiler we're already on the main actor, so we can call the
    // `@MainActor`-bound `onPresented()` and `onDismiss()` closures synchronously.

    func present(
        _ request: any OIDExternalUserAgentRequest,
        session: any OIDExternalUserAgentSession
    ) -> Bool {
        let didPresent = wrapped.present(request, session: session)
        if didPresent, let onPresented {
            MainActor.assumeIsolated { onPresented() }
        }
        return didPresent
    }

    func dismiss(
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        wrapped.dismiss(animated: animated) { [weak self] in
            if let onDismissed = self?.onDismissed {
                MainActor.assumeIsolated { onDismissed() }
            }
            completion()
        }
    }
}
