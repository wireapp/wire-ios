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

package import Foundation

package extension WireDriveNodeNetworkModel {

    /// The object metadata that tells the backend this upload creates a new draft node version.
    ///
    /// This is the single definition of the draft upload contract. It is shared by the streaming
    /// upload (`AWSClient.uploadRegular`, where it travels as `x-amz-meta-*` headers) and by the
    /// presigned upload used for background transfers (where the presigner folds it into
    /// `x-amz-meta-*` query items instead).

    func createDraftNodeMetadata(versionID: UUID) -> [String: String] {
        [
            "Draft-Mode": "true",
            "Create-Resource-UUID": uuid.transportString(),
            "Create-Version-ID": versionID.transportString()
        ]
    }

}
