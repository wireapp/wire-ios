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

import UIKit
import WireSyncEngine

extension UIAlertController {
    typealias DegradedCallLocale = L10n.Localizable.Call.Degraded

    static func makeOutgoingDegradedProteusCall(
        degradedUser: UserType?,
        callEnded: Bool = false,
        confirmationBlock: ((_ continueDegradedCall: Bool) -> Void)? = nil
    ) -> UIAlertController {
        typealias GeneralLocale = L10n.Localizable.General

        let title = degradedCallTitle(forCallEnded: callEnded)

        let message = degradedCallMessage(forUser: degradedUser, callEnded: callEnded)

        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if let confirmationBlock {
            controller.addAction(UIAlertAction(title: GeneralLocale.cancel, style: .cancel) { _ in
                confirmationBlock(false)
            })

            controller.addAction(UIAlertAction(title: DegradedCallLocale.Alert.Action.continue, style: .default) { _ in
                confirmationBlock(true)
            })
        } else {
            controller.addAction(UIAlertAction(title: GeneralLocale.ok, style: .default))
        }

        return controller
    }

    static func makeIncomingDegradedProteusCall(
        degradedUser: UserType?,
        callEnded: Bool = false,
        confirmationBlock: ((_ continueDegradedCall: Bool) -> Void)? = nil
    ) -> UIAlertController {
        let title = degradedCallTitle(forCallEnded: callEnded)
        let message = degradedCallMessage(forUser: degradedUser, callEnded: callEnded)

        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // Add actions
        if let confirmationBlock {
            controller.addAction(.cancel({
                confirmationBlock(false)
            }))

            controller.addAction(UIAlertAction(title: DegradedCallLocale.Incoming.Alert.Action.continue, style: .default) { _ in
                confirmationBlock(true)
            })
        } else {
            controller.addAction(UIAlertAction(title: L10n.Localizable.General.ok, style: .default))
        }

        return controller
    }

    static func makeOutgoingDegradedMLSCall(
        confirmationBlock: ((_ continueDegradedCall: Bool) -> Void)? = nil,
        cancelBlock: (() -> Void)? = nil) -> UIAlertController {
        typealias DegradedCall = L10n.Localizable.Call.Mls.Degraded.Alert

        let title = DegradedCall.title
        let message = DegradedCall.message
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // Add actions
        if let confirmationBlock {
            controller.addAction(UIAlertAction(title: DegradedCall.Action.continue, style: .default) { _ in
                confirmationBlock(true)
            })

            controller.addAction(.cancel(cancelBlock))
        } else {
            controller.addAction(UIAlertAction(
                title: L10n.Localizable.General.ok,
                style: .default,
                handler: { _ in
                    cancelBlock?()
                }
            ))
        }

        return controller
    }

    static func makeEndingDegradedMLSCall(
        confirmationBlock: ((_ continueDegradedCall: Bool) -> Void)? = nil,
        cancelBlock: (() -> Void)? = nil) -> UIAlertController {
        typealias DegradedCall = L10n.Localizable.Call.Mls.Degraded.Alert
        typealias EndedCall = L10n.Localizable.Call.Mls.Degraded.Ended.Alert

        let title = DegradedCall.title
        let message = EndedCall.message
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // Add actions
        if let confirmationBlock {
            controller.addAction(UIAlertAction(title: DegradedCall.Action.continue, style: .default) { _ in
                confirmationBlock(true)
            })

            controller.addAction(.cancel(cancelBlock))
        } else {
            controller.addAction(UIAlertAction(
                title: L10n.Localizable.General.ok,
                style: .default,
                handler: { _ in
                    cancelBlock?()
                }
            ))
        }

        return controller
    }

    static func makeIncomingDegradedMLSCall(
        confirmationBlock: @escaping (_ answerDegradedCall: Bool) -> Void
    ) -> UIAlertController {
        typealias DegradedCall = L10n.Localizable.Call.Mls.Degraded.Alert
        typealias IncomingCall = L10n.Localizable.Call.Mls.Degraded.Incoming.Alert

        let controller = UIAlertController(title: DegradedCall.title,
                                           message: IncomingCall.message,
                                           preferredStyle: .alert)

        // Add actions

        controller.addAction(UIAlertAction(title: IncomingCall.Action.continue, style: .default) { _ in
            confirmationBlock(true)
        })

        controller.addAction(.cancel({
            confirmationBlock(false)
        }))

        return controller
    }

    // MARK: - Private

    private static func degradedCallTitle(forCallEnded callEnded: Bool) -> String {
        return callEnded ? DegradedCallLocale.Ended.Alert.title : DegradedCallLocale.Alert.title
    }

    private static func degradedCallMessage(forUser degradedUser: UserType?, callEnded: Bool) -> String {
        if let user = degradedUser {
            if callEnded {
                return user.isSelfUser ?
                    DegradedCallLocale.Ended.Alert.Message.`self` :
                    DegradedCallLocale.Ended.Alert.Message.user(user.name ?? "")
            } else {
                return user.isSelfUser ?
                    DegradedCallLocale.Alert.Message.`self` :
                    DegradedCallLocale.Alert.Message.user(user.name ?? "")
            }
        } else {
            return callEnded ?
                DegradedCallLocale.Ended.Alert.Message.unknown :
                DegradedCallLocale.Alert.Message.unknown
        }
    }
}
