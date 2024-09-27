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

extension WireProtos.Asset.Original {
    public var hasRasterImage: Bool {
        guard case .image? = metaData else {
            return false
        }

        guard let uti = UTIHelper.convertToUti(mime: mimeType) else { return false }

        return !UTIHelper.conformsToVectorType(uti: uti)
    }
}

extension ImageAsset {
    fileprivate var isRaster: Bool {
        !UTIHelper.conformsToVectorType(mime: mimeType)
    }
}

extension GenericMessage {
    public var hasRasterImage: Bool {
        guard let content else { return false }
        switch content {
        case let .image(data):
            return data.isRaster

        case let .ephemeral(data):
            switch data.content {
            case let .image(image)?:
                return image.isRaster
            default:
                return false
            }

        default:
            return false
        }
    }
}
