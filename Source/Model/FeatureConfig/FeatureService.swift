//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

/// This class facilitates storage and retrieval of feature configs to and from
/// the database.
///
/// Each `Feature` may have a different structure for its configuration, so a json
/// encoded form is what is stored in the database. Use this class to fetch a specific
/// feature as a type that contains a decoded configuration.
///
/// **Note:** fetching features can occur on any context, but updates should only
/// take place on the sync context.

public class FeatureService {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Life cycle

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Accessors

    public func fetchAppLock() -> Feature.AppLock {
        var result: Feature.AppLock!

        context.performGroupedAndWait {
            let feature = Feature.fetch(name: .appLock, context: $0)!
            let config = try! JSONDecoder().decode(Feature.AppLock.Config.self, from: feature.config!)
            result = .init(status: feature.status, config: config)
        }

        return result
    }

    public func storeAppLock(_ appLock: Feature.AppLock) {
        let config = try! JSONEncoder().encode(appLock.config)

        Feature.updateOrCreate(havingName: .appLock, in: context) {
            $0.status = appLock.status
            $0.config = config
        }
    }

    public func fetchConferenceCalling() -> Feature.ConferenceCalling {
        var result: Feature.ConferenceCalling!

        context.performGroupedAndWait {
            let feature = Feature.fetch(name: .conferenceCalling, context: $0)!
            result = .init(status: feature.status)
        }

        return result
    }

    public func storeConferenceCalling(_ conferenceCalling: Feature.ConferenceCalling) {
        Feature.updateOrCreate(havingName: .conferenceCalling, in: context) {
            $0.status = conferenceCalling.status
        }

        guard
            needsToNotifyUser(for: .conferenceCalling),
            conferenceCalling.status == .enabled
        else {
            return
        }

        notifyChange(.conferenceCallingIsAvailable)
    }

    public func fetchFileSharing() -> Feature.FileSharing {
        var result: Feature.FileSharing!

        context.performGroupedAndWait {
            let feature = Feature.fetch(name: .fileSharing, context: $0)!
            result = .init(status: feature.status)
        }

        return result
    }

    public func storeFileSharing(_ fileSharing: Feature.FileSharing) {
        Feature.updateOrCreate(havingName: .fileSharing, in: context) {
            $0.status = fileSharing.status
        }

        guard needsToNotifyUser(for: .fileSharing) else { return }

        switch fileSharing.status {
        case .disabled:
            notifyChange(.fileSharingDisabled)

        case .enabled:
            notifyChange(.fileSharingEnabled)
        }
    }

    public func fetchSelfDeletingMesssages() -> Feature.SelfDeletingMessages {
        let feature = Feature.fetch(name: .selfDeletingMessages, context: context)!
        let config = try! JSONDecoder().decode(Feature.SelfDeletingMessages.Config.self, from: feature.config!)
        return .init(status: feature.status, config: config)
    }

    public func storeSelfDeletingMessages(_ selfDeletingMessages: Feature.SelfDeletingMessages) {
        let config = try! JSONEncoder().encode(selfDeletingMessages.config)

        Feature.updateOrCreate(havingName: .selfDeletingMessages, in: context) {
            $0.status = selfDeletingMessages.status
            $0.config = config
        }

        guard needsToNotifyUser(for: .selfDeletingMessages) else { return }

        switch (selfDeletingMessages.status, selfDeletingMessages.config.enforcedTimeoutSeconds) {
        case (.disabled, _):
            notifyChange(.selfDeletingMessagesIsDisabled)

        case (.enabled, let enforcedTimeout) where enforcedTimeout > 0:
            notifyChange(.selfDeletingMessagesIsEnabled(enforcedTimeout: enforcedTimeout))

        case (.enabled, _):
            notifyChange(.selfDeletingMessagesIsEnabled(enforcedTimeout: nil))
        }
    }

    // MARK: - Helpers

    func createDefaultConfigsIfNeeded() {
        for name in Feature.Name.allCases where Feature.fetch(name: name, context: context) == nil {
            switch name {
            case .appLock:
                storeAppLock(.init())

            case .conferenceCalling:
                storeConferenceCalling(.init())
                
            case .fileSharing:
                storeFileSharing(.init())

            case .selfDeletingMessages:
                storeSelfDeletingMessages(.init())
            }
        }
    }

    /// Marks the feature as needing to be updated from the backend, which will be
    /// picked up by the sync strategy.
    ///
    /// - Parameters:
    ///     - featureName: the feature to refresh.

    public func enqueueBackendRefresh(for featureName: Feature.Name) {
        context.perform {
            let feature = Feature.fetch(name: featureName, context: self.context)
            feature?.needsToBeUpdatedFromBackend = true
        }
    }

    func needsToNotifyUser(for featureName: Feature.Name) -> Bool {
        var result = false

        context.performGroupedAndWait {
            let feature = Feature.fetch(name: featureName, context: $0)
            result = feature?.needsToNotifyUser ?? false
        }

        return result
    }

    public func setNeedsToNotifyUser(_ notifyUser: Bool, for featureName: Feature.Name) {
        context.performGroupedAndWait {
            let feature = Feature.fetch(name: featureName, context: $0)
            feature?.needsToNotifyUser = notifyUser
        }
    }

    private func notifyChange(_ change: FeatureChange) {
        NotificationCenter.default.post(name: .featureDidChangeNotification, object: change)
    }

}

extension FeatureService {

    /// A type that represents the possible changes to feature configs.
    ///
    /// These can be used by the ui layer to determine what kind of alert
    /// it needs to display to inform the user of changes.

    public enum FeatureChange {

        case conferenceCallingIsAvailable
        case selfDeletingMessagesIsDisabled
        case selfDeletingMessagesIsEnabled(enforcedTimeout: UInt?)
        case fileSharingEnabled
        case fileSharingDisabled

    }

}

extension Notification.Name {

    public static let featureDidChangeNotification = Notification.Name("FeatureDidChangeNotification")

}
