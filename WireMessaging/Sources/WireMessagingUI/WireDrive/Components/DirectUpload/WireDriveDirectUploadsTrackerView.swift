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

package import SwiftUI
import WireDesign
import WireLocators
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells.Files.Upload
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells.Files.Upload

/// The Shared Drive uploads tracker, shown above the file list.
///
/// Collapsed it is a single pill; expanded it is a sheet listing every upload.
package struct WireDriveDirectUploadsTrackerView: View {

    @ObservedObject private var viewModel: WireDriveDirectUploadsViewModel

    package init(viewModel: WireDriveDirectUploadsViewModel) {
        self.viewModel = viewModel
    }

    package var body: some View {
        Group {
            switch viewModel.presentation {
            case .hidden:
                EmptyView()
            case .pill, .sheet:
                pill
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.presentation)
        .sheet(isPresented: isSheetPresented) {
            WireDriveDirectUploadsSheetView(viewModel: viewModel)
        }
    }

    private var isSheetPresented: Binding<Bool> {
        Binding(
            get: { viewModel.presentation == .sheet },
            set: { isPresented in
                if isPresented {
                    viewModel.expand()
                } else if viewModel.presentation == .sheet {
                    viewModel.collapse()
                }
            }
        )
    }

    private var pill: some View {
        Button {
            viewModel.expand()
        } label: {
            HStack(spacing: 12) {
                WireDriveDirectUploadStatusIcon(
                    status: viewModel.summary.activeCount > 0
                        ? .progress(viewModel.summary.overallProgress)
                        : (viewModel.isFailureState ? .failure : .done)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.title)
                        .font(for: .body2)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                    Text(viewModel.isFailureState ? Strings.tapToReview : viewModel.subtitle)
                        .font(for: .subline1)
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(for: .subline1)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(ColorTheme.Backgrounds.surface.color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.title), \(viewModel.subtitle)")
        .accessibilityHint(Accessibility.expand)
        .accessibilityIdentifier(Locators.WireDrive.UploadsPage.pill)
    }
}

struct WireDriveDirectUploadStatusIcon: View {

    enum Status {

        /// An upload in flight, with a known fraction complete.
        case progress(Float)

        /// An upload that failed.
        case failure

        /// Nothing in flight and nothing failed.
        case done
    }

    let status: Status

    @ScaledMetric private var size: CGFloat = 24

    @Environment(\.wireAccentColor) private var accentColor

    var body: some View {
        ZStack {
            switch status {
            case .failure:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(ColorTheme.Base.error.color)
            case let .progress(value):
                ProgressView(value: Double(value))
                    .progressViewStyle(.wireDriveAsset())
                Image(systemName: "arrow.up")
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(ColorTheme.Base.primary(accentColor).color)
            case .done:
                Image(systemName: "checkmark.circle")
                    .font(.system(size: size))
                    .foregroundStyle(ColorTheme.Base.primary(accentColor).color)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview("uploading") {
    WireDriveDirectUploadsTrackerView(viewModel: .preview())
}

#Preview("all uploaded") {
    WireDriveDirectUploadsTrackerView(
        viewModel: .preview(
            items: [
                .preview(fileName: "a.pdf", status: .uploaded),
                .preview(fileName: "b.pdf", status: .uploaded)
            ]
        )
    )
}

#Preview("all failed") {
    WireDriveDirectUploadsTrackerView(
        viewModel: .preview(
            items: [
                .preview(fileName: "a.pdf", status: .failed(error: .unauthorized), isRetryable: true),
                .preview(fileName: "b.pdf", status: .failed(error: .unauthorized), isRetryable: true)
            ]
        )
    )
}
