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

import GenericMessageProtocol
import WireDataModel
import WireLogging

// sourcery: AutoMockable
public protocol AssetTransferStateResolverProtocol {

    /// Resolves the asset message's transfer state
    ///
    /// - Parameters:
    ///   - assetMessage: message to resolve
    ///   - genericMessage: the generic message for the asset message
    ///   - context: the managed object context

    func resolveTransferState(
        assetMessage: ZMAssetClientMessage,
        genericMessage: GenericMessage,
        context: NSManagedObjectContext
    )
}

public struct AssetTransferStateResolver: AssetTransferStateResolverProtocol {

    public init() {}

    public func resolveTransferState(
        assetMessage: ZMAssetClientMessage,
        genericMessage: GenericMessage,
        context: NSManagedObjectContext
    ) {
        guard let assetData = genericMessage.assetData, let status = assetData.status else {
            WireLogger.assets.warn(
                "[WPB-28386] resolveTransferState: no assetData/status, nonce=\(assetMessage.nonce?.uuidString ?? "nil") - transferState left at \(assetMessage.transferState.rawValue)"
            )
            return
        }

        WireLogger.assets.info(
            "[WPB-28386] resolveTransferState: nonce=\(assetMessage.nonce?.uuidString ?? "nil") hasOriginal=\(assetData.hasOriginal) hasPreview=\(assetData.hasPreview) hasUploaded=\(assetData.hasUploaded) status=\(status)"
        )

        switch status {
        case let .uploaded(data) where data.hasAssetID:
            assetMessage.updateTransferState(
                .uploaded,
                synchronize: false
            )

        case .notUploaded where assetMessage.transferState != .uploaded:
            switch assetData.notUploaded {
            case .cancelled:
                context.delete(assetMessage)
            case .failed:
                assetMessage.updateTransferState(
                    .uploadingFailed,
                    synchronize: false
                )
            }

        default:
            WireLogger.assets.warn(
                "[WPB-28386] resolveTransferState: unhandled status branch for nonce=\(assetMessage.nonce?.uuidString ?? "nil"), transferState left at \(assetMessage.transferState.rawValue)"
            )
        }
    }

}
