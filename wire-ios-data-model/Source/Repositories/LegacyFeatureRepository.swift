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
import WireLogging

// sourcery: AutoMockable
public protocol LegacyFeatureRepositoryInterface {

    func fetchAppLock() -> Feature.AppLock
    func storeAppLock(_ appLock: Feature.AppLock)
    func fetchApps() -> Feature.Apps
    func storeApps(_ appLock: Feature.Apps)
    func fetchConferenceCalling() -> Feature.ConferenceCalling
    func storeConferenceCalling(_ conferenceCalling: Feature.ConferenceCalling)
    func fetchFileSharing() -> Feature.FileSharing
    func storeFileSharing(_ fileSharing: Feature.FileSharing)
    func fetchSelfDeletingMessages() -> Feature.SelfDeletingMessages
    func storeSelfDeletingMessages(_ selfDeletingMessages: Feature.SelfDeletingMessages)
    func fetchAllowedGlobalOperations() async -> Feature.AllowedGlobalOperations
    func storeAllowedGlobalOperations(_ resetMLSConversations: Feature.AllowedGlobalOperations)
    func fetchConversationGuestLinks() -> Feature.ConversationGuestLinks
    func storeConversationGuestLinks(_ conversationGuestLinks: Feature.ConversationGuestLinks)
    func fetchClassifiedDomains() -> Feature.ClassifiedDomains
    func storeClassifiedDomains(_ classifiedDomains: Feature.ClassifiedDomains)
    func fetchDigitalSignature() -> Feature.DigitalSignature
    func storeDigitalSignature(_ digitalSignature: Feature.DigitalSignature)
    func fetchMLS() -> Feature.MLS
    func fetchMLS() async -> Feature.MLS
    func storeMLS(_ mls: Feature.MLS)
    func fetchE2EI() -> Feature.E2EI
    func storeE2EI(_ e2ei: Feature.E2EI)
    func fetchMLSMigration() -> Feature.MLSMigration
    func storeMLSMigration(_ mlsMigration: Feature.MLSMigration)
    func fetchChannels() -> Feature.Channels
    func storeChannels(_ channels: Feature.Channels)
    func fetchConsumableNotifications() -> Feature.ConsumableNotifications
    func storeConsumableNotifications(_ consumableNotifications: Feature.ConsumableNotifications)
    func fetchCells() -> Feature.Cells
    func storeCells(_ cells: Feature.Cells)
    func fetchAssetAuditLog() -> Feature.AssetAuditLog

}

/// **Do not use it for new code, use FeatureConfigRepository instead**
///
/// This class facilitates storage and retrieval of feature configs to and from
/// the database.
///
/// Each `Feature` may have a different structure for its configuration, so a json
/// encoded form is what is stored in the database. Use this class to fetch a specific
/// feature as a type that contains a decoded configuration.
///
/// **Note:** fetching features can occur on any context, but updates should only
/// take place on the sync context.

public class LegacyFeatureRepository: LegacyFeatureRepositoryInterface {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let logger = WireLogger(tag: "LegacyFeatureRepository")
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // MARK: - Life cycle

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - App lock

    public func fetchAppLock() -> Feature.AppLock {
        guard
            let feature = Feature.fetch(name: .appLock, context: context),
            let featureConfig = feature.config
        else {
            return .init()
        }

        var config = Feature.AppLock.Config()

        do {
            config = try decoder.decode(Feature.AppLock.Config.self, from: featureConfig)
        } catch {
            logger.error("failed to decode Feature.AppLock.Config: \(error)")
        }

        return .init(status: feature.status, config: config)
    }

    public func storeAppLock(_ appLock: Feature.AppLock) {
        do {
            let config = try encoder.encode(appLock.config)

            Feature.updateOrCreate(havingName: .appLock, in: context) {
                $0.status = appLock.status
                $0.config = config
            }
        } catch {
            logger.error("failed to encode Feautre.AppLock.Config: \(error)")
        }
    }

    // MARK: Apps

    public func fetchApps() -> Feature.Apps {
        guard let feature = Feature.fetch(name: .apps, context: context) else {
            return .init()
        }

        return .init(status: feature.status)
    }

    public func storeApps(_ apps: Feature.Apps) {
        Feature.updateOrCreate(havingName: .apps, in: context) {
            $0.status = apps.status
        }
    }

    // MARK: - Conference calling

    public func fetchConferenceCalling() -> Feature.ConferenceCalling {
        guard let feature = Feature.fetch(name: .conferenceCalling, context: context) else {
            return .init()
        }

        guard let featureConfig = feature.config else {
            return .init(status: feature.status)
        }
        var config = Feature.ConferenceCalling.Config()
        do {
            config = try decoder.decode(Feature.ConferenceCalling.Config.self, from: featureConfig)
        } catch {
            logger.error("failed to decode Feature.ConferenceCalling.Config: \(error)")
        }

        return .init(status: feature.status, config: config)
    }

    public func storeConferenceCalling(_ conferenceCalling: Feature.ConferenceCalling) {
        func notifyUser() {
            guard
                needsToNotifyUser(for: .conferenceCalling),
                conferenceCalling.status == .enabled
            else {
                return
            }

            notifyChange(.conferenceCallingIsAvailable)
        }

        guard let featureConfig = conferenceCalling.config else {
            Feature.updateOrCreate(havingName: .conferenceCalling, in: context) {
                $0.status = conferenceCalling.status
            }
            notifyUser()
            return
        }

        do {
            let config = try encoder.encode(featureConfig)
            Feature.updateOrCreate(havingName: .conferenceCalling, in: context) {
                $0.status = conferenceCalling.status
                $0.config = config
            }

            notifyUser()
        } catch {
            logger.error("failed to encoder Feature.ConferenceCalling.Config: \(error)")
        }
    }

    // MARK: - File sharing

    public func fetchFileSharing() -> Feature.FileSharing {
        guard let feature = Feature.fetch(name: .fileSharing, context: context) else {
            return .init()
        }

        return .init(status: feature.status)
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

    // MARK: - Self deleting messages

    public func fetchSelfDeletingMessages() -> Feature.SelfDeletingMessages {
        guard
            let feature = Feature.fetch(name: .selfDeletingMessages, context: context),
            let featureConfig = feature.config
        else {
            return .init()
        }

        var config = Feature.SelfDeletingMessages.Config()

        do {
            config = try decoder.decode(Feature.SelfDeletingMessages.Config.self, from: featureConfig)
        } catch {
            logger.error("failed to decode Feature.SelfDeletingMessages.Config: \(error)")
        }

        return .init(status: feature.status, config: config)
    }

    public func storeSelfDeletingMessages(_ selfDeletingMessages: Feature.SelfDeletingMessages) {
        do {
            let config = try encoder.encode(selfDeletingMessages.config)

            Feature.updateOrCreate(havingName: .selfDeletingMessages, in: context) {
                $0.status = selfDeletingMessages.status
                $0.config = config
            }

            guard needsToNotifyUser(for: .selfDeletingMessages) else { return }

            switch (selfDeletingMessages.status, selfDeletingMessages.config.enforcedTimeoutSeconds) {
            case (.disabled, _):
                notifyChange(.selfDeletingMessagesIsDisabled)

            case let (.enabled, enforcedTimeout) where enforcedTimeout > 0:
                notifyChange(.selfDeletingMessagesIsEnabled(enforcedTimeout: enforcedTimeout))

            case (.enabled, _):
                notifyChange(.selfDeletingMessagesIsEnabled(enforcedTimeout: nil))
            }
        } catch {
            logger.error("failed to encode Feature.SelfDeletingMessages.Config: \(error)")
        }
    }

    public func storeAllowedGlobalOperations(_ allowedGlobalOperations: Feature.AllowedGlobalOperations) {
        do {
            let config = try encoder.encode(allowedGlobalOperations.config)

            Feature.updateOrCreate(havingName: .allowedGlobalOperations, in: context) {
                $0.status = allowedGlobalOperations.status
                $0.config = config
            }
        } catch {
            logger.error("failed to encode Feature.AllowedGlobalOperations.Config: \(error)")
        }
    }

    public func fetchAllowedGlobalOperations() async -> Feature.AllowedGlobalOperations {
        let (featureStatus, featureConfig) = await context.perform { [context] in
            let feature = Feature.fetch(name: .allowedGlobalOperations, context: context)
            return (feature?.status, feature?.config)
        }

        guard let featureConfig, let featureStatus else {
            return .init()
        }

        var config = Feature.AllowedGlobalOperations.Config()

        do {
            config = try decoder.decode(
                Feature.AllowedGlobalOperations.Config.self,
                from: featureConfig
            )
        } catch {
            logger.error("failed to decode Feature.AllowedGlobalOperations.Config: \(error)")
        }

        return .init(status: featureStatus, config: config)

    }

    // MARK: - Conversation guest links

    public func fetchConversationGuestLinks() -> Feature.ConversationGuestLinks {
        guard let feature = Feature.fetch(name: .conversationGuestLinks, context: context) else {
            return .init()
        }
        return .init(status: feature.status)
    }

    public func storeConversationGuestLinks(_ conversationGuestLinks: Feature.ConversationGuestLinks) {
        Feature.updateOrCreate(havingName: .conversationGuestLinks, in: context) {
            $0.status = conversationGuestLinks.status
        }

        guard needsToNotifyUser(for: .conversationGuestLinks) else { return }

        switch conversationGuestLinks.status {
        case .disabled:
            notifyChange(.conversationGuestLinksDisabled)

        case .enabled:
            notifyChange(.conversationGuestLinksEnabled)
        }
    }

    // MARK: - Classified domains

    public func fetchClassifiedDomains() -> Feature.ClassifiedDomains {
        guard
            let feature = Feature.fetch(name: .classifiedDomains, context: context),
            let featureConfig = feature.config
        else {
            return .init()
        }

        var config = Feature.ClassifiedDomains.Config()

        do {
            config = try decoder.decode(Feature.ClassifiedDomains.Config.self, from: featureConfig)
        } catch {
            logger.error("failed to decode Feature.ClassifiedDomains.Config: \(error)")
        }

        return .init(status: feature.status, config: config)
    }

    public func storeClassifiedDomains(_ classifiedDomains: Feature.ClassifiedDomains) {
        do {
            let config = try encoder.encode(classifiedDomains.config)

            Feature.updateOrCreate(havingName: .classifiedDomains, in: context) {
                $0.status = classifiedDomains.status
                $0.config = config
            }
        } catch {
            logger.error("failed to encode Feature.ClassifiedDomains.Config: \(error)")
        }
    }

    // MARK: - Digital signature

    public func fetchDigitalSignature() -> Feature.DigitalSignature {
        guard let feature = Feature.fetch(name: .digitalSignature, context: context) else {
            return .init()
        }

        return .init(status: feature.status)
    }

    public func storeDigitalSignature(_ digitalSignature: Feature.DigitalSignature) {
        Feature.updateOrCreate(havingName: .digitalSignature, in: context) {
            $0.status = digitalSignature.status
        }
    }

    // MARK: - MLS

    public func fetchMLS() async -> Feature.MLS {
        let (status, configData) = await context.perform { [context] in
            let feature = Feature.fetch(name: .mls, context: context)
            return (feature?.status, feature?.config)
        }

        return makeMLS(status: status, configData: configData)
    }

    public func fetchMLS() -> Feature.MLS {
        let (status, configData) = context.performAndWait {
            let feature = Feature.fetch(name: .mls, context: context)
            return (feature?.status, feature?.config)
        }

        return makeMLS(status: status, configData: configData)
    }

    private func makeMLS(status: Feature.Status?, configData: Data?) -> Feature.MLS {
        guard let status, let configData else {
            return .init()
        }

        var config = Feature.MLS.Config()

        do {
            config = try decoder.decode(Feature.MLS.Config.self, from: configData)
        } catch {
            logger.error("failed to decode Feature.MLS.Config: \(error)")
        }

        return .init(status: status, config: config)
    }

    public func storeMLS(_ mls: Feature.MLS) {
        do {
            let config = try encoder.encode(mls.config)

            Feature.updateOrCreate(havingName: .mls, in: context) {
                $0.status = mls.status
                $0.config = config
            }
        } catch {
            logger.error("failed to encode Feature.MLS.Config: \(error)")
        }
    }

    // MARK: - E2EId

    public func fetchE2EI() -> Feature.E2EI {
        guard
            let feature = Feature.fetch(name: .e2ei, context: context),
            let featureConfig = feature.config
        else {
            return .init()
        }

        let config = try! JSONDecoder().decode(Feature.E2EI.Config.self, from: featureConfig)
        return .init(status: feature.status, config: config)
    }

    public func storeE2EI(_ e2ei: Feature.E2EI) {
        do {
            let config = try encoder.encode(e2ei.config)

            Feature.updateOrCreate(havingName: .e2ei, in: context) {
                $0.status = e2ei.status
                $0.config = config
            }
        } catch {
            logger.error("failed to encode Feature.E2EI.Config: \(error)")
        }

        guard
            needsToNotifyUser(for: .e2ei),
            e2ei.status == .enabled
        else {
            return
        }

        notifyChange(.e2eIEnabled)
    }

    // MARK: - MLSMigration

    public func fetchMLSMigration() -> Feature.MLSMigration {
        guard
            let feature = Feature.fetch(name: .mlsMigration, context: context),
            let featureConfig = feature.config
        else {
            return .init()
        }

        var config = Feature.MLSMigration.Config()

        do {
            config = try decoder.decode(Feature.MLSMigration.Config.self, from: featureConfig)
        } catch {
            logger.error("failed to decode Feature.MLS.Config: \(error)")
        }

        return .init(status: feature.status, config: config)
    }

    public func storeMLSMigration(_ mlsMigration: Feature.MLSMigration) {
        do {
            let config = try encoder.encode(mlsMigration.config)

            Feature.updateOrCreate(havingName: .mlsMigration, in: context) {
                $0.status = mlsMigration.status
                $0.config = config
            }
        } catch {
            logger.error("failed to encode Feature.MLS.Config: \(error)")
        }
    }

    // MARK: - Channels

    public func fetchChannels() -> Feature.Channels {
        guard
            let feature = Feature.fetch(name: .channels, context: context),
            let featureConfig = feature.config
        else {
            return .init()
        }

        var config = Feature.Channels.Config()

        do {
            config = try decoder.decode(Feature.Channels.Config.self, from: featureConfig)
        } catch {
            logger.error("failed to decode Feature.Channels.Config: \(error)")
        }

        return .init(status: feature.status, config: config)
    }

    public func storeChannels(_ channels: Feature.Channels) {
        do {
            let config = try encoder.encode(channels.config)

            Feature.updateOrCreate(havingName: .channels, in: context) {
                $0.status = channels.status
                $0.config = config
            }
        } catch {
            logger.error("failed to encode Feature.Channels.Config: \(error)")
        }
    }

    public func fetchConsumableNotifications() -> Feature.ConsumableNotifications {
        guard let feature = Feature.fetch(name: .consumableNotifications, context: context) else {
            return .init()
        }

        return .init(status: feature.status)
    }

    public func storeConsumableNotifications(_ consumableNotifications: Feature.ConsumableNotifications) {
        Feature.updateOrCreate(havingName: .consumableNotifications, in: context) {
            $0.status = consumableNotifications.status
        }
    }

    // MARK: Cells

    public func fetchCells() -> Feature.Cells {
        guard let feature = Feature.fetch(name: .cells, context: context) else {
            return .init()
        }

        return .init(status: feature.status)
    }

    public func storeCells(_ cells: Feature.Cells) {
        Feature.updateOrCreate(havingName: .cells, in: context) {
            $0.status = cells.status
        }
    }

    // MARK: - Asset audit log

    public func fetchAssetAuditLog() -> Feature.AssetAuditLog {
        guard let feature = Feature.fetch(name: .assetAuditLog, context: context) else {
            return .init()
        }

        return .init(status: feature.status)
    }

    // MARK: - Methods

    func createDefaultConfigsIfNeeded() {
        for name in Feature.Name.allCases where Feature.fetch(name: name, context: context) == nil {
            switch name {
            case .appLock:
                storeAppLock(.init())

            case .apps:
                storeApps(.init())

            case .conferenceCalling:
                storeConferenceCalling(.init())

            case .fileSharing:
                storeFileSharing(.init())

            case .selfDeletingMessages:
                storeSelfDeletingMessages(.init())

            case .allowedGlobalOperations:
                storeAllowedGlobalOperations(.init())

            case .conversationGuestLinks:
                storeConversationGuestLinks(.init())

            case .classifiedDomains:
                storeClassifiedDomains(.init())

            case .digitalSignature:
                storeDigitalSignature(.init())

            case .mls:
                storeMLS(.init())

            case .e2ei:
                storeE2EI(.init())

            case .mlsMigration:
                storeMLSMigration(.init())

            case .channels:
                storeChannels(.init())

            case .consumableNotifications:
                storeConsumableNotifications(.init())

            case .cells:
                storeCells(.init())

            case .assetAuditLog:
                // No op: not supported in legacy repository.
                break
            }
        }
    }

    func needsToNotifyUser(for featureName: Feature.Name) -> Bool {
        var result = false

        context.performGroupedAndWait {
            let feature = Feature.fetch(name: featureName, context: context)
            result = feature?.needsToNotifyUser ?? false
        }

        return result
    }

    public func setNeedsToNotifyUser(_ notifyUser: Bool, for featureName: Feature.Name) {
        context.performGroupedAndWait {
            let feature = Feature.fetch(name: featureName, context: context)
            feature?.needsToNotifyUser = notifyUser
        }
    }

    private func notifyChange(_ change: FeatureChange) {
        NotificationCenter.default.post(name: .featureDidChangeNotification, object: change)
    }

}

public extension LegacyFeatureRepository {

    /// A type that represents the possible changes to feature configs.
    ///
    /// These can be used by the ui layer to determine what kind of alert
    /// it needs to display to inform the user of changes.

    enum FeatureChange: Equatable {

        case conferenceCallingIsAvailable
        case selfDeletingMessagesIsDisabled
        case selfDeletingMessagesIsEnabled(enforcedTimeout: UInt?)
        case fileSharingEnabled
        case fileSharingDisabled
        case conversationGuestLinksEnabled
        case conversationGuestLinksDisabled
        case e2eIEnabled

        public var hasFurtherActions: Bool {
            switch self {
            case .e2eIEnabled:
                true
            default:
                false
            }
        }
    }

}

public extension Notification.Name {

    static let featureDidChangeNotification = Notification.Name("FeatureDidChangeNotification")

}
