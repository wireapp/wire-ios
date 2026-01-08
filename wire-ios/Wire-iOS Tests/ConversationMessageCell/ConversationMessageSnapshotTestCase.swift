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
import WireFoundationSupport
import WireMessagingDomainSupport
import XCTest
@testable import Wire

private extension ConversationMessageContext {
    static let defaultContext = ConversationMessageContext(
        isSameSenderAsPrevious: false,
        isTimestampInSameMinuteAsPreviousMessage: false,
        isFirstMessageOfTheDay: false,
        isFirstUnreadMessage: false,
        isLastMessage: false,
        searchQueries: [],
        previousMessageIsKnock: false
    )
}

func XCTAssertArrayEqual(
    _ descriptions: [Any],
    _ expectedDescriptions: [Any],
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let classes = descriptions.map { String(describing: $0) }
    let expectedClasses = expectedDescriptions.map { String(describing: $0) }
    XCTAssertEqual(classes, expectedClasses, file: file, line: line)
}

class ConversationMessageSnapshotTestCase: ZMSnapshotTestCase {

    var userSession: UserSessionMock!
    var forceRecord: Bool = false
    var mockUserDefaults = UserDefaultsProtocolMock()

    override func setUp() {
        super.setUp()
        userSession = UserSessionMock()
        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = []
        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = false
    }

    override func tearDown() {
        userSession = nil
        super.tearDown()
    }

    /// Performs a snapshot test for a message
    func verify(
        message: ConversationMessage,
        context: ConversationMessageContext? = nil,
        named: String? = nil,
        waitForImagesToLoad: Bool = false,
        waitForTextViewToLoad: Bool = false,
        allColorSchemes: Bool = false,
        allWidths: Bool = true,
        snapshotBackgroundColor: UIColor? = nil,
        record: Bool? = nil,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {

        let createSut: (CGFloat) -> UIView = { width in
            // prevent cache exist and loading image immediately
            if !waitForImagesToLoad {
                MediaAssetCache.defaultImageCache.cache.removeAllObjects()
            }
            return self.createUIStackView(
                message: message,
                context: context,
                waitForImagesToLoad: waitForImagesToLoad,
                waitForTextViewToLoad: waitForTextViewToLoad,
                snapshotBackgroundColor: snapshotBackgroundColor,
                width: width
            )
        }

        if allColorSchemes {
            ColorScheme.default.variant = .dark
            verify(
                createSut: createSut,
                snapshotBackgroundColor: snapshotBackgroundColor,
                named: (named ?? "") + "dark",
                record: record ?? forceRecord,
                allWidths: allWidths,
                file: file,
                testName: testName,
                line: line
            )

            ColorScheme.default.variant = .light
            verify(
                createSut: createSut,
                snapshotBackgroundColor: snapshotBackgroundColor,
                named: (named ?? "") + "light",
                record: record ?? forceRecord,
                allWidths: allWidths,
                file: file,
                testName: testName,
                line: line
            )
        } else {
            verify(
                createSut: createSut,
                snapshotBackgroundColor: snapshotBackgroundColor,
                named: named,
                record: record ?? forceRecord,
                allWidths: allWidths,
                file: file,
                testName: testName,
                line: line
            )
        }
    }

    private func verify(
        createSut: (CGFloat) -> UIView,
        snapshotBackgroundColor: UIColor?,
        named name: String? = nil,
        record: Bool? = nil,
        allColorSchemes: Bool = false,
        allWidths: Bool = true,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        let backgroundColor = snapshotBackgroundColor ?? (ColorScheme.default.variant == .light ? .white : .black)

        if allWidths {
            verifyInAllPhoneWidths(
                createSut: createSut,
                snapshotBackgroundColor: backgroundColor,
                named: name,
                record: record,
                file: file,
                testName: testName,
                line: line
            )
        } else {
            verifyInWidths(
                createSut: createSut,
                widths: [smallestWidth],
                snapshotBackgroundColor: backgroundColor,
                named: name,
                record: record ?? forceRecord,
                file: file,
                testName: testName,
                line: line
            )
        }
    }

    private func createUIStackView(
        message: ConversationMessage,
        context: ConversationMessageContext?,
        waitForImagesToLoad: Bool,
        waitForTextViewToLoad: Bool,
        snapshotBackgroundColor: UIColor?,
        width: CGFloat
    ) -> UIStackView {
        let context = (context ?? ConversationMessageContext.defaultContext)!

        let factory = MockWireMessagingFactoryProtocol()
        factory.makeFetchNodeUseCase_MockValue = MockWireDriveFetchNodeUseCaseProtocol()

        let section = ConversationMessageSectionController(
            message: message,
            context: context,
            selfUser: userSession.selfUser,
            userSession: userSession,
            useInvertedIndices: false,
            contentWidth: width,
            userDefaults: mockUserDefaults,
            wireMessagingFactory: factory
        )

        let views = section.cellDescriptionsForTesting.map { $0.instance.makeView(message) }
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = snapshotBackgroundColor ?? (ColorScheme.default.variant == .light ? .white : .black)

        if waitForImagesToLoad {
            _ = waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup])
        }

        if waitForTextViewToLoad {
            // We need to run the run loop for UITextView to highlight detected links
            let delay = Date().addingTimeInterval(1)
            RunLoop.main.run(until: delay)
        }

        return stackView

    }

}

extension ConversationMessageCellDescription {

    func makeView(_ message: ZMConversationMessage? = nil) -> UIView {
        let view = View()
        let container = UIView()

        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)

        let leading = view.leadingAnchor.constraint(equalTo: container.leadingAnchor)
        let trailing = view.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        let top = view.topAnchor.constraint(equalTo: container.topAnchor)
        let bottom = view.bottomAnchor.constraint(equalTo: container.bottomAnchor)

        NSLayoutConstraint.activate([leading, trailing, top, bottom])

        view.configure(with: configuration, animated: false)
        if let message {
            view.message = message
        }

        return container
    }
}
