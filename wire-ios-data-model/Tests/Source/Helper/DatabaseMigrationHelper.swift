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


import XCTest
@testable import WireDataModel

struct DatabaseMigrationHelper {

    private let bundle = Bundle(for: ZMManagedObject.self)
    private let dataModelName = "zmessaging"

    func createObjectModel(version: String) throws -> NSManagedObjectModel {
        let modelVersion = "\(dataModelName)\(version)"

        // Get the compiled datamodel file bundle
        let modelURL = try XCTUnwrap(bundle.url(
            forResource: dataModelName,
            withExtension: "momd"
        ))
        let modelBundle = try XCTUnwrap(Bundle(url: modelURL))

        // Create the url for the given datamodel version
        let modelVersionURL = try XCTUnwrap(modelBundle.url(
            forResource: modelVersion,
            withExtension: "mom"
        ), "\(modelVersion).mom not found in Bundle \(modelBundle)")

        // Create the versioned model from the url
        return try XCTUnwrap(NSManagedObjectModel(contentsOf: modelVersionURL))
    }

    func createStore(model: NSManagedObjectModel, at storeURL: URL) throws -> NSPersistentContainer {
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

    func inferredMappingModel(sourceVersion: String, destinationVersion: String) throws -> NSMappingModel {
        let sourceModel = try createObjectModel(version: sourceVersion)
        let destinationModel = try createObjectModel(version: destinationVersion)

        return try NSMappingModel.inferredMappingModel(
            forSourceModel: sourceModel,
            destinationModel: destinationModel
        )
    }
}
