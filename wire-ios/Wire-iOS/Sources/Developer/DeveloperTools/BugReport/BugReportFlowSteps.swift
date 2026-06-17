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

import AVFoundation
import AVKit
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import WireDataModel

private typealias L = L10n.Localizable.BugReport

// MARK: - Page 1: Description

struct BugReportDescriptionStep: View {

    @ObservedObject var model: BugReportFlowModel

    var body: some View {
        BugReportStepScaffold(stepIndex: 1, title: L.Description.title, model: model) {
            Section {
                TextField(L.Description.Summary.placeholder, text: $model.summary, axis: .vertical)
                    .accessibilityIdentifier("bugReport.summary")
            } header: {
                Text(L.Description.Summary.header)
            } footer: {
                Text(L.Description.Summary.footer)
            }

            Section(L.Description.ExpectedBehavior.header) {
                TextField(L.Description.ExpectedBehavior.placeholder, text: $model.expectedBehavior, axis: .vertical)
            }

            Section(L.Description.ActualBehavior.header) {
                TextField(L.Description.ActualBehavior.placeholder, text: $model.actualBehavior, axis: .vertical)
            }

            Section {
                DatePicker(
                    L.Description.Timeframe.label,
                    selection: $model.timeframe,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
            } header: {
                Text(L.Description.Timeframe.header)
            } footer: {
                Text(L.Description.Timeframe.footer)
            }

            BugReportNextLink(isEnabled: model.canSubmit) {
                BugReportReproductionStep(model: model)
            }
        }
    }
}

// MARK: - Page 2: Reproduction

struct BugReportReproductionStep: View {

    @ObservedObject var model: BugReportFlowModel

    var body: some View {
        BugReportStepScaffold(stepIndex: 2, title: L.Reproduction.title, model: model) {
            Section {
                TextField(L.Reproduction.Steps.placeholder, text: $model.stepsToReproduce, axis: .vertical)
                    .lineLimit(3...10)
            } header: {
                Text(L.Reproduction.Steps.header)
            } footer: {
                Text(L.Reproduction.Steps.footer)
            }

            Section(L.Reproduction.Reproducibility.header) {
                Picker(L.Reproduction.Reproducibility.header, selection: $model.reproducibility) {
                    ForEach(Reproducibility.allCases) { Text($0.label).tag($0) }
                }
            }

            Section(L.Reproduction.Workaround.header) {
                Picker(L.Reproduction.Workaround.header, selection: $model.workaroundStatus) {
                    ForEach(WorkaroundStatus.allCases) { Text($0.label).tag($0) }
                }
                if model.workaroundStatus == .yes {
                    TextField(L.Reproduction.Workaround.placeholder, text: $model.workaroundDetail, axis: .vertical)
                }
            }

            BugReportNextLink(isEnabled: true) {
                BugReportClassificationStep(model: model)
            }
        }
    }
}

// MARK: - Page 3: Classification

struct BugReportClassificationStep: View {

    @ObservedObject var model: BugReportFlowModel

    var body: some View {
        BugReportStepScaffold(stepIndex: 3, title: L.Classification.title, model: model) {
            Section(L.Classification.Impact.header) {
                ForEach(BugImpact.allCases) { option in
                    Button {
                        model.impact = option
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: model.impact == option ? "circle.inset.filled" : "circle")
                                .foregroundStyle(model.impact == option ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.label)
                                    .foregroundStyle(.primary)
                                Text(option.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section(L.Classification.Severity.header) {
                ForEach(BugSeverity.allCases) { option in
                    Button {
                        model.severity = option
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: model.severity == option ? "circle.inset.filled" : "circle")
                                .foregroundStyle(model.severity == option ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.label)
                                    .foregroundStyle(.primary)
                                Text(option.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                Picker(L.Classification.Regression.header, selection: $model.regression) {
                    ForEach(TriState.allCases) { Text($0.label).tag($0) }
                }
                if model.regression == .yes {
                    TextField(L.Classification.LastWorkingVersion.placeholder, text: $model.lastKnownWorkingVersion)
                }
            } header: {
                Text(L.Classification.Regression.header)
            } footer: {
                Text(L.Classification.Regression.footer)
            }

            BugReportNextLink(isEnabled: model.canProceedFromClassification) {
                BugReportEvidenceStep(model: model)
            }
        }
    }
}

// MARK: - Page 4: Evidence & notes

struct BugReportEvidenceStep: View {

    @ObservedObject var model: BugReportFlowModel
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var fullscreenAttachment: BugReportAttachment?

    var body: some View {
        BugReportStepScaffold(stepIndex: 4, title: L.Evidence.title, model: model) {
            Section {
                PhotosPicker(selection: $pickerItems, maxSelectionCount: 5, matching: .any(of: [.images, .videos])) {
                    Label(L.Evidence.Screenshots.button, systemImage: "photo.on.rectangle")
                }
                .accessibilityIdentifier("bugReport.addScreenshots")

                if !model.attachments.isEmpty {
                    AttachmentCarousel(attachments: model.attachments, onTap: { fullscreenAttachment = $0 })
                }
            } header: {
                Text(L.Evidence.Screenshots.header)
            }

            Section(L.Evidence.RelatedReports.header) {
                TextField(L.Evidence.RelatedReports.placeholder, text: $model.relatedReports, axis: .vertical)
            }

            Section(L.Evidence.OtherContext.header) {
                TextField(L.Evidence.OtherContext.placeholder, text: $model.additionalNotes, axis: .vertical)
            }

            BugReportNextLink(isEnabled: true) {
                BugReportReviewStep(model: model)
            }
        }
        .onChange(of: pickerItems) { items in
            Task { await loadAttachments(items) }
        }
        .fullScreenCover(item: $fullscreenAttachment) { attachment in
            AttachmentFullscreenView(attachment: attachment)
        }
    }

    private func loadAttachments(_ items: [PhotosPickerItem]) async {
        var loaded: [BugReportAttachment] = []
        var imageIndex = 1
        var videoIndex = 1
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            guard data.count <= bugReportMaxAttachmentSize else { continue }
            let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .audiovisualContent) })
            let thumbnailData = isVideo ? await videoThumbnail(from: data) : nil
            let filename = isVideo ? "recording-\(videoIndex).mp4" : "screenshot-\(imageIndex).png"
            loaded.append(BugReportAttachment(filename: filename, data: data, isVideo: isVideo, thumbnailData: thumbnailData))
            if isVideo { videoIndex += 1 } else { imageIndex += 1 }
        }
        model.attachments = loaded
    }

    private func videoThumbnail(from data: Data) async -> Data? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mp4")
        guard (try? data.write(to: tempURL)) != nil else { return nil }
        defer { try? FileManager.default.removeItem(at: tempURL) }
        let asset = AVURLAsset(url: tempURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        guard let (cgImage, _) = try? await generator.image(at: .zero) else { return nil }
        return UIImage(cgImage: cgImage).pngData()
    }
}

// MARK: - Page 5: Review & send

struct BugReportReviewStep: View {

    @ObservedObject var model: BugReportFlowModel
    @State private var fullscreenAttachment: BugReportAttachment?

    var body: some View {
        BugReportStepScaffold(stepIndex: 5, title: L.Review.title, model: model) {
            Section(L.Review.Description.header) {
                reviewRow(L.Review.Field.summary, model.summary)
                reviewRow(L.Review.Field.expected, model.expectedBehavior)
                reviewRow(L.Review.Field.actual, model.actualBehavior)
                reviewRow(L.Review.Field.timeframe, model.timeframe.formatted())
            }

            Section(L.Review.Reproduction.header) {
                reviewRow(L.Review.Field.steps, model.stepsToReproduce)
                reviewRow(L.Review.Field.reproducibility, model.reproducibility.label)
            }

            Section(L.Review.Classification.header) {
                reviewRow(L.Review.Field.impact, model.impact?.label ?? "")
                reviewRow(L.Review.Field.severity, model.severity?.label ?? "")
                reviewRow(L.Review.Field.regression, model.regression.label)
                if model.regression == .yes {
                    reviewRow(L.Review.Field.lastWorkingVersion, model.lastKnownWorkingVersion)
                }
            }

            if !model.attachments.isEmpty {
                Section(L.Review.Screenshots.header) {
                    AttachmentCarousel(attachments: model.attachments, onTap: { fullscreenAttachment = $0 })
                }
            }

            Section {
                Label(L.Review.autoInfo, systemImage: "checkmark.seal")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                NavigationLink {
                    BugReportConversationPickerView(model: model)
                } label: {
                    Text(L.Review.sendInWire)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("bugReport.sendInWire")

                Button {
                    Task { await model.shareViaActivitySheet() }
                } label: {
                    Text(L.Review.share).frame(maxWidth: .infinity)
                }
                .disabled(model.isSubmitting)
            } footer: {
                Text(L.Review.sendFooter)
            }
        }
        .alert(
            L.Error.title,
            isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })
        ) {
            Button(L.Error.ok, role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .fullScreenCover(item: $fullscreenAttachment) { attachment in
            AttachmentFullscreenView(attachment: attachment)
        }
    }

    @ViewBuilder
    private func reviewRow(_ title: String, _ value: String) -> some View {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(trimmed.isEmpty ? "—" : trimmed)
        }
    }
}

// MARK: - Shared attachment carousel

struct AttachmentCarousel: View {
    let attachments: [BugReportAttachment]
    let onTap: (BugReportAttachment) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments) { attachment in
                    Button { onTap(attachment) } label: {
                        ZStack(alignment: .bottomTrailing) {
                            if let thumbnail = attachment.thumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color.secondary.opacity(0.2)
                            }
                            if attachment.isVideo {
                                Image(systemName: "play.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2)
                                    .padding(4)
                            }
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Fullscreen attachment viewer

struct AttachmentFullscreenView: View {

    let attachment: BugReportAttachment
    @Environment(\.dismiss) private var dismiss
    @State private var videoURL: URL?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if attachment.isVideo {
                if let url = videoURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        .ignoresSafeArea()
                } else {
                    ProgressView().tint(.white)
                }
            } else if let image = attachment.thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.black.opacity(0.4))
                    .padding()
            }
        }
        .task {
            guard attachment.isVideo else { return }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(attachment.id.uuidString + ".mp4")
            try? attachment.data.write(to: url)
            videoURL = url
        }
    }
}

// MARK: - Conversation picker

private typealias LP = L10n.Localizable.BugReport.ConversationPicker

struct BugReportConversationPickerView: View {

    @ObservedObject var model: BugReportFlowModel
    @State private var searchText = ""
    @State private var selectedConversation: ZMConversation?

    private var filtered: [ZMConversation] {
        guard !searchText.isEmpty else { return model.conversations }
        return model.conversations.filter {
            $0.displayNameWithFallback.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                if filtered.isEmpty {
                    Text(LP.noResults)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
                ForEach(filtered, id: \.objectID) { conversation in
                    Button {
                        selectedConversation = conversation
                    } label: {
                        HStack(spacing: 12) {
                            ConversationInitialsView(name: conversation.displayNameWithFallback)
                                .frame(width: 40, height: 40)

                            Text(conversation.displayNameWithFallback)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: selectedConversation == conversation
                                  ? "circle.inset.filled" : "circle")
                                .foregroundStyle(selectedConversation == conversation
                                                 ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $searchText)

            Divider()

            Button {
                guard let conversation = selectedConversation else { return }
                Task { await model.submitViaWire(to: conversation) }
            } label: {
                HStack(spacing: 8) {
                    if model.isSubmitting { ProgressView() }
                    Text(LP.send).fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedConversation == nil || model.isSubmitting)
            .padding()
        }
        .navigationTitle(LP.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.loadConversations() }
        .alert(
            L10n.Localizable.BugReport.Error.title,
            isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })
        ) {
            Button(L10n.Localizable.BugReport.Error.ok, role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

// MARK: - Conversation avatar

private struct ConversationInitialsView: View {
    let name: String

    var body: some View {
        Circle()
            .fill(.tint.opacity(0.15))
            .overlay {
                Text(String(name.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundStyle(.tint)
            }
    }
}
