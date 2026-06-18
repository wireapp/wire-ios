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

import Foundation
import SwiftUI
@preconcurrency import QuickLookThumbnailing

struct Thumbnail: Identifiable {

    let id = UUID()
    let imageData: Data?
    let systemIconName: String

}

@MainActor
protocol ComposeMessageViewModel {

    var conversation: Conversation { get }
    var messageText: String { get set }
    var canSend: Bool { get }
    var isLoading: Bool { get }
    var progressState: MessageProgressState? { get }
    var thumbnails: [Thumbnail] { get }

    func start() async
    func send() async

}

enum MessageProgressState {
    case preparing
    case sending(Float)
    case success
}

@Observable
@MainActor
final class ComposeMessageViewModelImpl: ComposeMessageViewModel {

    let account: Account
    let conversation: Conversation
    let shareItems: [ShareItem]
    var messageText: String = ""
    var thumbnails: [Thumbnail] = []

    var canSend: Bool {
        true
    }

    var isLoading: Bool = false
    var progressState: MessageProgressState?

    private let router: RootRouter
    private let sendMessage: SendMessageUseCase
    private let onDone: () -> Void

    init(
        account: Account,
        conversation: Conversation,
        shareItems: [ShareItem],
        router: RootRouter,
        sendMessage: SendMessageUseCase,
        onDone: @escaping () -> Void
    ) {
        self.account = account
        self.conversation = conversation
        self.shareItems = shareItems
        self.router = router
        self.onDone = onDone
        self.sendMessage = sendMessage
    }

    func start() async {
        var thumbnails = [Thumbnail]()
        let thumbnailGenerator = QLThumbnailGenerator()

        for shareItem in shareItems {
            let request = QLThumbnailGenerator.Request(
                fileAt: shareItem.url,
                size: CGSize(width: 75, height: 75),
                scale: 1,
                representationTypes: .thumbnail
            )

            let data = try? await thumbnailGenerator
                .generateBestRepresentation(for: request)
                .uiImage
                .pngData()

            thumbnails.append(
                Thumbnail(
                    imageData: data,
                    systemIconName: shareItem.systemIconName
                )
            )
        }

        self.thumbnails = thumbnails

    }

    func send() async {
        isLoading = true
        defer { isLoading = false }

        // FIXME: allow multiple share items
        let message = Message(
            text: messageText,
            shareItem: shareItems.first!
        )

        let sendMessageTask = Task.detached { [self] in
            try await sendMessage(
                message,
                for: account,
                in: conversation
            )
        }

        let progress: AsyncThrowingStream<MessageSendingProgress, any Error>
        do {
            progress = try await sendMessageTask.value
        } catch {
            router.errorAlert = .generic(message: "failed to send: \(error)")
            return
        }

        do {
            for try await update in progress {
                switch update {
                case .preparing:
                    progressState = .preparing
                case let .sending(progress):
                    progressState = .sending(progress)
                }
            }
            
            progressState = .success
            
            try await Task.sleep(for: .seconds(1))
            
            progressState = nil
            onDone()
        } catch let error as MessageSendingError {
            switch error {
            case .timedOut:
                router.errorAlert = .generic(message: "Timed out")
            case .conversationDegraded:
                router.errorAlert = .generic(message: "Conversation is degraded")
            case .fileSharingDisabled:
                router.errorAlert = .generic(message: "File sharing is disabled")
            case let .generic(error):
                print("failed sending message: \(error)")
                router.errorAlert = .generic(message: "Something went wrong")
            }
        } catch {
            print("failed sending message: \(error)")
            router.errorAlert = .generic(message: "Something went wrong")
        }
    }

}

@MainActor
struct ComposeMessageViewModelMock: ComposeMessageViewModel {

    var conversation: Conversation
    var messageText: String = ""
    var canSend: Bool = true
    var isLoading: Bool = false
    var progressState: MessageProgressState?
    var thumbnails: [Thumbnail] = []

    func start() async {}
    func send() async {}

}
