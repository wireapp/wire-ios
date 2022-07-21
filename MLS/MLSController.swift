//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

public protocol MLSControllerProtocol {
    func uploadKeyPackagesIfNeeded()
    func conversationExists(groupID: MLSGroupID) -> Bool
    @discardableResult func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID
}

public final class MLSController: MLSControllerProtocol {

    // MARK: - Properties

    private weak var context: NSManagedObjectContext?
    private let coreCrypto: CoreCryptoProtocol
    private let logger = ZMSLog(tag: "core-crypto")

    let targetUnclaimedKeyPackageCount = 100

    let actionProvider: MLSActionsProviderProtocol

    // MARK: - Life cycle

    init(
        context: NSManagedObjectContext,
        coreCrypto: CoreCryptoProtocol,
        actionProvider: MLSActionsProviderProtocol = MLSActionsProvider()
    ) {
        self.context = context
        self.coreCrypto = coreCrypto
        self.actionProvider = actionProvider

        do {
            try generatePublicKeysIfNeeded()
        } catch {
            logger.error("failed to generate public keys: \(String(describing: error))")
        }
    }

    // MARK: - Public keys

    private func generatePublicKeysIfNeeded() throws {
        guard
            let context = context,
            let selfClient = ZMUser.selfUser(in: context).selfClient()
        else {
            return
        }

        var keys = selfClient.mlsPublicKeys

        if keys.ed25519 == nil {
            let keyBytes = try coreCrypto.wire_clientPublicKey()
            let keyData = Data(keyBytes)
            keys.ed25519 = keyData.base64EncodedString()
        }

        selfClient.mlsPublicKeys = keys
        context.saveOrRollback()
    }

    // MARK: - Key packages

    enum MLSKeyPackagesError: Error {

        case failedToGenerateKeyPackages

    }

    /// Uploads new key packages if needed.
    ///
    /// Checks how many key packages are available on the backend and
    /// generates new ones if there are less than 50% of the target unclaimed key package count..

    public func uploadKeyPackagesIfNeeded() {
        guard let context = context else { return }
        let user = ZMUser.selfUser(in: context)
        guard let clientID = user.selfClient()?.remoteIdentifier else { return }

        // TODO: Here goes the logic to determine how check to remaining key packages and re filling the new key packages after calculating number of welcome messages it receives by the client.

        /// For now temporarily we generate and upload at most 100 new key packages

         countUnclaimedKeyPackages(clientID: clientID, context: context.notificationContext) { unclaimedKeyPackageCount in
            guard unclaimedKeyPackageCount <= self.targetUnclaimedKeyPackageCount / 2 else { return }

            do {
                let amount = UInt32(self.targetUnclaimedKeyPackageCount - unclaimedKeyPackageCount)
                let keyPackages = try self.generateKeyPackages(amountRequested: amount)

                self.uploadKeyPackages(
                    clientID: clientID,
                    keyPackages: keyPackages,
                    context: context.notificationContext
                )

            } catch {
                self.logger.error("failed to generate new key packages: \(String(describing: error))")
            }
        }
    }

    private func countUnclaimedKeyPackages(clientID: String, context: NotificationContext, completion: @escaping (Int) -> Void) {
        actionProvider.countUnclaimedKeyPackages(clientID: clientID, context: context) { result in
            switch result {
            case .success(let count):
                completion(count)

            case .failure(let error):
                self.logger.error("failed to fetch MLS key packages count with error: \(String(describing: error))")
            }
        }
    }

    private func generateKeyPackages(amountRequested: UInt32) throws -> [String] {

        var keyPackages = [[UInt8]]()

        do {

            keyPackages = try coreCrypto.wire_clientKeypackages(amountRequested: amountRequested)

        } catch let error {
            logger.error("failed to generate new key packages: \(String(describing: error))")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        if keyPackages.isEmpty {
            logger.error("CoreCrypto generated empty key packages array")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        return keyPackages.map {
            Data($0).base64EncodedString()
        }
    }

    private func uploadKeyPackages(clientID: String, keyPackages: [String], context: NotificationContext) {
        actionProvider.uploadKeyPackages(clientID: clientID, keyPackages: keyPackages, context: context) { result in
            switch result {
            case .success:
                break

            case .failure(let error):
                self.logger.error("failed to upload key packages: \(String(describing: error))")
            }
        }
    }
}

protocol MLSActionsProviderProtocol {

    func countUnclaimedKeyPackages(
        clientID: String,
        context: NotificationContext,
        resultHandler: @escaping CountSelfMLSKeyPackagesAction.ResultHandler
    )

    func uploadKeyPackages(
        clientID: String,
        keyPackages: [String],
        context: NotificationContext,
        resultHandler: @escaping UploadSelfMLSKeyPackagesAction.ResultHandler
    )

}

private class MLSActionsProvider: MLSActionsProviderProtocol {

    func countUnclaimedKeyPackages(clientID: String, context: NotificationContext, resultHandler: @escaping CountSelfMLSKeyPackagesAction.ResultHandler) {
        let action = CountSelfMLSKeyPackagesAction(clientID: clientID, resultHandler: resultHandler)
        action.send(in: context)
    }

    func uploadKeyPackages(clientID: String, keyPackages: [String], context: NotificationContext, resultHandler: @escaping UploadSelfMLSKeyPackagesAction.ResultHandler) {
        let action = UploadSelfMLSKeyPackagesAction(clientID: clientID, keyPackages: keyPackages, resultHandler: resultHandler)
        action.send(in: context)
    }
}

// MARK: - Process Welcome Message

extension MLSController {

    public func conversationExists(groupID: MLSGroupID) -> Bool {
        return coreCrypto.wire_conversationExists(conversationId: groupID.bytes)
    }

    @discardableResult
    public func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID {
        guard let messageBytes = welcomeMessage.base64EncodedBytes else {
            logger.error("failed to convert welcome message to bytes")
            throw MLSWelcomeMessageProcessingError.failedToConvertMessageToBytes
        }

        do {
            let groupID = try coreCrypto.wire_processWelcomeMessage(welcomeMessage: messageBytes)
            return MLSGroupID(bytes: groupID)
        } catch {
            logger.error("failed to process welcome message: \(String(describing: error))")
            throw MLSWelcomeMessageProcessingError.failedToProcessMessage
        }
    }

}

public enum MLSWelcomeMessageProcessingError: Error {
    case failedToConvertMessageToBytes
    case failedToProcessMessage
}
