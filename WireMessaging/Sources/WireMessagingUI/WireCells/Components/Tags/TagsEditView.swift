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
    
    private let horizontalPadding: CGFloat = 16
    private let tagBubbleSpacing: CGFloat = 10

    init(fileItem: FilesViewItem, updateTagsUseCase: any WireCellsUpdateTagsUseCaseProtocol) {
        _viewModel = .init(wrappedValue: .init(fileItem: fileItem, updateTagsUseCase: updateTagsUseCase))
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
                                    await viewModel.save()
                                }
                            } label: {
                                Text(L10n.Localizable.General.save)
                                    .bold()
                            }
                            .disabled(!viewModel.hasChanges)
                        }
                    }
                }
                .background(ColorTheme.Backgrounds.background.color)
                .tint(ColorTheme.Base.primary.color)
                .onReceive(viewModel.dismiss) {
                    dismiss()
                }
        }
    }
    
    @ViewBuilder private func content() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                normalText(Strings.Tags.headline)
                
                tagNameInputArea()
                
                Spacer(minLength: 6)
                
                addedTagsArea()
                
                Spacer(minLength: 28)

                suggestedTagsArea()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical)
            .animation(.easeInOut, value: viewModel.enteredTag)
        }
    }
    
    @ViewBuilder private func tagNameInputArea() -> some View {
        VStack {
            HStack {
                let prompt = Strings.Tags.textFieldPlaceholder
                TextField("", text: $viewModel.enteredTag, prompt: Text(prompt))
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        addEnteredTag()
                    }
                
                Button {
                    addEnteredTag()
                } label: {
                    Text(Strings.Tags.addTagButton)
                }
                .disabled(viewModel.validationState != .valid)
                .animation(nil, value: viewModel.enteredTag)
            }
            
            if let message = viewModel.validationErrorMessage(for: viewModel.validationState) {
                validationText(message)
            }
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
    
    @ViewBuilder private func addedTagsArea() -> some View {
        VStack(spacing: 16) {
            sectionText(Strings.Tags.addedTagsSection)
            
            let currentTags = viewModel.currentTags
            
            if currentTags.isEmpty {
                normalText(Strings.Tags.addedTagsSectionEmpty)
            } else {
                FlowLayout(spacing: tagBubbleSpacing) {
                    ForEach(currentTags, id: \.self) { tag in
                        currentTagBubble(tag: tag)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    @ViewBuilder private func suggestedTagsArea() -> some View {
        VStack(spacing: 16) {
            sectionText(Strings.Tags.suggestedTagsSection)
            
            let suggestedTags = viewModel.suggestedTags
            
            if suggestedTags.isEmpty {
                normalText(Strings.Tags.suggestedTagsSectionEmpty)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: tagBubbleSpacing) {
                        ForEach(suggestedTags, id: \.self) { tag in
                            suggestedTagBubble(tag: tag)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                }
                .padding(.horizontal, -horizontalPadding)
            }
        }
    }
    
    @ViewBuilder private func normalText(_ text: String) -> some View {
        Text(text)
            .wireTextStyle(.body1)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder private func sectionText(_ text: String) -> some View {
        Text(text)
            .wireTextStyle(.h4)
            .textCase(.uppercase)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(ColorTheme.Base.secondaryText.color)
    }
    
    @ViewBuilder private func validationText(_ text: String) -> some View {
        Text(text)
            .wireTextStyle(.body1)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(ColorTheme.Base.error.color)
    }
    
    @ViewBuilder private func currentTagBubble(tag: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        
        HStack {
            Text(tag)
            
            Button {
                withAnimation {
                    viewModel.removeTag(tag)
                }
            } label: {
                Image(systemName: "xmark")
                    .imageScale(.small)
            }
            .accessibilityLabel(Text(Accessibility.Tags.removeTag.replacingOccurrences(of: "{0}", with: tag)))
        }
        .fontWeight(.medium)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background {
            shape.stroke(ColorTheme.Base.primary.color, lineWidth: 1)
        }
        .background {
            shape.fill(ColorTheme.Base.primaryVariant.color)
        }
        .foregroundStyle(ColorTheme.Base.primary.color)
    }
    
    @ViewBuilder private func suggestedTagBubble(tag: String) -> some View {
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
        }
        .accessibilityLabel(Text(Accessibility.Tags.addTag.replacingOccurrences(of: "{0}", with: tag)))
        .foregroundStyle(.primary)
    }
}

#Preview {
    let item = FilesViewItem(
        id: UUID(),
        filename: "Hello World",
        ownedBy: nil,
        modifiedAt: nil,
        icon: .document,
        tags: ["Lorem", "Ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit"]
    )
    
    let mockAPI = MockNodesAPIProtocol()
    let useCase = WireCellsUpdateTagsUseCase(nodesAPI: mockAPI)
    
    TagsEditView(fileItem: item, updateTagsUseCase: useCase)
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())
}
