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
import WireMessagingDomain
import WireMessagingDomainSupport

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct TagsEditView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: ViewModel

    @FocusState private var isTextFieldFocused: Bool

    private let horizontalPadding: CGFloat = 16
    private let tagBubbleSpacing: CGFloat = 8

    struct UseCases {
        let updateTags: any WireCellsUpdateTagsUseCaseProtocol
        let getSuggestions: any WireCellsGetTagSuggestionsUseCaseProtocol
    }

    init(fileItem: FilesViewItem, useCases: UseCases, postSaveAction: @escaping () async -> Void) {
        _viewModel = .init(wrappedValue: .init(fileItem: fileItem, useCases: useCases, postSaveAction: postSaveAction))
    }

    var body: some View {
        NavigationStack {
            content()
                .navigationTitle(Text(Strings.Tags.title))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Text(L10n.Localizable.General.close)
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        if viewModel.isPerformingSave {
                            ProgressView()
                                .tint(Color.primary)
                        } else {
                            Button {
                                Task {
                                    isTextFieldFocused = false
                                    await viewModel.save()
                                }
                            } label: {
                                Text(L10n.Localizable.General.save)
                                    .bold()
                            }
                            .disabled(!viewModel.isSaveEnabled)
                        }
                    }

                    ToolbarItemGroup(placement: .keyboard) {
                        suggestedTagsList(viewModel.filteredSuggestedTags, withKeyboardStyle: true)
                            .animation(.easeInOut, value: viewModel.enteredTag)
                            .animation(.easeInOut, value: isTextFieldFocused)
                    }
                }
                .background {
                    ColorTheme.Backgrounds.background.color
                        .ignoresSafeArea(edges: .all)
                }
                .tint(ColorTheme.Base.primary.color)
                .alert(isPresented: $viewModel.isSaveErrorMessagePresented) {
                    Alert(
                        title: Text(Strings.Tags.Error.saveFailedTitle),
                        message: Text(Strings.Tags.Error.saveFailedMessage),
                        primaryButton: .default(Text(Strings.Tags.Error.retryButton)) {
                            if viewModel.isSaveEnabled {
                                Task {
                                    await viewModel.save()
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
                .onTapGesture {
                    isTextFieldFocused = false
                }
                .onReceive(viewModel.dismiss) {
                    dismiss()
                }
        }
    }

    @ViewBuilder
    private func content() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                normalText(Strings.Tags.headline)

                VStack(alignment: .leading, spacing: 10) {
                    addedTagsArea()

                    tagNameInputArea()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, horizontalPadding)
                .background(ColorTheme.Backgrounds.backgroundVariant.color)
                .padding(.horizontal, -horizontalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)

                tagNameValidationError()

                Spacer(minLength: 20)

                suggestedTagsArea()
                    .opacity(isTextFieldFocused ? 0 : 1)
                    .animation(.easeInOut, value: isTextFieldFocused)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical)
            .animation(.easeInOut, value: viewModel.enteredTag)
            .animation(.easeInOut, value: viewModel.suggestedTags)
        }
    }

    @ViewBuilder
    private func tagNameInputArea() -> some View {
        let prompt = Strings.Tags.textFieldPlaceholder
        TextField("", text: $viewModel.enteredTag, prompt: Text(prompt))
            .textFieldStyle(.plain)
            .textInputAutocapitalization(.never)
            .focused($isTextFieldFocused)
            .onSubmit {
                addEnteredTag()
            }
            .padding(.vertical, 4)
    }

    @ViewBuilder
    private func tagNameValidationError() -> some View {
        if let message = viewModel.validationErrorMessage(for: viewModel.validationState) {
            validationText(message)
        }
    }

    private func addEnteredTag() {
        if viewModel.validationState == .valid {
            withAnimation {
                viewModel.addTag(viewModel.enteredTag)
                viewModel.enteredTag = ""
            }
        }
    }

    @ViewBuilder
    private func addedTagsArea() -> some View {
        let currentTags = viewModel.currentTags

        if !currentTags.isEmpty {
            FlowLayout(spacing: tagBubbleSpacing) {
                ForEach(currentTags, id: \.self) { tag in
                    currentTagBubble(tag: tag)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func suggestedTagsArea() -> some View {
        VStack(spacing: 16) {
            sectionText(Strings.Tags.suggestedTagsSection)

            let suggestedTags = viewModel.suggestedTags

            if suggestedTags.isEmpty {
                normalText(Strings.Tags.suggestedTagsSectionEmpty)
            } else {
                suggestedTagsList(suggestedTags, withKeyboardStyle: false)
            }
        }
    }

    @ViewBuilder
    private func suggestedTagsList(_ tags: [String], withKeyboardStyle: Bool) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: tagBubbleSpacing) {
                ForEach(tags, id: \.self) { tag in
                    suggestedTagBubble(tag: tag)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .frame(maxHeight: withKeyboardStyle ? .infinity : nil)
        }
        .padding(.horizontal, -horizontalPadding)
    }

    @ViewBuilder
    private func normalText(_ text: String) -> some View {
        Text(text)
            .font(for: .body1)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(for: .h4)
            .textCase(.uppercase)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(ColorTheme.Base.secondaryText.color)
    }

    @ViewBuilder
    private func validationText(_ text: String) -> some View {
        Text(text)
            .font(for: .body1)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(ColorTheme.Base.error.color)
    }

    @ViewBuilder
    private func currentTagBubble(tag: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)

        Button {
            withAnimation {
                viewModel.removeTag(tag)
            }
        } label: {
            HStack {
                Text(tag)

                Image(systemName: "xmark")
                    .imageScale(.small)
            }
            .fontWeight(.medium)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background {
                shape.fill(ColorTheme.Base.primaryVariant.color)
            }
        }
        .accessibilityLabel(Text(Accessibility.Tags.removeTag.replacingOccurrences(of: "{0}", with: tag)))
        .foregroundStyle(ColorTheme.Base.primary.color)
    }

    @ViewBuilder
    private func suggestedTagBubble(tag: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)

        Button {
            withAnimation {
                viewModel.addTag(tag)
            }
        } label: {
            HStack {
                Text(tag)

                Image(systemName: "plus")
                    .imageScale(.small)
            }
            .fontWeight(.medium)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background {
                shape.fill(ColorTheme.Backgrounds.backgroundVariant.color)
            }
            .background {
                shape.stroke(ColorTheme.Base.secondaryText.color)
            }
            .padding(.vertical, 1)
        }
        .accessibilityLabel(Text(Accessibility.Tags.addTag.replacingOccurrences(of: "{0}", with: tag)))
        .foregroundStyle(.primary)
    }
}

#Preview {
    let item = FilesViewItem(
        id: UUID(),
        kind: .file,
        name: "some_file.pdf",
        filePath: "some/path",
        ownedBy: nil,
        modifiedAt: nil,
        icon: .document,
        tags: ["Lorem", "Ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit"]
    )

    let mockAPI = {
        let mockAPI = MockNodesAPIProtocol()
        mockAPI.getAllTags_MockMethod = {
            ["suggested tag 1", "tag 2", "lorem", "ipsum", "abc"]
        }
        mockAPI.updateTagsNodeIDTags_MockMethod = { _, _ in }
        return mockAPI
    }()

    let useCases = TagsEditView.UseCases(
        updateTags: WireCellsUpdateTagsUseCase(nodesAPI: mockAPI),
        getSuggestions: WireCellsGetTagSuggestionsUseCase(nodesAPI: mockAPI),
    )

    TagsEditView(fileItem: item, useCases: useCases, postSaveAction: {})
}
