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

import WireDesign
import WireTestingPackage
import XCTest
import Ziphy

@testable import Wire

final class GiphySearchViewControllerSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: GiphySearchViewController!

    private var mockConversation: MockConversation!
    private var mockNavigationController: UINavigationController!

    private var client: ZiphyClient!
    private var requester: MockURLSession!
    private var resultsController: ZiphySearchResultsController!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        mockConversation = MockConversation.oneOnOneConversation()
        requester = MockURLSession(cache: nil)
        client = ZiphyClient(
            host: "localhost",
            requester: requester,
            downloadSession: requester
        )
        resultsController = ZiphySearchResultsController(client: client, pageSize: 5)

        let searchTerm: String = "apple"
        sut = GiphySearchViewController(
            searchTerm: searchTerm,
            conversation: (mockConversation as Any) as! ZMConversation,
            searchResultsController: resultsController
        )

        mockNavigationController = UINavigationController(rootViewController: sut)
        mockNavigationController.navigationBar.backgroundColor = SemanticColors.View.backgroundDefault

        sut.collectionView?.backgroundColor = SemanticColors.View.backgroundDefault
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        mockConversation = nil
        mockNavigationController = nil
        client = nil
        requester = nil
        resultsController = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testEmptySearchScreenWithKeyword() {
        snapshotHelper.verify(matching: mockNavigationController.view)
    }

}
