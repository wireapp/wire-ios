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

import WireProtos

extension CommitBundle {
    func protobufData() throws -> Data {
        return try Mls_CommitBundle(commitBundle: self).serializedData()
    }
}

extension Mls_CommitBundle {
    init(commitBundle: CommitBundle) {
        self = Mls_CommitBundle.with {
            $0.commit = commitBundle.commit.data
            $0.groupInfoBundle = Mls_GroupInfoBundle(
                publicGroupState: commitBundle.publicGroupState
            )

            if let welcome = commitBundle.welcome {
                $0.welcome = welcome.data
            }
        }
    }
}

extension Mls_GroupInfoBundle {
    init(publicGroupState: PublicGroupStateBundle) {
        self = Mls_GroupInfoBundle.with {
            $0.groupInfo = publicGroupState.payload.data
            $0.groupInfoType = Mls_GroupInfoType(encryptionType: publicGroupState.encryptionType)
            $0.ratchetTreeType = Mls_RatchetTreeType(ratchetTreeType: publicGroupState.ratchetTreeType)
        }
    }
}

extension Mls_GroupInfoType {
    init(encryptionType: PublicGroupStateEncryptionType) {
        switch encryptionType {
        case .Plaintext:
            self = .publicGroupState
        case .JweEncrypted:
            assertionFailure("JweEncrypted is not supported yet")
            self = .publicGroupState
        }
    }
}

extension Mls_RatchetTreeType {
    init(ratchetTreeType: RatchetTreeType) {
        switch ratchetTreeType {
        case .Full:
            self = .full
        case .Delta:
            self = .delta
        case .ByRef:
            self = .reference
        }
    }
}
