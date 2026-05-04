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
import WireDataModel
import WireSyncEngine
import WireSystem

public final class AutomationEmailCredentials: NSObject {
    public var email: String
    public var password: String
    init(email: String, password: String) {
        self.email = email
        self.password = password
        super.init()
    }
}

/// This class is used to retrieve specific arguments passed on the
/// command line when running automation tests.
/// These values typically do not need to be stored in `Settings`.
public final class AutomationHelper: NSObject {
    public static let sharedHelper = AutomationHelper()
    /// Whether analytics should be used
    public var useAnalytics: Bool {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: get it from xcconfig?
        // return UserDefaults.standard.bool(forKey: "UseAnalytics")
        true
    }

    /// Whether to skip the first login alert
    public var skipFirstLoginAlerts: Bool {
        automationEmailCredentials != nil
    }

    var backendType: String?

    /// The login credentials provides by command line
    public let automationEmailCredentials: AutomationEmailCredentials?
    /// Whether we push notification permissions alert is disabled
    public let disablePushNotificationAlert: Bool
    /// Whether autocorrection is disabled
    public let disableAutocorrection: Bool
    /// Whether we should disable the call quality survey.
    public let disableCallQualitySurvey: Bool
    /// Whether we should disable dismissing the conversation input bar keyboard by dragging it downwards.
    public let disableInteractiveKeyboardDismissal: Bool
    /// Debug data to install in the share container
    let debugDataToInstall: URL?

    /// The name of the arguments file in the /tmp directory
    private let fileArgumentsName = "wire_arguments.txt"

    /// Whether the backend environment type should be persisted as a setting.
    let shouldPersistBackendType: Bool

    /// Whether the calling overlay should disappear automatically.
    public let keepCallingOverlayVisible: Bool

    public let developerFlagArguments: [String]

    public private(set) var preferredAPIVersion: APIVersion?
    public private(set) var allowMLSGroupCreation: Bool?

    override init() {
        let url = URL(string: NSTemporaryDirectory())?.appendingPathComponent(fileArgumentsName)
        let arguments: ArgumentsType = url.flatMap(FileArguments.init) ?? CommandLineArguments()

        self.disablePushNotificationAlert = arguments.hasFlag(AutomationKey.disablePushNotificationAlert)
        self.disableAutocorrection = arguments.hasFlag(AutomationKey.disableAutocorrection)
        self.disableCallQualitySurvey = arguments.hasFlag(AutomationKey.disableCallQualitySurvey)
        self.shouldPersistBackendType = arguments.hasFlag(AutomationKey.persistBackendType)
        self.disableInteractiveKeyboardDismissal = arguments.hasFlag(AutomationKey.disableInteractiveKeyboardDismissal)
        self.keepCallingOverlayVisible = arguments.hasFlag(AutomationKey.keepCallingOverlayVisible)

        self.automationEmailCredentials = AutomationHelper.credentials(arguments)
        if arguments.hasFlag(AutomationKey.logNetwork) {
            ZMSLog.set(level: .debug, tag: "Network")
        }
        if arguments.hasFlag(AutomationKey.logCalling) {
            ZMSLog.set(level: .debug, tag: "calling")
        }
        AutomationHelper.enableLogTags(arguments)
        if let debugDataPath = arguments.flagValueIfPresent(AutomationKey.debugDataToInstall.rawValue),
           FileManager.default.fileExists(atPath: debugDataPath) {
            self.debugDataToInstall = URL(fileURLWithPath: debugDataPath)
        } else {
            self.debugDataToInstall = nil
        }

        if let value = arguments.flagValueIfPresent(AutomationKey.preferredAPIVersion.rawValue),
           let apiVersion = Int32(value) {
            self.preferredAPIVersion = APIVersion(rawValue: apiVersion)
        }

        if let backendType = arguments.flagValueIfPresent(AutomationKey.backendType.rawValue) {
            self.backendType = backendType
        }

        if let flags = arguments.flagValueIfPresent(AutomationKey.developerFlag.rawValue) {
            self.developerFlagArguments = flags.split(separator: " ").map { "\($0)" }
        } else {
            self.developerFlagArguments = []
        }

        self.allowMLSGroupCreation = arguments.hasFlag(AutomationKey.allowMLSGroupCreation.rawValue)

        super.init()
        persistBackendTypeOverrideIfNeeded(with: backendType)
    }

    private enum AutomationKey: String {
        case email = "loginemail"
        case password = "loginpassword"
        case logNetwork = "debug-log-network"
        case logCalling = "debug-log-calling"
        case logTags = "debug-log"
        case disablePushNotificationAlert = "disable-push-alert"
        case disableAutocorrection = "disable-autocorrection"
        case debugDataToInstall = "debug-data-to-install"
        case disableCallQualitySurvey = "disable-call-quality-survey"
        case persistBackendType = "persist-backend-type"
        case backendType = "BackendEnvironmentTypeOverrideKey"
        case disableInteractiveKeyboardDismissal = "disable-interactive-keyboard-dismissal"
        case keepCallingOverlayVisible = "keep-calling-overlay-visible"
        case preferredAPIVersion = "preferred-api-version"
        case allowMLSGroupCreation = "allow-mls-group-creation"
        case deprecatedCallingUI = "deprecated-calling-ui"
        case developerFlag = "developer-flag"
    }

    /// Returns the login email and password credentials if set in the given arguments
    private static func credentials(_ arguments: ArgumentsType) -> AutomationEmailCredentials? {
        guard let email = arguments.flagValueIfPresent(AutomationKey.email.rawValue),
              let password = arguments.flagValueIfPresent(AutomationKey.password.rawValue) else {
            return nil
        }
        return AutomationEmailCredentials(email: email, password: password)
    }

    // Switches on all flags that you would like to log listed after `--debug-log=` tags should be separated by comma
    private static func enableLogTags(_ arguments: ArgumentsType) {
        guard let tagsString = arguments.flagValueIfPresent(AutomationKey.logTags.rawValue) else { return }
        let tags = tagsString.components(separatedBy: ",")
        tags.forEach { ZMSLog.set(level: .debug, tag: $0) }
    }
}

// MARK: - Helpers

protocol ArgumentsType {

    var flagPrefix: String { get }

    /// Argument strings
    var arguments: Set<String> { get }

    /// Returns whether the flag is set
    func hasFlag(_ name: String) -> Bool

    /// Returns the value of a flag, if present
    func flagValueIfPresent(_ commandLineArgument: String) -> String?
}

// MARK: - default implementation

extension ArgumentsType {

    var flagPrefix: String { "--" }

    func hasFlag(_ name: String) -> Bool {
        arguments.contains(flagPrefix + name)
    }

    func hasFlag<Flag: RawRepresentable>(_ flag: Flag) -> Bool where Flag.RawValue == String {
        hasFlag(flag.rawValue)
    }

    func flagValueIfPresent(_ commandLineArgument: String) -> String? {
        for argument in arguments {
            let searchString = flagPrefix + commandLineArgument + "="
            if argument.hasPrefix(searchString) {
                return String(argument[searchString.index(searchString.startIndex, offsetBy: searchString.count)...])
            }
        }
        return nil
    }
}

/// Command line arguments
private struct CommandLineArguments: ArgumentsType {

    let arguments: Set<String>

    init() {
        self.arguments = Set(ProcessInfo.processInfo.arguments)
    }
}

/// Arguments read from a file on disk
private struct FileArguments: ArgumentsType {

    let arguments: Set<String>

    init?(url: URL) {
        guard let argumentsString = try? String(contentsOfFile: url.path, encoding: .utf8) else { return nil }
        self.arguments = Set(argumentsString.components(separatedBy: .whitespaces))
    }
}

// MARK: - Debug

public extension AutomationHelper {
    /// Takes all files in the folder pointed at by `debugDataToInstall` and installs them
    /// in the shared folder, erasing any other file in that folder.
    func installDebugDataIfNeeded() {
        guard let packageURL = debugDataToInstall,
              let appGroupIdentifier = Bundle.main.applicationGroupIdentifier else { return }
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupIdentifier)
        // DELETE
        let filesToDelete = try! FileManager.default.contentsOfDirectory(atPath: sharedContainerURL.path)
        filesToDelete.forEach {
            try! FileManager.default.removeItem(atPath: sharedContainerURL.appendingPathComponent($0).path)
        }
        // COPY
        try! FileManager.default.copyFolderRecursively(
            from: packageURL,
            to: sharedContainerURL,
            overwriteExistingFiles: true
        )
    }
}
