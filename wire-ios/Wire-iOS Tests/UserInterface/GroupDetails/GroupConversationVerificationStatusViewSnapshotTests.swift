//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import XCTest

@testable import Wire

final class GroupConversationVerificationStatusViewSnapshotTests: BaseSnapshotTestCase {

    private var sut: GroupConversationVerificationStatusView!

    override func setUp() {
        super.setUp()

        sut = .init(frame: .init(origin: .zero, size: .init(width: 300, height: 30)))
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    // MARK: -

    func testNeitherCertifiedNorVerified_Light() {
        // When
        sut.status = .init(isE2EICertified: false, isProteusVerified: false)

        // Then
        verify(matching: sut)
    }

    func testNeitherCertifiedNorVerified_Dark() {
        // When
        sut.status = .init(isE2EICertified: false, isProteusVerified: false)
        sut.overrideUserInterfaceStyle = .dark

        // Then
        verify(matching: sut)
    }

    // MARK: -

    func testOnlyE2EICertified_Light() {
        // When
        sut.status = .init(isE2EICertified: true, isProteusVerified: false)
        sut.frame.size = sut.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )

        // Then
        verify(matching: sut)
    }

    func testOnlyE2EICertified_Dark() {
        // When
        sut.status = .init(isE2EICertified: true, isProteusVerified: false)
        sut.overrideUserInterfaceStyle = .dark
        sut.frame.size = sut.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )

        // Then
        verify(matching: sut)
    }

    // MARK: -

    func testOnlyProteusVerified_Light() {
        // When
        sut.status = .init(isE2EICertified: false, isProteusVerified: true)
        sut.frame.size = sut.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )

        // Then
        verify(matching: sut)
    }

    func testOnlyProteusVerified_Dark() {
        // When
        sut.status = .init(isE2EICertified: false, isProteusVerified: true)
        sut.overrideUserInterfaceStyle = .dark
        sut.frame.size = sut.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )

        // Then
        verify(matching: sut)
    }

    // MARK: -

    func testBothE2EICertifiedAndProteusVerified_Light() {
        // When
        sut.status = .init(isE2EICertified: true, isProteusVerified: true)
        sut.frame.size = sut.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )

        // Then
        verify(matching: sut)
    }

    func testBothE2EICertifiedAndProteusVerified_Dark() {
        // When
        sut.status = .init(isE2EICertified: true, isProteusVerified: true)
        sut.overrideUserInterfaceStyle = .dark
        sut.frame.size = sut.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )

        // Then
        verify(matching: sut)
    }
}
