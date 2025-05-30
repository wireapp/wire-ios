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

struct AccountTypeSelectionView: View {

    @Environment(\.dismiss) private var dismiss

    private typealias Strings = L10n.Localizable.AccountTypeSelector
    private typealias Labels = L10n.Accessibility.AccountTypeSelector

    var body: some View {
        NavigationStack {
            ScrollView {
                scrollViewContent
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetCloseButton {
                        dismiss()
                    }
                    .accessibilityLabel(Labels.Close.label)
                }
            }
        }
    }

    @ViewBuilder private var scrollViewContent: some View {
        VStack(spacing: 24) {
            teamAccountView
            personalAccountView
        }
    }

    // MARK: -

    @ViewBuilder private var teamAccountView: some View {
        let background = RoundedRectangle(cornerRadius: 24, style: .circular)
            .stroke(ColorTheme.Base.primary.color)
        VStack(spacing: 24) {
            teamAccountTitles
            teamAccountFeatures
            teamAccountButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    @ViewBuilder private var teamAccountTitles: some View {
        TitlesView(
            title: Strings.OptionTeam.title,
            subtitle: Strings.OptionTeam.subtitle
        )
    }

    @ViewBuilder private var teamAccountFeatures: some View {
        VStack(spacing: 12) {
            Divider()
            FeatureView(Strings.OptionTeam.feature0)
            Divider()
            FeatureView(Strings.OptionTeam.feature1)
            Divider()
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder private var teamAccountButton: some View {
        Button {
            print("[WPB-17525]") // TODO: [WPB-17525] implement flow
        } label: {
            Text(Strings.OptionTeam.button)
                .lineLimit(nil)
        }
        .wireButtonStyle(.primary)
        .bold()
    }

    // MARK: -

    @ViewBuilder private var personalAccountView: some View {
        let background = RoundedRectangle(cornerRadius: 24, style: .circular)
            .stroke(ColorTheme.Strokes.outline.color)
        VStack(spacing: 24) {
            personalAccountTitles
            personalAccountFeatures
            personalAccountButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    @ViewBuilder private var personalAccountTitles: some View {
        TitlesView(
            title: Strings.OptionPersonal.title,
            subtitle: Strings.OptionPersonal.subtitle
        )
    }

    @ViewBuilder private var personalAccountFeatures: some View {
        VStack(spacing: 12) {
            Divider()
            BulletTextView(text: "This is a sample text with a custom bullet image.", bulletImage: Image(systemName: "circle.fill"))
            Divider()
            FeatureView(Strings.OptionPersonal.feature0)
            Divider()
            FeatureView(Strings.OptionPersonal.feature1)
            Divider()
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder private var personalAccountButton: some View {
        Button {
            print("[WPB-17453]") // TODO: [WPB-17453] implement flow
        } label: {
            Text(Strings.OptionPersonal.button)
                .lineLimit(nil)
        }
        .wireButtonStyle(.secondary)
        .bold()
    }

}

// MARK: -

private struct TitlesView: View {

    var title: String
    var subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.callout.bold())
                .foregroundStyle(ColorTheme.Base.primary.color)
            Text(subtitle)
        }
    }

}

private struct FeatureView: View {

    var content: String

    init(_ content: String) {
        self.content = content
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {

            Image(systemName: "checkmark.circle.fill")

//            Image(.circleCheck)
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .foregroundStyle(ColorTheme.Base.positive.color)
//                .frame(height: UIFont.preferredFont(forTextStyle: .body).pointSize)
//                .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] + 5.5 }
//                .background(Color.red)

            ZStack {
                Text(verbatim: "o") // used to vertically align the image for large font sizes
                    .hidden()
                    .accessibilityHidden(true)
                Image(.circleCheck)
                    .resizable()
                    .background(Color.red)
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(ColorTheme.Base.positive.color)
                    .layoutPriority(-1)
            }
            Text(content)
            Spacer()
        }
    }

}

// MARK: -

#Preview {
    Spacer()
        .sheet(isPresented: .constant(true)) {
            AccountTypeSelectionView()
//                .dynamicTypeSize(.accessibility5)
        }
}



struct BulletTextView: View {
    let text: String
    let bulletImage: Image

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            bulletImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UIFont.preferredFont(forTextStyle: .body).pointSize * 0.8)
                .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] }

            Text(text)
                .font(.body) // or use `.font(.body).dynamicTypeSize(...)` if needed
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            BulletTextView(text: "This is a sample text with a custom bullet image.", bulletImage: Image(systemName: "circle.fill"))

            BulletTextView(text: "Another bullet point with a longer text that wraps to the next line and remains aligned.", bulletImage: Image(systemName: "star.fill"))
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .dynamicTypeSize(.accessibility4)
}
