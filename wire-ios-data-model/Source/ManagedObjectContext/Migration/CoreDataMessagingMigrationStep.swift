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


import CoreData

struct CoreDataMessagingMigrationStep {

    let sourceVersion: CoreDataMessagingMigrationVersion
    let destinationVersion: CoreDataMessagingMigrationVersion

    let sourceModel: NSManagedObjectModel
    let destinationModel: NSManagedObjectModel
    let mappingModel: NSMappingModel

    // MARK: Init

    init(
        sourceVersion: CoreDataMessagingMigrationVersion,
        destinationVersion: CoreDataMessagingMigrationVersion
    ) throws {
        guard
            let sourceURL = sourceVersion.managedObjectModelURL(),
            let destinationURL = destinationVersion.managedObjectModelURL(),
            let sourceModel = NSManagedObjectModel(contentsOf: sourceURL),
            let destinationModel = NSManagedObjectModel(contentsOf: destinationURL),
            let mappingModel = try? Self.mappingModel(fromSourceModel: sourceModel, toDestinationModel: destinationModel)
        else {
            let message = "can not initialize migration step from source: \(sourceVersion) to destination: \(destinationVersion)!"
            throw CoreDataMessagingMigratorError.missingFiles(message: message)
        }

        self.sourceVersion = sourceVersion
        self.destinationVersion = destinationVersion
        self.sourceModel = sourceModel
        self.destinationModel = destinationModel
        self.mappingModel = mappingModel
    }

    // MARK: - Mapping

    private static func mappingModel(
        fromSourceModel sourceModel: NSManagedObjectModel,
        toDestinationModel destinationModel: NSManagedObjectModel
    ) throws -> NSMappingModel {
        guard let customMapping = customMappingModel(fromSourceModel: sourceModel, toDestinationModel: destinationModel) else {
            return try inferredMappingModel(fromSourceModel:sourceModel, toDestinationModel: destinationModel)
        }
        return customMapping
    }

    private static func inferredMappingModel(
        fromSourceModel sourceModel: NSManagedObjectModel,
        toDestinationModel destinationModel: NSManagedObjectModel
    ) throws -> NSMappingModel {
        try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
    }

    private static func customMappingModel(
        fromSourceModel sourceModel: NSManagedObjectModel,
        toDestinationModel destinationModel: NSManagedObjectModel
    ) -> NSMappingModel? {
        NSMappingModel(
            from: [WireDataModelBundle.bundle],
            forSourceModel: sourceModel,
            destinationModel: destinationModel
        )
    }
}
