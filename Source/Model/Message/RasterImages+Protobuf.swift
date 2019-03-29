//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

public extension ZMAssetOriginal {
    var hasRasterImage: Bool {
        return hasImage() && UTType(mimeType: mimeType)?.isSVG == false
    }
}

fileprivate extension ZMImageAsset {
    var isRaster: Bool {
        return UTType(mimeType: mimeType)?.isSVG == false
    }
}

public extension ZMGenericMessage {
    var hasRasterImage: Bool {
        return hasImage() && image.isRaster
    }
}

public extension ZMEphemeral {
    var hasRasterImage: Bool {
        return hasImage() && image.isRaster
    }
}

