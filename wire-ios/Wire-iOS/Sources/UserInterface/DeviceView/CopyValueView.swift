//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

protocol CopyActionHandler {
    func copy(_ value: String)
}

struct CopyValueView: View {
    var title: String
    var value: String
    var isCopyEnabled: Bool = true

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(UIFont.smallSemiboldFont.swiftUIfont)
            HStack {
                Text(value).font(Font.custom("SF Mono", size: 16))
                if isCopyEnabled {
                    Spacer()
                    VStack {
                        SwiftUI.Button(action: copy, label: {
                            Image(.copy)
                        })
                        Spacer()
                    }
                }
            }
        }
    }

    func copy() {
        UIPasteboard.general.string = value
    }
}

#Preview {
    CopyValueView(title: "Lorem ipsum dolem", value: "no data now")
}
