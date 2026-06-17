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

import PhotosUI
import SwiftUI

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
                                .foregroundStyle(model.impact == option ? .tint : .secondary)
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
                                .foregroundStyle(model.severity == option ? .tint : .secondary)
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

    var body: some View {
        BugReportStepScaffold(stepIndex: 4, title: L.Evidence.title, model: model) {
            Section {
                PhotosPicker(selection: $pickerItems, maxSelectionCount: 5, matching: .images) {
                    Label(L.Evidence.Screenshots.button, systemImage: "photo.on.rectangle")
                }
                .accessibilityIdentifier("bugReport.addScreenshots")

                if !model.attachments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(model.attachments) { attachment in
                                if let image = attachment.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
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
    }

    private func loadAttachments(_ items: [PhotosPickerItem]) async {
        var loaded: [BugReportAttachment] = []
        for (index, item) in items.enumerated() {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(BugReportAttachment(filename: "screenshot-\(index + 1).png", data: data))
            }
        }
        model.attachments = loaded
    }
}

// MARK: - Page 5: Review & send

struct BugReportReviewStep: View {

    @ObservedObject var model: BugReportFlowModel

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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(model.attachments) { attachment in
                                if let image = attachment.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
            }

            Section {
                Label(L.Review.autoInfo, systemImage: "checkmark.seal")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    Task { await model.submitViaWire() }
                } label: {
                    HStack {
                        if model.isSubmitting { ProgressView() }
                        Text(L.Review.sendInWire).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(model.isSubmitting)
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
