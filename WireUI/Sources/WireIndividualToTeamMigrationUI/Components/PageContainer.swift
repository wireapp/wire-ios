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
import WireDesign
import WireFoundation

struct PageContainer<Content: View>: View {
    private let content: Content

    private let step: Int
    private let stepCount: Int
    private let stepTitle: String

    init(
        @ViewBuilder content: () -> Content,
        step: Int,
        stepCount: Int,
        stepTitle: String
    ) {
        self.content = content()
        self.step = step
        self.stepCount = stepCount
        self.stepTitle = stepTitle
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack {
                    Text(String.formated(key: "individualToTeam.progressCount", bundle: .module, step, stepCount))
                        .wireTextStyle(.subline1)
                        .foregroundStyle(Color(uiColor: ColorTheme.Base.secondaryText))
                    Spacer()
                        .frame(height: 12)
                    Text(stepTitle)
                        .wireTextStyle(.h2)
                    Spacer(minLength: 36)
                    content
                }
                .padding(.horizontal, 16)
                // Ensure there is a minimum of 16 points space to the bottom of the screen.
                .padding(.bottom, max(16 - proxy.safeAreaInsets.bottom, 0))
                .frame(
                    minHeight: proxy.size.height
                )
            }
            .scrollIndicators(.hidden)
        }
    }
}
