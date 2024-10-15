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

import AVFoundation
import Photos
import WireDesign
import WireTestingPackage
import XCTest

@testable import Wire

// MARK: - CameraKeyboardViewControllerDelegateMock

final class CameraKeyboardViewControllerDelegateMock: CameraKeyboardViewControllerDelegate {

    var cameraKeyboardWantsToOpenCameraRollHitCount: UInt = 0
    @objc func cameraKeyboardViewControllerWantsToOpenCameraRoll(_ controller: CameraKeyboardViewController) {
        cameraKeyboardWantsToOpenCameraRollHitCount += 1
    }

    var cameraKeyboardWantsToOpenFullScreenCameraHitCount: UInt = 0
    @objc func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(_ controller: CameraKeyboardViewController) {
        cameraKeyboardWantsToOpenFullScreenCameraHitCount += 1
    }

    var cameraKeyboardDidSelectVideoHitCount: UInt = 0
    @objc func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectVideo: URL, duration: TimeInterval) {
        cameraKeyboardDidSelectVideoHitCount += 1
    }

    var cameraKeyboardViewControllerDidSelectImageDataHitCount: UInt = 0
    func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectImageData: Data, isFromCamera: Bool, uti: String?) {
        cameraKeyboardViewControllerDidSelectImageDataHitCount += 1
    }
}

// MARK: - MockAssetLibrary

private final class MockAssetLibrary: AssetLibrary {
    fileprivate override var count: UInt { return 5 }

    fileprivate override func refetchAssets(synchronous: Bool) {
        // no op
    }
}

// MARK: - MockImageManager

private final class MockImageManager: ImageManagerProtocol {

    func cancelImageRequest(_ requestID: PHImageRequestID) {
        // no op
    }

    func requestImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?, resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        return 0
    }

    func requestImageData(for asset: PHAsset, options: PHImageRequestOptions?, resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        return 0
    }

    func requestExportSession(forVideo asset: PHAsset, options: PHVideoRequestOptions?, exportPreset: String, resultHandler: @escaping (AVAssetExportSession?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        return 0
    }

    static var defaultInstance: ImageManagerProtocol = MockImageManager()
}

// MARK: - CallingMockCameraKeyboardViewController

private final class CallingMockCameraKeyboardViewController: CameraKeyboardViewController {
    override var shouldBlockCallingRelatedActions: Bool {
        return true
    }
}

// MARK: - CameraKeyboardViewControllerTests

final class CameraKeyboardViewControllerTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: CameraKeyboardViewController!
    private var delegateMock: CameraKeyboardViewControllerDelegateMock!
    fileprivate var mockAssetLibrary: MockAssetLibrary!
    fileprivate var mockImageManager: MockImageManager!

    // MARK: - setUp

    override func setUp() {
        super.setUp()

        snapshotHelper = SnapshotHelper()
        mockAssetLibrary = MockAssetLibrary(photoLibrary: MockPhotoLibrary())
        mockImageManager = MockImageManager()
        delegateMock = CameraKeyboardViewControllerDelegateMock()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        delegateMock = nil
        mockAssetLibrary = nil
        mockImageManager = nil

        super.tearDown()
    }

    // MARK: - Helper methods

    @discardableResult
    private func prepareForSnapshot(_ size: CGSize = CGSize(width: 320, height: 216)) -> UIView {
        self.sut.beginAppearanceTransition(true, animated: false)
        self.sut.endAppearanceTransition()

        let container = UIView()
        container.addSubview(self.sut.view)
        container.backgroundColor = SemanticColors.View.backgroundConversationView
        container.translatesAutoresizingMaskIntoConstraints = false
        sut.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: size.height),
            container.widthAnchor.constraint(equalToConstant: size.width),
            sut.view.topAnchor.constraint(equalTo: container.topAnchor),
            sut.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            sut.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            sut.view.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        container.layoutIfNeeded()
        return container
    }

    private func setupSut(permissions: PhotoPermissionsController) {
        sut = CameraKeyboardViewController(permissions: permissions)
    }

    // MARK: - Tests

    func testWithCallingOverlay() {
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        sut = CallingMockCameraKeyboardViewController(permissions: permissions)

        snapshotHelper.verify(matching: prepareForSnapshot())
    }

    func testThatFirstSectionContainsCameraCellOnly() {
        // GIVEN
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        setupSut(permissions: permissions)

        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()

        // WHEN
        let cameraCell = self.sut.collectionView.cellForItem(at: IndexPath(item: 0, section: 0))

        // THEN
        XCTAssertTrue(cameraCell is CameraCell)
        XCTAssertEqual(self.sut.collectionView.numberOfSections, 2)
        XCTAssertEqual(self.sut.collectionView.numberOfItems(inSection: 0), 1)
    }

    func testThatTableViewContainsPermissionsCellOnly_CameraAndLibraryAccessNotGranted() {
        // GIVEN
        let permissions = MockPhotoPermissionsController(camera: false, library: false)
        setupSut(permissions: permissions)
        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()

        // WHEN
        let cameraCell = self.sut.collectionView.cellForItem(at: IndexPath(item: 0, section: 0))

        // THEN
        XCTAssertTrue(cameraCell is CameraKeyboardPermissionsCell)
        XCTAssertEqual(self.sut.collectionView.numberOfSections, 1)
        XCTAssertEqual(self.sut.collectionView.numberOfItems(inSection: 0), 1)
    }

    // MARK: - Tests for InitialStateLayoutSizeCompact

    private func initialStateLayoutSizeCompact(with permissions: PhotoPermissionsController,
                                               file: StaticString = #file,
                                               testName: String = #function,
                                               line: UInt = #line) {
        // GIVEN
        // splitView?.layoutSize = .compact // TODO: remove?
        // WHEN
        setupSut(permissions: permissions)
        // THEN
        snapshotHelper.verify(
            matching: prepareForSnapshot(),
            file: file,
            testName: testName,
            line: line
        )
    }

    func testInitialStateLayoutSizeCompact() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: true, library: true)

        // THEN
        initialStateLayoutSizeCompact(with: permissions)
    }

    func testInitialStateLayoutSizeCompact_CameraAndLibraryAccessNotGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: false, library: false)

        // THEN
        initialStateLayoutSizeCompact(with: permissions)
    }

    func testInitialStateLayoutSizeCompact_CameraAccessGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: true, library: false)

        // THEN
        initialStateLayoutSizeCompact(with: permissions)
    }

    func testInitialStateLayoutSizeCompact_LibraryAccessGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: false, library: true)

        // THEN
        initialStateLayoutSizeCompact(with: permissions)
    }

    // MARK: - Tests for InitialStateLayoutSizeRegularPortrait

    private func initialStateLayoutSizeRegularPortrait(with permissions: PhotoPermissionsController,
                                                       file: StaticString = #file,
                                                       testName: String = #function,
                                                       line: UInt = #line) {
        // GIVEN
        // splitView?.layoutSize = .regularPortrait // TODO: remove?
        // splitView?.leftViewControllerWidth = 216
        // WHEN
        setupSut(permissions: permissions)
        // THEN
        snapshotHelper.verify(
            matching: prepareForSnapshot(CGSize(width: 768, height: 264)),
            file: file,
            testName: testName,
            line: line
        )
    }

    func testInitialStateLayoutSizeRegularPortrait() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: true, library: true)

        // THEN
        initialStateLayoutSizeRegularPortrait(with: permissions)
    }

    func testInitialStateLayoutSizeRegularPortrait_CameraAndLibraryAccessNotGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: false, library: false)

        // THEN
        initialStateLayoutSizeRegularPortrait(with: permissions)
    }

    func testInitialStateLayoutSizeRegularPortrait_CameraAccessGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: true, library: false)

        // THEN
        initialStateLayoutSizeRegularPortrait(with: permissions)
    }

    func testInitialStateLayoutSizeRegularPortrait_LibraryAccessGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: false, library: true)

        // THEN
        initialStateLayoutSizeRegularPortrait(with: permissions)
    }

    // MARK: - Tests for InitialStateLayoutSizeRegularLandscape

    func initialStateLayoutSizeRegularLandscape(with permissions: PhotoPermissionsController,
                                                file: StaticString = #file,
                                                testName: String = #function,
                                                line: UInt = #line) {
        // GIVEN
        // splitView?.layoutSize = .regularLandscape // TODO: remove?
        // splitView?.leftViewControllerWidth = 216
        // WHEN
        setupSut(permissions: permissions)
        // THEN
        snapshotHelper.verify(matching: prepareForSnapshot(CGSize(width: 1024, height: 352)), file: file, testName: testName, line: line)
    }

    func testInitialStateLayoutSizeRegularLandscape() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: true, library: true)

        // THEN
        initialStateLayoutSizeRegularLandscape(with: permissions)
    }

    func testInitialStateLayoutSizeRegularLandscape_CameraAndLibraryAccessNotGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: false, library: false)

        // THEN
        initialStateLayoutSizeRegularLandscape(with: permissions)
    }

    func testInitialStateLayoutSizeRegularLandscape_CameraAccessGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: true, library: false)

        // THEN
        initialStateLayoutSizeRegularLandscape(with: permissions)
    }

    func testInitialStateLayoutSizeRegularLandscape_LibraryAccessGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: false, library: true)

        // THEN
        initialStateLayoutSizeRegularLandscape(with: permissions)
    }

    // MARK: - Tests for CameraScrolledHorizontallySomePercent

    private func cameraScrolledHorizontallySomePercent(with permissions: PhotoPermissionsController,
                                                       file: StaticString = #file,
                                                       testName: String = #function,
                                                       line: UInt = #line) {
        // GIVEN
        // self.splitView?.layoutSize = .compact // TODO: remove?
        setupSut(permissions: permissions)
        self.prepareForSnapshot()
        // WHEN
        self.sut.collectionView.scrollRectToVisible(CGRect(x: 300, y: 0, width: 160, height: 10), animated: false)
        // THEN
        snapshotHelper.verify(matching: prepareForSnapshot(),
               file: file,
               testName: testName,
               line: line)
    }

    func testCameraScrolledHorizontallySomePercent() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: true, library: true)

        // THEN
        cameraScrolledHorizontallySomePercent(with: permissions)
    }

    func testCameraScrolledHorizontallySomePercent_CameraAndLibraryAccessNotGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: false, library: false)

        // THEN
        cameraScrolledHorizontallySomePercent(with: permissions)
    }

    func testCameraScrolledHorizontallySomePercent_CameraAccessGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: true, library: false)

        // THEN
        cameraScrolledHorizontallySomePercent(with: permissions)
    }

    func testCameraScrolledHorizontallySomePercent_LibraryAccessGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: false, library: true)

        // THEN
        cameraScrolledHorizontallySomePercent(with: permissions)
    }

    // MARK: - Tests for CameraScrolledHorizontallyAwayPercent

    private func cameraScrolledHorizontallyAwayPercent(with permissions: PhotoPermissionsController,
                                                       file: StaticString = #file,
                                                       testName: String = #function,
                                                       line: UInt = #line) {
        // GIVEN
        // splitView?.layoutSize = .compact // TODO: remove?
        setupSut(permissions: permissions)
        prepareForSnapshot()
        // WHEN
        sut.collectionView.scrollRectToVisible(CGRect(x: 320, y: 0, width: 160, height: 10), animated: false)
        // THEN
        snapshotHelper.verify(matching: prepareForSnapshot(),
               file: file,
               testName: testName,
               line: line)
    }

    func testCameraScrolledHorizontallyAwayPercent() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: true, library: true)

        // THEN
        cameraScrolledHorizontallyAwayPercent(with: permissions)
    }

    func testCameraScrolledHorizontallyAwayPercent_CameraAndLibraryAccessNotGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: false, library: false)

        // THEN
        cameraScrolledHorizontallyAwayPercent(with: permissions)
    }

    func testCameraScrolledHorizontallyAwayPercent_CameraAccessGranted() {
        let permissions = MockPhotoPermissionsController(camera: true, library: false)

        // THEN
        cameraScrolledHorizontallyAwayPercent(with: permissions)
    }

    func testCameraScrolledHorizontallyAwayPercent_LibraryAccessGranted() {
        // GIVEN && WHEN
        let permissions = MockPhotoPermissionsController(camera: false, library: true)

        // THEN
        cameraScrolledHorizontallyAwayPercent(with: permissions)
    }

    func testThatItCallsDelegateCameraRollWhenCameraRollButtonPressed() {
        // GIVEN
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        setupSut(permissions: permissions)
        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()

        // WHEN
        self.sut.cameraRollButton.sendActions(for: .touchUpInside)

        // THEN
        XCTAssertEqual(self.delegateMock.cameraKeyboardWantsToOpenCameraRollHitCount, 1)
        XCTAssertEqual(self.delegateMock.cameraKeyboardWantsToOpenFullScreenCameraHitCount, 0)
        XCTAssertEqual(self.delegateMock.cameraKeyboardDidSelectVideoHitCount, 0)
        XCTAssertEqual(self.delegateMock.cameraKeyboardViewControllerDidSelectImageDataHitCount, 0)
    }

    func testThatItCallsDelegateWhenWantsToOpenFullScreenCamera() {
        // GIVEN
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        setupSut(permissions: permissions)
        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()

        // WHEN
        let cameraCell = self.sut.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as! CameraCell
        cameraCell.expandButton.sendActions(for: .touchUpInside)

        // THEN
        XCTAssertEqual(self.delegateMock.cameraKeyboardWantsToOpenCameraRollHitCount, 0)
        XCTAssertEqual(self.delegateMock.cameraKeyboardWantsToOpenFullScreenCameraHitCount, 1)
        XCTAssertEqual(self.delegateMock.cameraKeyboardDidSelectVideoHitCount, 0)
        XCTAssertEqual(self.delegateMock.cameraKeyboardViewControllerDidSelectImageDataHitCount, 0)
    }
}
