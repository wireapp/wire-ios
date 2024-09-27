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
import WireCryptobox

extension ZMUserSession {
    /// Parses and execute a debug command, which is expected to be
    /// tokenized already (e.g. "print", "foobar")
    public func executeDebugCommand(
        _ command: [String],
        onComplete: @escaping (DebugCommandResult) -> Void
    ) {
        guard let keyword = command.first else {
            onComplete(.unknownCommand)
            return
        }

        let arguments = Array(command.dropFirst())

        guard let command = debugCommands[keyword] else {
            onComplete(.unknownCommand)
            return
        }

        let state = savedDebugState[keyword] ?? [:]
        command.execute(
            arguments: arguments,
            userSession: self,
            state: state,
            onComplete: onComplete
        )
    }

    static func initDebugCommands() -> [String: DebugCommand] {
        let commands = [
            DebugCommandLogEncryption(),
            DebugCommandShowIdentifiers(),
            DebugCommandHelp(),
            DebugCommandVariables(),
        ]
        return commands.reduce(into: [:]) { partialResult, command in
            partialResult[command.keyword] = command
        }
    }

    func restoreDebugCommandsState() {
        for value in debugCommands.values {
            let state = savedDebugState[value.keyword] ?? [:]
            value.restoreFromState(userSession: self, state: state)
        }
    }

    private var debugStateUserDefaultsKey: String? {
        guard
            let identifier = (providedSelfUser as! ZMUser).remoteIdentifier
        else {
            return nil
        }
        return "Wire-debugCommandsState-\(identifier)"
    }

    /// The debug state persisted for this user
    fileprivate var savedDebugState: [String: [String: Any]] {
        get {
            guard let key = debugStateUserDefaultsKey else {
                return [:]
            }
            return UserDefaults.shared()?
                .dictionary(forKey: key) as? [String: [String: Any]] ?? [:]
        }
        set {
            guard let key = debugStateUserDefaultsKey else {
                return
            }
            UserDefaults.shared()?.set(newValue, forKey: key)
        }
    }
}

// MARK: - DebugCommand

/// A debug command that can be invoked with arguments
protocol DebugCommand {
    /// This is the keyword used to invoke the command
    var keyword: String { get }

    /// This will be called to execute the command
    func execute(
        arguments: [String],
        userSession: ZMUserSession,
        state: [String: Any],
        onComplete: @escaping ((DebugCommandResult) -> Void)
    )

    /// Restore any state from the persistent state, e.g. re-enable logging
    /// of a certain kind based on whether it was enabled before.
    /// This is called once in the lifetime of a DebugCommand.
    func restoreFromState(userSession: ZMUserSession, state: [String: Any])
}

extension DebugCommand {
    /// Save any "state" that needs to be persisted. The state should
    /// only contain types can serialized in user defaults.
    func saveState(userSession: ZMUserSession, state: [String: Any]) {
        userSession.savedDebugState[keyword] = state
    }
}

// MARK: - DebugCommandMixin

/// This is a mixin (implementation of a protocol that can be
/// inherited to avoid having to rewrite all protocol methods and vars)
private class DebugCommandMixin: DebugCommand {
    // MARK: Lifecycle

    init(keyword: String) {
        self.keyword = keyword
    }

    // MARK: Internal

    let keyword: String

    func execute(
        arguments: [String],
        userSession: ZMUserSession,
        state: [String: Any],
        onComplete: @escaping ((DebugCommandResult) -> Void)
    ) {
        onComplete(.failure(error: "Not implemented"))
    }

    func restoreFromState(userSession: ZMUserSession, state: [String: Any]) {}
}

// MARK: - DebugCommandResult

/// The result of a debug command
public enum DebugCommandResult {
    /// The command was a success. There is a string to show to the user
    case success(info: String?)
    /// The command was a success. There is a file to show to the user
    case successWithFile(file: NSURL)
    /// The command failed
    case failure(error: String?)
    /// The command was not recognized
    case unknownCommand
}

// MARK: - Command execution

extension EncryptionSessionIdentifier {
    fileprivate init?(string: String) {
        let split = string.split(separator: "_")
        guard split.count == 2 else {
            return nil
        }
        let user = String(split[0])
        let client = String(split[1])
        self.init(userId: user, clientId: client)
    }
}

// MARK: - DebugCommandLogEncryption

private class DebugCommandLogEncryption: DebugCommandMixin {
    // MARK: Lifecycle

    init() {
        super.init(keyword: "logEncryption")
    }

    // MARK: Internal

    var currentlyEnabledLogs: Set<EncryptionSessionIdentifier> = Set()

    override func execute(
        arguments: [String],
        userSession: ZMUserSession,
        state: [String: Any],
        onComplete: @escaping ((DebugCommandResult) -> Void)
    ) {
        defer {
            saveEnabledLogs(userSession: userSession)
        }

        if arguments.first == "list" {
            return onComplete(.success(
                info:
                "Enabled:\n" +
                    currentlyEnabledLogs
                    .map(\.rawValue)
                    .joined(separator: "\n")
            ))
        }

        guard arguments.count == 2,
              arguments[0] == "add" || arguments[0] == "remove"
        else {
            return onComplete(.failure(error: "usage: \(usage)"))
        }

        let isAdding = arguments[0] == "add"
        let subject = arguments[1]

        userSession.syncManagedObjectContext.perform {
            // swiftlint:disable:next todo_requires_jira_link
            // TODO: [John] use flag here
            guard let keyStore = userSession.syncManagedObjectContext.zm_cryptKeyStore else {
                return onComplete(.failure(error: "No encryption context"))
            }

            if !isAdding, subject == "all" {
                keyStore.encryptionContext.disableExtendedLoggingOnAllSessions()
                self.currentlyEnabledLogs = Set()
                return onComplete(.success(info: "all removed"))
            }

            guard let identifier = EncryptionSessionIdentifier(string: subject) else {
                return onComplete(.failure(error: "Invalid id \(subject)"))
            }

            if isAdding {
                self.currentlyEnabledLogs.insert(identifier)
            } else {
                self.currentlyEnabledLogs.remove(identifier)
            }

            keyStore.encryptionContext.setExtendedLogging(identifier: identifier, enabled: isAdding)
            return onComplete(.success(info: "Added logging for identifier \(identifier)"))
        }
    }

    override func restoreFromState(
        userSession: ZMUserSession,
        state: [String: Any]
    ) {
        guard let logs = state[logsKey] as? [String] else {
            return
        }
        currentlyEnabledLogs = Set(logs.compactMap {
            EncryptionSessionIdentifier(string: $0)
        })
        userSession.syncManagedObjectContext.performGroupedBlock {
            guard let keyStore = userSession.syncManagedObjectContext.zm_cryptKeyStore else {
                return
            }

            for currentlyEnabledLog in self.currentlyEnabledLogs {
                keyStore.encryptionContext.setExtendedLogging(identifier: currentlyEnabledLog, enabled: true)
            }
        }
    }

    // MARK: Private

    private let logsKey = "enabledLogs"

    private var usage: String {
        "\(keyword) <add|remove|list> <sessionId|all>"
    }

    private func saveEnabledLogs(userSession: ZMUserSession) {
        let idsToSave = currentlyEnabledLogs.map(\.rawValue)
        saveState(userSession: userSession, state: [logsKey: idsToSave])
    }
}

// MARK: - DebugCommandShowIdentifiers

/// Show the user and client identifier
private class DebugCommandShowIdentifiers: DebugCommandMixin {
    // MARK: Lifecycle

    init() {
        super.init(keyword: "showIdentifier")
    }

    // MARK: Internal

    override func execute(
        arguments: [String],
        userSession: ZMUserSession,
        state: [String: Any],
        onComplete: @escaping ((DebugCommandResult) -> Void)
    ) {
        guard
            let client = userSession.selfUserClient,
            let user = userSession.providedSelfUser as? ZMUser
        else {
            onComplete(.failure(error: "No user"))
            return
        }

        onComplete(.success(
            info:
            "User: \(user.remoteIdentifier.uuidString)\n" +
                "Client: \(client.remoteIdentifier ?? "-")\n" +
                "Session: \(client.sessionIdentifier?.rawValue ?? "-")"
        ))
    }
}

// MARK: - DebugCommandHelp

/// Show commands
private class DebugCommandHelp: DebugCommandMixin {
    // MARK: Lifecycle

    init() {
        super.init(keyword: "help")
    }

    // MARK: Internal

    override func execute(
        arguments: [String],
        userSession: ZMUserSession,
        state: [String: Any],
        onComplete: @escaping ((DebugCommandResult) -> Void)
    ) {
        let output = userSession.debugCommands.keys.sorted().joined(separator: "\n")
        onComplete(.success(info: output))
    }
}

// MARK: - DebugCommandVariables

/// Debug variables
private class DebugCommandVariables: DebugCommandMixin {
    // MARK: Lifecycle

    init() {
        super.init(keyword: "variables")
    }

    // MARK: Internal

    override func execute(
        arguments: [String],
        userSession: ZMUserSession,
        state: [String: Any],
        onComplete: @escaping ((DebugCommandResult) -> Void)
    ) {
        var newState = state
        switch arguments.first {
        case "list":
            return onComplete(.success(info: state.map { v in
                "\(v.key) => \(v.value)"
            }.joined(separator: "\n")))

        case "set":
            guard arguments.count == 2 || arguments.count == 3 else {
                return onComplete(.failure(error: "Usage: set <name> [<value>]"))
            }
            let key = arguments[1]
            let value = arguments.count == 3 ? arguments[2] : nil
            if let value {
                newState[key] = value
            } else {
                newState.removeValue(forKey: key)
            }
            saveState(userSession: userSession, state: state)
            return onComplete(.success(info: nil))

        case "get":
            guard arguments.count == 2 else {
                return onComplete(.failure(error: "Usage: get <name>"))
            }
            return onComplete(
                .success(info: String(describing: state[arguments[1]]))
            )

        default:
            return onComplete(.unknownCommand)
        }
    }
}
