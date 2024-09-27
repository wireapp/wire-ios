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

import SwiftUI
import WireCommonComponents
import WireDesign

struct CopyValueView: View {
    // MARK: Internal

    let title: String
    let value: String
    let isCopyEnabled: Bool
    let performCopy: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(FontSpec.smallSemiboldFont.swiftUIFont)
                .foregroundColor(Color(uiColor: SemanticColors.Label.textSectionHeader))
                .padding(.bottom, ViewConstants.Padding.small)

            HStack {
                Text(value)
                    .font(FontSpec.normalRegularFont.swiftUIFont.monospaced())
                Spacer()

                if isCopyEnabled {
                    VStack {
                        Button(action: copy) {
                            Image(.copy)
                                .renderingMode(.template)
                                .foregroundColor(Color(uiColor: SemanticColors.Icon.foregroundDefaultBlack))
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: Private

    private func copy() {
        performCopy?(value)
    }
}
