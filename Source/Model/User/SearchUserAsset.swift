//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


public enum SearchUserAsset: ExpressibleByNilLiteral, Hashable {
    case none
    case legacyId(UUID)
    case assetKey(String)

    public init(nilLiteral: ()) {
        self = .none
    }

    public var hashValue: Int {
        switch self {
        case .none: return 0
        case .legacyId(let id): return id.hashValue
        case .assetKey(let key): return key.hashValue
        }
    }

    public func objcCompatibilityValue() -> SearchUserAssetObjC? {
        return SearchUserAssetObjC(asset: self)
    }
}


public func ==(lhs: SearchUserAsset, rhs: SearchUserAsset) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none): return true
    case (.legacyId(let leftId), .legacyId(let rightId)): return leftId == rightId
    case (.assetKey(let leftKey), .assetKey(let rightKey)): return leftKey == rightKey
    default: return false
    }
}


@objcMembers public class SearchUserAssetObjC: NSObject {
    public let internalAsset: SearchUserAsset

    @objc public var legacyID: UUID? {
        get {
            switch internalAsset {
            case .legacyId(let id): return id
            default: return nil
            }
        }
    }

    @objc public var assetKey: String? {
        get {
            switch internalAsset {
            case .assetKey(let key): return key
            default: return nil
            }
        }
    }

    public init(legacyId: UUID) {
        internalAsset = .legacyId(legacyId)
    }

    public init(assetKey: String) {
        internalAsset = .assetKey(assetKey)
    }

    fileprivate init?(asset: SearchUserAsset) {
        if .none == asset { return nil }
        internalAsset = asset
    }
}
