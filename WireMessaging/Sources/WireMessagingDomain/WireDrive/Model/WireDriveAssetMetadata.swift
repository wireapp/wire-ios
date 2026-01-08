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

public import Foundation

public enum WireDriveAssetMetadata: Equatable, Hashable, Sendable {
    case image(width: Int, height: Int)
    case video(width: Int?, height: Int?, durationMs: Int64?)
    case audio(durationMs: Int64?, normalizedLoudness: Data?)

    public var width: Int? {
        switch self {
        case let .image(width, _), let .video(width?, _, _):
            width
        case .video, .audio:
            nil
        }
    }

    public var height: Int? {
        switch self {
        case let .image(_, height), let .video(_, height?, _):
            height
        case .video, .audio:
            nil
        }
    }

    public var durationMs: Int64? {
        switch self {
        case .image:
            nil
        case let .video(_, _, durationMs), let .audio(durationMs, _):
            durationMs
        }
    }
}
