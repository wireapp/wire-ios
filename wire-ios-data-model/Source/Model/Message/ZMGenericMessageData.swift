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

// MARK: - ZMGenericMessageData

@objc(ZMGenericMessageData)
@objcMembers
public class ZMGenericMessageData: ZMManagedObject {
    // MARK: Open

    // MARK: - Static

    override open class func entityName() -> String {
        "GenericMessageData"
    }

    // MARK: Public

    public static let dataKey = "data"
    public static let nonceKey = "nonce"
    public static let messageKey = "message"
    public static let assetKey = "asset"

    /// The nonce used to encrypt `data`, if applicable.

    @NSManaged public private(set) var nonce: Data?

    /// The client message containing this generic message data.

    @NSManaged public var message: ZMClientMessage?

    /// The asset client message containing this generic message data.

    @NSManaged public var asset: ZMAssetClientMessage?

    // MARK: - Properties

    /// The deserialized Protobuf object, if available.

    public var underlyingMessage: GenericMessage? {
        do {
            return try GenericMessage(serializedData: getProtobufData())
        } catch {
            Logging.messageProcessing.warn("Could not retrieve GenericMessage: \(error.localizedDescription)")
            return nil
        }
    }

    /// Whether the Protobuf data is encrypted in the database.

    public var isEncrypted: Bool {
        nonce != nil
    }

    override public var modifiedKeys: Set<AnyHashable>? {
        get { Set() }
        set { /* do nothing */ }
    }

    /// Set the generic message.
    ///
    /// This method will attempt to serialize the protobuf object and store its data in this
    /// instance.
    ///
    /// - Parameter message: The protobuf object whose serialized data will be stored.
    /// - Throws: `ProcessingError` if the data can't be stored.

    public func setGenericMessage(_ message: GenericMessage) throws {
        guard let protobufData = try? message.serializedData() else {
            throw ProcessingError.failedToSerializeMessage
        }

        guard let moc = managedObjectContext else {
            throw ProcessingError.missingManagedObjectContext
        }

        let (data, nonce) = try encryptDataIfNeeded(data: protobufData, in: moc)
        self.data = data
        self.nonce = nonce
    }

    // MARK: Private

    // MARK: - Managed Properties

    /// The (possibly encrypted) serialized Profobuf data.

    @NSManaged private var data: Data

    // MARK: - Methods

    private func getProtobufData() throws -> Data {
        guard let moc = managedObjectContext else {
            throw ProcessingError.missingManagedObjectContext
        }

        return try decryptDataIfNeeded(data: data, in: moc)
    }

    private func encryptDataIfNeeded(data: Data, in moc: NSManagedObjectContext) throws -> (data: Data, nonce: Data?) {
        guard moc.encryptMessagesAtRest else { return (data, nonce: nil) }

        do {
            return try moc.encryptData(data: data)
        } catch let error as NSManagedObjectContext.EncryptionError {
            WireLogger.ear.error("failed to encrypt message: \(String(describing: error))")
            throw ProcessingError.failedToEncrypt(reason: error)
        }
    }

    private func decryptDataIfNeeded(data: Data, in moc: NSManagedObjectContext) throws -> Data {
        guard let nonce else { return data }

        do {
            return try moc.decryptData(data: data, nonce: nonce)
        } catch let error as NSManagedObjectContext.EncryptionError {
            WireLogger.ear.error("failed to decrypt message: \(String(describing: error))")
            throw ProcessingError.failedToDecrypt(reason: error)
        }
    }
}

// MARK: ZMGenericMessageData.ProcessingError

extension ZMGenericMessageData {
    enum ProcessingError: LocalizedError {
        case missingManagedObjectContext
        case failedToSerializeMessage
        case failedToEncrypt(reason: NSManagedObjectContext.EncryptionError)
        case failedToDecrypt(reason: NSManagedObjectContext.EncryptionError)

        // MARK: Internal

        var errorDescription: String? {
            switch self {
            case .missingManagedObjectContext:
                "A managed object context is required to process the message data."
            case .failedToSerializeMessage:
                "The message data couldn't not be serialized."
            case let .failedToEncrypt(reason: encryptionError):
                "The message data could not be encrypted. \(encryptionError.errorDescription ?? "")"
            case let .failedToDecrypt(reason: encryptionError):
                "The message data could not be decrypted. \(encryptionError.errorDescription ?? "")"
            }
        }
    }
}

// MARK: EncryptionAtRestMigratable

extension ZMGenericMessageData: EncryptionAtRestMigratable {
    static let predicateForObjectsNeedingMigration: NSPredicate? = nil

    func migrateTowardEncryptionAtRest(
        in context: NSManagedObjectContext,
        key: VolatileData
    ) throws {
        let (ciphertext, nonce) = try context.encryptData(
            data: data,
            key: key
        )

        data = ciphertext
        self.nonce = nonce
    }

    func migrateAwayFromEncryptionAtRest(
        in context: NSManagedObjectContext,
        key: VolatileData
    ) throws {
        guard let nonce else {
            return
        }

        let plaintext = try context.decryptData(
            data: data,
            nonce: nonce,
            key: key
        )

        data = plaintext
        self.nonce = nil
    }
}
