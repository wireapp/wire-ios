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

import GenericMessageProtocol
import WireDesign
import WireMessagingDomainSupport
import WireTestingPackage
import XCTest

@testable import Wire

// MARK: - UIView extension

private extension UIView {

    func prepareForSnapshot(_ size: CGSize = CGSize(width: 320, height: 216)) -> UIView {
        let container = ReplyRoundCornersView(containedView: self)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: size.width).isActive = true
        container.backgroundColor = SemanticColors.View.backgroundUserCell
        return container
    }

}

// MARK: - MessageReplyAttachmentsViewSnapshotTests

final class MessageReplyAttachmentsViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        invalidateStyle()
        super.tearDown()
    }

    // MARK: - Helper methods

    func invalidateStyle() {
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }

    // MARK: - Snapshot Tests

    func testThatItRendersMultipartMessagePreviewWithSingleImageAttachment() {
        let sut = makeView(
            testCase: .singleImageAttachment,
            text: "Lorem Ipsum Dolor Sit Amed."
        )

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )
    }

    func testThatItRendersMultipartMessagePreviewWithSingleFileAttachment() {
        let sut = makeView(
            testCase: .singleFileAttachment,
            text: "Lorem Ipsum Dolor Sit Amed."
        )

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )
    }

    func testThatItRendersMultipartMessagePreviewWithMultipleAttachments() {
        let sut = makeView(
            testCase: .multipleAttachments,
            text: "Lorem Ipsum Dolor Sit Amed."
        )

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )
    }

    func testThatItRendersMultipartMessagePreviewWithSingleAttachmentAndNoText() {
        let sut = makeView(
            testCase: .singleFileAttachment
        )

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )
    }

    enum TestCase {
        case singleImageAttachment
        case singleFileAttachment
        case multipleAttachments
    }

    private func makeView(testCase: TestCase, text: String = "") -> UIView {
        let nodeID = UUID.mockID1

        let attachments: [Attachment] = switch testCase {
        case .singleFileAttachment:
            [
                Attachment.with {
                    $0.content = .cellAsset(.with {
                        $0.contentType = "application/pdf"
                        $0.initialName = "test.pdf"
                        $0.uuid = nodeID.uuidString
                    })

                }
            ]
        case .singleImageAttachment:
            [
                Attachment.with {
                    $0.content = .cellAsset(.with {
                        $0.initialMetaData = .image(.with { _ in })
                        $0.uuid = nodeID.uuidString
                    })
                }
            ]
        case .multipleAttachments:
            [
                Attachment.with {
                    $0.content = .cellAsset(.with {
                        $0.initialMetaData = .image(.with { _ in })
                        $0.uuid = nodeID.uuidString
                    })
                },
                Attachment.with {
                    $0.content = .cellAsset(.with {
                        $0.initialMetaData = .image(.with { _ in })
                        $0.uuid = nodeID.uuidString
                    })
                }
            ]
        }

        let message = MockMessageFactory.multipartMessage(
            withText: text,
            attachments: attachments
        )

        let fetchNodeUseCase = MockWireCellsFetchNodeUseCaseProtocol()
        fetchNodeUseCase.invokeNodeID_MockValue = AsyncThrowingStream { continuation in
            continuation.finish()
        }
        let viewModel = MessageReplyAttachmentsViewModel(
            fetchNodeUseCase: fetchNodeUseCase
        )

        let view = message.replyPreview(messageReplyAttachmentsViewModel: viewModel)!
        return view.prepareForSnapshot()
    }
}
