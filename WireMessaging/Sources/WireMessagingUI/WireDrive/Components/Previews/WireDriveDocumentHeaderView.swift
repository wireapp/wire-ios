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

import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct WireDriveDocumentHeaderView: View {
    enum Constants {
        static let errorColor = ColorTheme.Base.error.color
        static let headerIconSize: CGFloat = 16
    }

    @ScaledMetric private var readyToOpenIconPadding: CGFloat = 3.8
    @ScaledMetric private var scale: CGFloat = 1
    @Environment(\.wireAccentColor) private var wireAccentColor

    var iconSize: CGSize {
        .init(width: Constants.headerIconSize * scale, height: Constants.headerIconSize * scale)
    }

    let headerIcon: Image
    let headerText: String
    let labelText: String
    let isDraftPreview: Bool
    let state: WireDriveFileUITracker.State
    var minHeight: CGFloat?
    let isAvailableOffline: Bool

    var body: some View {
        header()
    }

    @ViewBuilder
    private func header() -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                stateIconView()

                Text(headerText)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    .font(for: .subline1)
                    .lineLimit(1)
                    .layoutPriority(1)

                if isAvailableOffline { availableOfflineIcon() }

                Spacer()

                if !isDraftPreview {
                    stateTextView()
                        .foregroundStyle(isError ? ColorTheme.Base.error.color : ColorTheme.Base.secondaryText.color)
                        .font(for: .subline1)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)

            ZStack(alignment: .bottom) {
                Group {
                    Text(labelText)
                    reservedSpaceFor2LinesOfText()
                }
                .foregroundStyle(ColorTheme.Backgrounds.onSurfaceVariant.color)
                .font(for: .h5)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.horizontal, .bottom], 8)
            }
        }
        .frame(minHeight: minHeight)
    }

    /// Reserving a minimum amout of space for 2 lines of text.
    /// `.minimumScaleFactor(0.5)` allows the reserved space to shrink for the draft version,
    /// which has height restrictions and truncates the line instead of breaking into multiple lines.
    @ViewBuilder
    private func reservedSpaceFor2LinesOfText() -> some View {
        Text("\n")
            .minimumScaleFactor(0.5)
            .hidden()
            .accessibilityHidden(true)
    }

    private var isError: Bool {
        switch state {
        case .failed:
            true
        default:
            false
        }
    }

    @ViewBuilder
    private func stateTextView() -> some View {
        switch state {
        case let .loaded(showReadyToOpen):
            if showReadyToOpen {
                Text(Strings.Files.readyToOpenAfterDownload)
                    .minimumScaleFactor(0.5)
            } else {
                EmptyView()
            }
        case .failed:
            Text(Strings.Files.downloadFailed)
                .minimumScaleFactor(0.5)
        case .notLoaded:
            EmptyView()
        case .loading:
            Text(Strings.Files.tapToCancelDownload)
                .minimumScaleFactor(0.5)
        }
    }

    @ViewBuilder
    private func progressView(progress: Double) -> some View {
        ProgressView(value: progress)
            .progressViewStyle(.wireDriveAsset())
            .frame(width: iconSize.width, height: iconSize.height)
    }

    @ViewBuilder
    private func stateIconView() -> some View {
        switch state {
        case let .loaded(showReadyToOpen):
            if showReadyToOpen {
                progressView(progress: 1)
                    .overlay {
                        Image(systemName: "checkmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .fontWeight(.black)
                            .foregroundStyle(.blue)
                            .padding(4 * scale)
                    }
            } else {
                headerIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize.width, height: iconSize.height)
            }
        case .failed:
            if isDraftPreview {
                Image(systemName: "exclamationmark.triangle")
                    .fontWeight(.semibold)
                    .font(.system(size: 14 * scale))
                    .foregroundStyle(Constants.errorColor)
                    .frame(width: iconSize.width, height: iconSize.height)
            } else {
                headerIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize.width, height: iconSize.height)
            }
        case .notLoaded:
            headerIcon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize.width, height: iconSize.height)
        case let .loading(progress, _):
            progressView(progress: progress)
        }
    }

    @ViewBuilder
    private func availableOfflineIcon() -> some View {
        Image(systemName: "arrow.down.circle.fill")
            .resizable()
            .frame(width: 12 * scale, height: 11 + scale)
            .foregroundStyle(ColorTheme.Base.secondaryText.color)
            .accessibilityLabel(Accessibility.Files.availableOffline)
    }
}

#Preview {
    let headerIcon = Image(WireDriveFileType.pdf.imageResource)
    let headerText = "PDF (336 KB)"
    let labelText = "CDR_20220120 Accessibility Review Reviewed Final Plus"
    let labelTextShort = "Filename"

    ScrollView {
        VStack {
            Group {
                WireDriveDocumentHeaderView(
                    headerIcon: headerIcon,
                    headerText: headerText,
                    labelText: labelText,
                    isDraftPreview: false,
                    state: .loading(progress: 0.7, isLargeFile: false),
                    isAvailableOffline: false
                )

                WireDriveDocumentHeaderView(
                    headerIcon: headerIcon,
                    headerText: headerText,
                    labelText: labelText,
                    isDraftPreview: false,
                    state: .loaded(showReadyToOpen: true),
                    isAvailableOffline: true
                )

                WireDriveDocumentHeaderView(
                    headerIcon: headerIcon,
                    headerText: headerText,
                    labelText: labelText,
                    isDraftPreview: false,
                    state: .notLoaded,
                    isAvailableOffline: false
                )

                WireDriveDocumentHeaderView(
                    headerIcon: headerIcon,
                    headerText: headerText,
                    labelText: labelText,
                    isDraftPreview: false,
                    state: .failed,
                    isAvailableOffline: false
                )

                WireDriveDocumentHeaderView(
                    headerIcon: headerIcon,
                    headerText: headerText,
                    labelText: labelText,
                    isDraftPreview: true,
                    state: .failed,
                    isAvailableOffline: false
                )

                WireDriveDocumentHeaderView(
                    headerIcon: headerIcon,
                    headerText: headerText,
                    labelText: labelTextShort,
                    isDraftPreview: true,
                    state: .failed,
                    isAvailableOffline: false
                )
            }
            .background(.background)
            .frame(width: 200)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    .background(.gray)
}
