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

    /// The app lock
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
        context.performGroupedAndWait {
            let config = try! JSONEncoder().encode(appLock.config)
            Feature.updateOrCreate(havingName: .appLock, in: $0) {
                $0.status = appLock.status
                $0.config = config
            }
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
        context.performGroupedAndWait {
            Feature.updateOrCreate(havingName: .conferenceCalling, in: $0) {
                $0.status = conferenceCalling.status
            }
        }
    }

    /// The file sharing
    public func fetchFileSharing() -> Feature.FileSharing {
        let feature = Feature.fetch(name: .fileSharing, context: context)!
        return .init(status: feature.status)
    }

    public func storeFileSharing(_ fileSharing: Feature.FileSharing) {
        Feature.updateOrCreate(havingName: .fileSharing, in: context) {
            $0.status = fileSharing.status
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

    public func needsToNotifyUser(for featureName: Feature.Name) -> Bool {
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

}
