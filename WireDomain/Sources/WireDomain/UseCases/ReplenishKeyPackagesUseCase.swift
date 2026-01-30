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
import WireCoreCrypto
import WireDataModel
import WireLogging
import WireNetwork

/// Replenishes MLS key packages on the backend when the unclaimed count falls below threshold.
///
/// Key packages are only replenished if:
/// - More than 24 hours have passed since the last check for the given ciphersuite, OR
/// - The estimated local key package count is below the minimum threshold (half of target)
/// - AND the unclaimed remote count is below the minimum threshold
// sourcery: AutoMockable
public protocol ReplenishKeyPackagesUseCaseProtocol {

    /// Replenish key packages for a specific ciphersuite if needed.
    ///
    /// - Parameter ciphersuite: The MLS ciphersuite to replenish key packages for.
    ///
    func invoke(ciphersuite: WireDataModel.MLSCipherSuite) async

}

/// Manages the replenishment of MLS key packages on the backend for a specific ciphersuite.
///
/// This use case ensures that there are always enough unclaimed key packages available
/// on the backend for establishing new MLS conversations. It intelligently decides when
/// to generate and upload new key packages based on:
/// - Time since last check (24 hour threshold)
/// - Local key package estimates from CoreCrypto
/// - Remote unclaimed key package counts from the backend
///
/// The use case tracks the last check time per ciphersuite in the journal to prevent
/// excessive API calls, only querying the backend when necessary.
///
public final class ReplenishKeyPackagesUseCase: ReplenishKeyPackagesUseCaseProtocol {

    // MARK: - Properties

    private let clientID: String
    private let targetCount: Int
    private let minimumCount: Int
    private let coreCrypto: SafeCoreCryptoProtocol
    private let mlsAPI: MLSAPI
    private let journal: any JournalProtocol
    private let logger = WireLogger.mls

    // MARK: - Life cycle

    /// Creates a new key package replenishment use case.
    ///
    /// - Parameters:
    ///   - clientID: The client ID to replenish key packages for.
    ///   - targetCount: The target number of unclaimed key packages to maintain on the backend.
    ///                  The minimum threshold is automatically set to half of this value.
    ///   - coreCrypto: The CoreCrypto instance for generating key packages and checking local counts.
    ///   - mlsAPI: The MLS API instance for counting and uploading key packages.
    ///   - journal: The journal for persisting the last check time per ciphersuite.
    ///
    public init(
        clientID: String,
        targetCount: Int,
        coreCrypto: SafeCoreCryptoProtocol,
        mlsAPI: MLSAPI,
        journal: any JournalProtocol
    ) {
        self.clientID = clientID
        self.targetCount = targetCount
        minimumCount = targetCount / 2
        self.coreCrypto = coreCrypto
        self.mlsAPI = mlsAPI
        self.journal = journal
    }

    // MARK: - Methods

    public func invoke(ciphersuite: WireDataModel.MLSCipherSuite) async {
        logger.info("checking if need to replenish key packages")
        guard await shouldReplenishKeyPackages(for: ciphersuite) else {
            logger.info("no need to replenish key packages")
            return
        }

        do {
            let keypackageCount = try await countKeyPackages(for: ciphersuite)
            updateLastCheckDate(for: ciphersuite)
            logger.info("there are \(keypackageCount) unclaimed key packages")

            guard keypackageCount <= minimumCount else {
                logger.info("no need to replenish key packages yet")
                return
            }

            let amount = max(0, targetCount - keypackageCount)
            let keyPackages = try await generateKeyPackages(amountRequested: UInt32(amount), for: ciphersuite)
            try await uploadKeyPackages(keyPackages: keyPackages)
            logger.info("successfully replenished key packages for client \(clientID)")
        } catch {
            logger.error("failed to replenish key packages for client \(clientID): \(String(describing: error))")
        }
    }

    // MARK: - Private

    private func shouldReplenishKeyPackages(for ciphersuite: WireDataModel.MLSCipherSuite) async -> Bool {
        if hoursSinceLastCheck(for: ciphersuite) > 24 {
            logger.info("last key package count is > 24h ago")
            return true
        } else {
            do {
                let estimatedCount = try await coreCrypto.perform {
                    try await $0.clientValidKeypackagesCount(
                        ciphersuite: ciphersuite.coreCryptoCipherSuite,
                        credentialType: .basic
                    )
                }

                if estimatedCount < minimumCount {
                    logger.info("estimated count is less than half of target")
                    return true
                }
            } catch {
                logger.warn("failed to estimate key package count: \(String(describing: error))")
                return true
            }
        }

        return false
    }

    private func hoursSinceLastCheck(for ciphersuite: WireDataModel.MLSCipherSuite) -> Int {
        let checkDates = journal[.lastKeyPackageCheckDates]
        guard let storedDate = checkDates.values[ciphersuite.rawValue] else {
            return .max
        }

        return Int(storedDate.timeIntervalSinceNow / .oneHour)
    }

    private func updateLastCheckDate(for ciphersuite: WireDataModel.MLSCipherSuite) {
        var checkDates = journal[.lastKeyPackageCheckDates]
        var updatedValues = checkDates.values
        updatedValues[ciphersuite.rawValue] = .now
        journal[.lastKeyPackageCheckDates] = KeyPackageCheckDates(values: updatedValues)
    }

    private func countKeyPackages(for ciphersuite: WireDataModel.MLSCipherSuite) async throws -> Int {
        do {
            return try await mlsAPI.countKeyPackages(
                clientID: clientID,
                ciphersuite: ciphersuite.toNetworkModel()
            )
        } catch {
            logger.warn("failed to count key packages: \(String(describing: error))")
            throw MLSKeyPackagesError.failedToCountUnclaimedKeyPackages
        }
    }

    private func generateKeyPackages(
        amountRequested: UInt32,
        for ciphersuite: WireDataModel.MLSCipherSuite
    ) async throws -> [String] {
        logger.info("generating \(amountRequested) key packages")
        var keyPackages = [WireCoreCryptoUniffi.KeyPackage]()

        do {
            keyPackages = try await coreCrypto.perform {
                let e2eiIsEnabled = try await $0.e2eiIsEnabled(
                    ciphersuite: ciphersuite.coreCryptoCipherSuite
                )
                return try await $0.clientKeypackages(
                    ciphersuite: ciphersuite.coreCryptoCipherSuite,
                    credentialType: e2eiIsEnabled ? .x509 : .basic,
                    amountRequested: amountRequested
                )
            }
        } catch {
            logger.warn("failed to generate new key packages: \(String(describing: error))")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        if keyPackages.isEmpty {
            logger.warn("CoreCrypto generated empty key packages array")
            throw MLSKeyPackagesError.failedToGenerateKeyPackages
        }

        return keyPackages.map {
            $0.copyBytes().base64EncodedString()
        }
    }

    private func uploadKeyPackages(keyPackages: [String]) async throws {
        do {
            let keyPackageUpload = KeyPackageUpload(
                keyPackages: keyPackages.map {
                    KeyPackage(base64EncodedData: $0)
                }
            )
            try await mlsAPI.uploadKeyPackages(
                clientID: clientID,
                keyPackages: keyPackageUpload
            )
        } catch {
            logger.warn("failed to upload key packages for client (\(clientID)): \(String(describing: error))")
            throw MLSKeyPackagesError.failedToUploadKeyPackages
        }
    }
}

// MARK: - Errors

/// Errors that can occur during key package replenishment.
enum MLSKeyPackagesError: Error {

    /// Failed to generate new key packages from CoreCrypto.
    case failedToGenerateKeyPackages

    /// Failed to upload key packages to the backend.
    case failedToUploadKeyPackages

    /// Failed to count unclaimed key packages from the backend.
    case failedToCountUnclaimedKeyPackages

}

// MARK: - Extensions

extension WireDataModel.MLSCipherSuite {

    func toNetworkModel() -> WireNetwork.MLSCipherSuite {
        switch self {
        case .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519:
            .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519
        case .MLS_128_DHKEMP256_AES128GCM_SHA256_P256:
            .MLS_128_DHKEMP256_AES128GCM_SHA256_P256
        case .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519:
            .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519
        case .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448:
            .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448
        case .MLS_256_DHKEMP521_AES256GCM_SHA512_P521:
            .MLS_256_DHKEMP521_AES256GCM_SHA512_P521
        case .MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448:
            .MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448
        case .MLS_256_DHKEMP384_AES256GCM_SHA384_P384:
            .MLS_256_DHKEMP384_AES256GCM_SHA384_P384
        }
    }

}
