//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import SwiftUI

struct UploadImagePreview: View {
    let image: Image
    let onRemove: @Sendable () -> Void

    init(image: Image, onRemove: @escaping @Sendable () -> Void) {
        self.onRemove = onRemove
        self.image = image
    }

    var body: some View {
        LocalImagePreview(image: image)
            .deleteItemButton(onRemove: onRemove)
    }
}

public struct UploadImagePreview_Preview: View {
    let demoImageName: String

    public init(demoImageName: String) {
        self.demoImageName = demoImageName
    }

    public var body: some View {
        UploadImagePreview(image: Image(demoImageName, bundle: .module)) {
            print("remove")
        }
    }

}

#Preview {
    VStack {
        UploadImagePreview_Preview(demoImageName: "rectangular-placeholder")
            .frame(width: 200, height: 200)
            .background(.white)
    }
    .background(.black)
}
