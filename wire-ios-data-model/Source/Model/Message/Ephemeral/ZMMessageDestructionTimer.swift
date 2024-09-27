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

import Foundation

let MessageDeletionTimerKey = "MessageDeletionTimer"
let MessageObfuscationTimerKey = "MessageObfuscationTimer"
private let log = ZMSLog(tag: "ephemeral")

extension NSManagedObjectContext {
    @objc public var zm_messageDeletionTimer: ZMMessageDestructionTimer? {
        precondition(zm_isUserInterfaceContext, "MessageDeletionTimerKey should be started only on the uiContext")

        return userInfo[MessageDeletionTimerKey] as? ZMMessageDestructionTimer
    }

    @objc public var zm_messageObfuscationTimer: ZMMessageDestructionTimer? {
        precondition(zm_isSyncContext, "MessageObfuscationTimer should be started only on the syncContext")

        return userInfo[MessageObfuscationTimerKey] as? ZMMessageDestructionTimer
    }

    @objc
    public func zm_createMessageObfuscationTimer() {
        precondition(zm_isSyncContext, "MessageObfuscationTimer should be started only on the syncContext")

        guard userInfo[MessageObfuscationTimerKey] == nil else {
            log.debug("Obfuscation timer already exists, skipping")
            return
        }

        userInfo[MessageObfuscationTimerKey] = ZMMessageDestructionTimer(managedObjectContext: self)
        log.debug("creating obfuscation timer")
    }

    @objc
    public func zm_createMessageDeletionTimer() {
        precondition(zm_isUserInterfaceContext, "MessageDeletionTimer should be started only on the uiContext")

        guard userInfo[MessageDeletionTimerKey] == nil else {
            log.debug("Deletion timer already exists, skipping")
            return
        }

        userInfo[MessageDeletionTimerKey] = ZMMessageDestructionTimer(managedObjectContext: self)
        log.debug("creating deletion timer")
    }

    /// Tears down zm_messageObfuscationTimer and zm_messageDeletionTimer
    /// Call inside a performGroupedBlock(AndWait) when calling it from another context
    @objc
    public func zm_teardownMessageObfuscationTimer() {
        precondition(zm_isSyncContext, "MessageObfuscationTimer is located on the syncContext")
        if let timer = userInfo[MessageObfuscationTimerKey] as? ZMMessageDestructionTimer {
            timer.tearDown()
            userInfo.removeObject(forKey: MessageObfuscationTimerKey)
            log.debug("tearing down obfuscation timer")
        }
    }

    /// Tears down zm_messageDeletionTimer
    /// Call inside a performGroupedBlock(AndWait) when calling it from another context
    @objc
    public func zm_teardownMessageDeletionTimer() {
        precondition(zm_isUserInterfaceContext, "MessageDeletionTimerKey is located on the uiContext")
        if let timer = userInfo[MessageDeletionTimerKey] as? ZMMessageDestructionTimer {
            timer.tearDown()
            userInfo.removeObject(forKey: MessageDeletionTimerKey)
            log.debug("tearing down deletion timer")
        }
    }
}

// MARK: - MessageDestructionType

enum MessageDestructionType: String {
    case obfuscation, deletion

    // MARK: Internal

    static let UserInfoKey = "destructionType"
}

// MARK: - ZMMessageDestructionTimer

@objcMembers
public class ZMMessageDestructionTimer: ZMMessageTimer {
    // MARK: Lifecycle

    override init(managedObjectContext: NSManagedObjectContext!) {
        super.init(managedObjectContext: managedObjectContext)
        timerCompletionBlock = { [weak self] message, userInfo in
            guard let self, let message, !message.isZombieObject else {
                return log.debug("not forwarding timer, nil message or zombie")
            }

            messageTimerDidFire(message: message, userInfo: userInfo)
        }
    }

    // MARK: Public

    public func startObfuscationTimer(message: ZMMessage, timeout: TimeInterval) {
        let fireDate = Date().addingTimeInterval(timeout)
        let started = startTimerIfNeeded(
            for: message,
            fireDate: fireDate,
            userInfo: [
                MessageDestructionType.UserInfoKey: MessageDestructionType
                    .obfuscation.rawValue,
            ]
        )
        if started {
            log.debug("starting obfuscation timer for \(message.nonce?.transportString() ?? "") timeout in \(timeout)")
        }
    }

    public func startDeletionTimer(message: ZMMessage, timeout: TimeInterval) -> TimeInterval {
        let fireDate = Date().addingTimeInterval(timeout)
        let started = startTimerIfNeeded(
            for: message,
            fireDate: fireDate,
            userInfo: [
                MessageDestructionType.UserInfoKey: MessageDestructionType.deletion
                    .rawValue,
            ]
        )
        if started {
            log.debug("starting deletion timer for \(message.nonce?.transportString() ?? "") timeout in \(timeout)")
        }

        return timeout
    }

    // MARK: Internal

    var isTesting = false

    func messageTimerDidFire(message: ZMMessage, userInfo: [AnyHashable: Any]?) {
        guard let userInfo = userInfo as? [String: Any],
              let type = userInfo[MessageDestructionType.UserInfoKey] as? String
        else {
            return
        }

        log.debug("message timer did fire for \(message.nonce?.transportString() ?? ""), \(type)")
        switch MessageDestructionType(rawValue: type) {
        case .some(.obfuscation):
            message.obfuscate()
        case .some(.deletion):
            message.deleteEphemeral()
        default:
            return
        }
        moc.saveOrRollback()
    }
}
