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

import WireTestingPackage
import XCTest

@testable import Wire

final class ConversationLinkAttachmentMessageCellTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var mockThumbnail: MockImageResource!
    private var sut: ConversationLinkAttachmentCell!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        let imageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        mockThumbnail = MockImageResource()
        mockThumbnail.imageData = imageData.pngData()!
    }

    // MARK: - tearDown

    override func tearDown() {
        MediaAssetCache.defaultImageCache.cache.removeAllObjects()
        snapshotHelper = nil
        sut = nil
        mockThumbnail = nil
        super.tearDown()
    }

    // MARK: - Helper method

    func setUpCell(configuration: ConversationLinkAttachmentCell.Configuration) -> ConversationLinkAttachmentCell {
        let cell = ConversationLinkAttachmentCell()
        cell.configure(with: configuration, animated: false)
        cell.frame.size = cell.systemLayoutSizeFitting(CGSize(width: 414, height: 0))

        return cell
    }

    // MARK: - Snapshot Tests

    func testThatItRendersYouTubeLinkAttachment() {
        // GIVEN
        let attachment = LinkAttachment(type: .youTubeVideo,
                                        title: "Lagar mat med Fernando Di Luca",
                                        permalink: URL(string: "https://www.youtube.com/watch?v=l7aqpSTa234")!,
                                        thumbnails: [],
                                        originalRange: NSRange(location: 0, length: 43))

        mockThumbnail.cacheIdentifier = #function
        let configuration = ConversationLinkAttachmentCell.Configuration(attachment: attachment, thumbnailResource: mockThumbnail)

        // WHEN
        sut = setUpCell(configuration: configuration)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersSoundCloudSongAttachment() {
        // GIVEN
        let attachment = LinkAttachment(type: .soundCloudTrack, title: "Bridgit Mendler - Atlantis feat. Kaiydo",
                                        permalink: URL(string: "https://soundcloud.com/bridgitmendler/bridgit-mendler-atlantis-feat-kaiydo")!,
                                        thumbnails: [], originalRange: NSRange(location: 0, length: 74))

        mockThumbnail.cacheIdentifier = #function
        let configuration = ConversationLinkAttachmentCell.Configuration(attachment: attachment, thumbnailResource: mockThumbnail)

        // WHEN
        sut = setUpCell(configuration: configuration)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersSoundCloudPlaylistAttachment() {
        // GIVEN
        let attachment = LinkAttachment(type: .soundCloudPlaylist, title: "Artists To Watch 2019",
                                        permalink: URL(string: "https://soundcloud.com/playback/sets/2019-artists-to-watch")!,
                                        thumbnails: [], originalRange: NSRange(location: 0, length: 58))

        mockThumbnail.cacheIdentifier = #function
        let configuration = ConversationLinkAttachmentCell.Configuration(attachment: attachment, thumbnailResource: mockThumbnail)

        // WHEN
        sut = setUpCell(configuration: configuration)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

}
