////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

enum CoreDataMessagingMigrationVersion: String, CaseIterable {

    private enum Constant {
        static let dataModelPrefix = "zmessaging"
        static let modelDirectory = "zmessaging.momd"
        static let resourceExtension = "mom"
    }

    // MARK: -

    // Note: add new versions here in first position!
    case version2_111 = "zmessaging2.111.0"
    case version2_110 = "zmessaging2.110.0"
    case version2_109 = "zmessaging2.109.0"
    case version2_108 = "zmessaging2.108.0"
    case version2_107 = "zmessaging2.107.0"
    case version2_106 = "zmessaging2.106.0"
    case version2_105 = "zmessaging2.105.0"
    case version2_104 = "zmessaging2.104.0"
    case version2_103 = "zmessaging2.103.0"
    case version2_102 = "zmessaging2.102.0"
    case version2_101 = "zmessaging2.101.0"
    case version2_100 = "zmessaging2.100.0"
    case version2_99 = "zmessaging2.99.0"
    case version2_98 = "zmessaging2.98.0"
    case version2_97 = "zmessaging2.97.0"
    case version2_96 = "zmessaging2.96.0"
    case version2_95 = "zmessaging2.95.0"
    case version2_94 = "zmessaging2.94.0"
    case version2_93 = "zmessaging2.93.0"
    case version2_92 = "zmessaging2.92.0"
    case version2_91 = "zmessaging2.91.0"
    case version2_90 = "zmessaging2.90.0"
    case version2_89 = "zmessaging2.89.0"
    case version2_88 = "zmessaging2.88.0"
    case version2_87 = "zmessaging2.87.0"
    case version2_86 = "zmessaging2.86.0"
    case version2_85 = "zmessaging2.85.0"
    case version2_84 = "zmessaging2.84.0"
    case version2_83 = "zmessaging2.83.0"
    case version2_82 = "zmessaging2.82.0"
    case version2_81 = "zmessaging2.81.0"
    case version2_80 = "zmessaging2.80.0"

    var nextVersion: Self? {
        switch self {
        case .version2_111:
            return nil
        case .version2_110:
            return .version2_111
        case .version2_109:
            return .version2_110
        case .version2_108:
            return .version2_109
        case .version2_107:
            return .version2_108
        case .version2_106:
            return .version2_107
        case .version2_80,
                .version2_81,
                .version2_82,
                .version2_83,
                .version2_84,
                .version2_85,
                .version2_86,
                .version2_87,
                .version2_88,
                .version2_89,
                .version2_90,
                .version2_91,
                .version2_92,
                .version2_93,
                .version2_94,
                .version2_95,
                .version2_96,
                .version2_97,
                .version2_98,
                .version2_99,
                .version2_100,
                .version2_101,
                .version2_102,
                .version2_103,
                .version2_104,
                .version2_105:
            return .version2_106
        }
    }

    /// Returns the version used in `.xcdatamodel`, like "2.3" for data model "zmessaging2.3".
    var dataModelVersion: String {
        rawValue.replacingOccurrences(of: Constant.dataModelPrefix, with: "")
    }

    // MARK: Current

    static let current: Self = {
        guard let current = allCases.first else {
            fatalError("no model versions found")
        }
        return current
    }()

    // MARK: Store URL

    func managedObjectModelURL() -> URL? {
        WireDataModelBundle.bundle.url(
            forResource: rawValue,
            withExtension: Constant.resourceExtension,
            subdirectory: Constant.modelDirectory
        )
    }

    var preMigrationAction: CoreDataAction? {
        switch self {
        case .version2_111:
            return RemoveDuplicatePreAction()

        default:
            return nil
        }
    }

    var postMigrationAction: CoreDataAction? {
        switch self {
        case .version2_111:
            return PrefillPrimaryKeyAction()

        default:
            return nil
        }
    }
}

private let dataModelName = "zmessaging"
private let bundle = WireDataModelBundle.bundle

extension CoreDataMessagingMigrationStep {

    func runPreMigrationStep(for storeURL: URL) throws {
        guard let action = self.destinationVersion.preMigrationAction else { return }

        let container = try createStore(model: self.sourceModel, at: storeURL)
        try action.perform(with: container)
    }

    func runPostMigrationStep(for storeURL: URL) throws {
        guard let action = self.destinationVersion.postMigrationAction else { return }

        let container = try createStore(model: self.destinationModel, at: storeURL)
        try action.perform(with: container)
    }

    private func createObjectModel(version: String) -> NSManagedObjectModel? {
        let modelVersion = "\(dataModelName)\(version)"

        // Get the compiled datamodel file bundle
        let modelURL = bundle.url(
            forResource: dataModelName,
            withExtension: "momd"
        )!

        let modelBundle = Bundle(url: modelURL)

        let modelVersionURL = modelBundle?.url(
            forResource: modelVersion,
            withExtension: "mom"
        )

        return modelVersionURL.flatMap { NSManagedObjectModel(contentsOf: $0) }
    }

    private func createStore(model: NSManagedObjectModel, at storeURL: URL) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(
            name: dataModelName,
            managedObjectModel: model
        )

        try container.persistentStoreCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL,
            options: nil
        )

        return container
    }
}

class CoreDataAction {

    private func loadStores(for persistentContainer: NSPersistentContainer) throws {
        persistentContainer.persistentStoreDescriptions.first?.shouldAddStoreAsynchronously = false

        var loadError: Error?
        persistentContainer.loadPersistentStores { description, error in
            loadError =  error
        }
        if let loadError {
            throw loadError
        }
    }

    func perform(with persistentContainer: NSPersistentContainer) throws {

        try loadStores(for: persistentContainer)

        let context = persistentContainer.newBackgroundContext()
        var savedError: Error?
        context.performAndWait {
            do {
                try self.execute(in: context)
                try context.save()
            } catch {
                savedError = error
            }
        }
        if let savedError {
            throw savedError
        }
    }


    func execute(in context: NSManagedObjectContext) throws {
        // to be overiden by subclasses
    }
}

class PrefillPrimaryKeyAction: CoreDataAction, CoreDataAction2111 {

    private enum Keys: String {
        case primaryKey
    }

    let entityNames = [ZMUser.entityName(), ZMConversation.entityName()]

    override func execute(in context: NSManagedObjectContext) throws {
        entityNames.forEach { entityName in
            fillPrimaryKeys(for: entityName, context: context)
        }
    }

    private func fillPrimaryKeys(for entityName: String, context: NSManagedObjectContext) {
        do {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.fetchBatchSize = 200
            let objects = try context.fetch(request)

            objects.forEach { object in

                let uniqueKey = self.primaryKey(for: object, entityName: entityName)
                object.setValue(uniqueKey, forKey: Keys.primaryKey.rawValue)
            }
        } catch {
            WireLogger.localStorage.error("error fetching data \(entityName): \(error.localizedDescription)")
        }
    }
}

class RemoveDuplicatePreAction: CoreDataAction, CoreDataAction2111 {

    private enum Keys: String {
        case needsToBeUpdatedFromBackend
        case primaryKey
    }

    let entityNames = [ZMUser.entityName(), ZMConversation.entityName(), Team.entityName()]

    override func execute(in context: NSManagedObjectContext) {
        entityNames.forEach { entityName in
            removeDuplicates(for: entityName, context: context)
        }
    }

    private func removeDuplicates(for entityName: String, context: NSManagedObjectContext) {
        let duplicateObjects: [Data: [NSManagedObject]] = context.findDuplicated(
            entityName: entityName,
            by: ZMManagedObject.remoteIdentifierDataKey()
        )

        var duplicates = [String: [NSManagedObject]]()

        duplicateObjects.forEach { (remoteIdentifierData: Data, objects: [NSManagedObject]) in
            objects.forEach { object in

                let uniqueKey = self.primaryKey(for: object, entityName: entityName)
                if duplicates[uniqueKey] == nil {
                    duplicates[uniqueKey] = []
                }
                duplicates[uniqueKey]?.append(object)
            }
        }

        WireLogger.localStorage.info("found (\(duplicates.count)) occurences of duplicate \(entityName)")

        duplicates.forEach { (key, objects: [NSManagedObject]) in
            guard objects.count > 1 else {
                WireLogger.localStorage.info("skipping object with different domain if any: \(key)")
                return
            }
            WireLogger.localStorage.debug("processing \(key)")
            // for now we just keep one object and mark to sync and drop the rest.
            // Marking needsToBeUpdatedFromBackend will recover the data from backend
            objects.first?.setValue(true, forKey: Keys.needsToBeUpdatedFromBackend.rawValue)
            objects.dropFirst().forEach(context.delete)

            WireLogger.localStorage.warn("removed  \(objects.count - 1) occurence of duplicate users", attributes: .safePublic)
        }

    }
}

protocol CoreDataAction2111 {
    func primaryKey(for object: NSManagedObject, entityName: String) -> String
}

extension CoreDataAction2111 {

    func primaryKey(for object: NSManagedObject, entityName: String) -> String {

        let remoteIdentifierData = object.value(forKey: ZMManagedObject.remoteIdentifierDataKey()) as? Data

        switch entityName {
        case ZMUser.entityName(), ZMConversation.entityName():
            let path = entityName == ZMUser.entityName() ? #keyPath(ZMUser.domain) : #keyPath(ZMConversation.domain)

            let domain = object.value(forKeyPath: path) as? String
            return ZMManagedObject.primaryKey(from: remoteIdentifierData.flatMap(UUID.init(data: )), domain: domain)

        case Team.entityName():

            return remoteIdentifierData.flatMap { UUID(data: $0)?.uuidString } ?? "<nil>"
        default:
            fatal("Entity named \(entityName) is not supported")
        }
    }

}
