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

import FBSnapshotTestCase
import UIKit
@testable import Wire
import WireCommonComponents

extension UITableViewCell: UITableViewDelegate, UITableViewDataSource {
    func wrapInTableView() -> UITableView {
        let tableView = UITableView(frame: self.bounds, style: .plain)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.layoutMargins = self.layoutMargins

        let size = self.systemLayoutSizeFitting(CGSize(width: bounds.width, height: 0.0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        self.layoutSubviews()

        self.bounds = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        self.contentView.bounds = self.bounds

        tableView.reloadData()
        tableView.bounds = self.bounds
        tableView.layoutIfNeeded()

        NSLayoutConstraint.activate([
            tableView.heightAnchor.constraint(equalToConstant: size.height)
        ])

        self.layoutSubviews()
        return tableView
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.bounds.size.height
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self
    }
}

class ZMSnapshotTestCase: FBSnapshotTestCase {

    typealias ConfigurationWithDeviceType = (_ view: UIView, _ isPad: Bool) -> Void
    typealias Configuration = (_ view: UIView) -> Void

    var uiMOC: NSManagedObjectContext!
    var coreDataStack: CoreDataStack!

    /// The color of the container view in which the view to
    /// be snapshot will be placed, defaults to UIColor.lightGrayColor
    var snapshotBackgroundColor: UIColor?

    /// If YES the uiMOC will have image and file caches. Defaults to NO.
    var needsCaches: Bool {
        return false
    }

    var documentsDirectory: URL?

    override open func setUp() {
        super.setUp()

        XCTAssertEqual(UIScreen.main.scale, 3, "Snapshot tests need to be run on a device with a 3x scale")
        if UIDevice.current.systemVersion.compare("17", options: .numeric, range: nil, locale: .current) == .orderedAscending {
            XCTFail("Snapshot tests need to be run on a device running at least iOS 17")
        }
        AppRootRouter.configureAppearance()
        FontScheme.configure(with: .large)

        UIView.setAnimationsEnabled(false)
        accentColor = .vividRed
        snapshotBackgroundColor = UIColor.clear

        // Enable when the design of the view has changed in order to update the reference snapshots

        recordMode = ProcessInfo.processInfo.environment["RECORDING_SNAPSHOTS"] == "YES"
        usesDrawViewHierarchyInRect = true

        do {
            documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            XCTAssertNil(error, "Unexpected error \(error)")
        }

        setupCoreDataStack()
        if needsCaches {
            setUpCaches()
        }
    }

    func setupCoreDataStack() {
        let account = Account(userName: "", userIdentifier: UUID())
        let coreDataStack = CoreDataStack(account: account,
                                          applicationContainer: documentsDirectory!,
                                          inMemoryStore: true)

        coreDataStack.loadStores(completionHandler: { error in
            XCTAssertNil(error)
        })
        self.coreDataStack = coreDataStack
        self.uiMOC = coreDataStack.viewContext
    }

    override open func tearDown() {
        if needsCaches {
            wipeCaches()
        }
        // Needs to be called before setting self.documentsDirectory to nil.
        removeContentsOfDocumentsDirectory()
        uiMOC = nil
        coreDataStack = nil
        documentsDirectory = nil
        snapshotBackgroundColor = nil
        UIColor.setAccentOverride(.undefined)
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }

    func removeContentsOfDocumentsDirectory() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: documentsDirectory!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

            for content: URL in contents {
                do {
                    try FileManager.default.removeItem(at: content)
                } catch {
                    XCTAssertNil(error, "Unexpected error \(error)")
                }
            }

        } catch {
            XCTAssertNil(error, "Unexpected error \(error)")
        }

    }

    func wipeCaches() {
        try? uiMOC.zm_fileAssetCache.wipeCaches()
        uiMOC.zm_userImageCache.wipeCache()
        PersonName.stringsToPersonNames().removeAllObjects()
    }

    func setUpCaches() {
        let cacheLocation = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        uiMOC.zm_userImageCache = UserImageLocalCache(location: nil)
        uiMOC.zm_fileAssetCache = FileAssetCache(location: cacheLocation)
    }

}

// MARK: - Helpers
extension ZMSnapshotTestCase {

    private func snapshotVerify(view: UIView,
                                identifier: String? = nil,
                                suffix: NSOrderedSet? = FBSnapshotTestCaseDefaultSuffixes(),
                                tolerance: CGFloat = tolerance,
                                file: StaticString = #file,
                                line: UInt = #line) {
        let errorDescription = snapshotVerifyViewOrLayer(view,
                                                            identifier: identifier,
                                                            suffixes: suffix!,
                                                            overallTolerance: tolerance,
                                                            defaultReferenceDirectory: (FB_REFERENCE_IMAGE_DIR),
                                                            defaultImageDiffDirectory: (IMAGE_DIFF_DIR))

        if errorDescription.count > 0 {
            XCTFail("\(errorDescription)", file: file, line: line)
        } else {
            XCTAssert(true)
        }
    }

    private func assertAmbigousLayout(_ view: UIView,
                                      file: StaticString = #file,
                                      line: UInt = #line) {
        if view.hasAmbiguousLayout,
            let trace = view._autolayoutTrace() {
            let description = "Ambigous layout in view: \(view) trace: \n\(trace)"

            recordFailure(withDescription: description, inFile: "\(file)", atLine: Int(line), expected: true)

        }
    }

    private func assertEmptyFrame(_ view: UIView,
                                  file: StaticString = #file,
                                  line: UInt = #line) -> Bool {
        if view.frame.isEmpty {
            let description = "View frame can not be empty"
            let filePath = "\(file)"
            recordFailure(withDescription: description, inFile: filePath, atLine: Int(line), expected: true)
            return true
        }
        return false
    }
}

// MARK: - interfaces

extension ZMSnapshotTestCase {

    func finalIdentifier(deviceName: String?, identifier: String?) -> String? {
        var finalDeviceName: String?

        if let deviceName, !deviceName.isEmpty {
            finalDeviceName = deviceName
        }

        if let identifier, !identifier.isEmpty {
            if let finalDeviceName {
                return "\(identifier)-\(finalDeviceName)"
            } else {
                return "\(identifier)"
            }
        } else {
            if let finalDeviceName {
                return finalDeviceName
            } else {
                return nil
            }
        }
    }

    /// Performs an assertion with the given view and the recorded snapshot.
    func verify(view: UIView,
                extraLayoutPass: Bool = false,
                tolerance: CGFloat = tolerance,
                identifier: String? = nil,
                deviceName: String? = nil,
                file: StaticString = #file,
                line: UInt = #line
        ) {
        let container = containerView(with: view, snapshotBackgroundColor: snapshotBackgroundColor)
        if assertEmptyFrame(container, file: file, line: line) {
            return
        }

        let identifier = finalIdentifier(deviceName: deviceName, identifier: identifier)

        if extraLayoutPass {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        view.layer.speed = 0 // freeze animations for deterministic tests
        snapshotVerify(view: container,
                       identifier: identifier,
                       suffix: FBSnapshotTestCaseDefaultSuffixes(),
                       tolerance: tolerance,
                       file: file,
                       line: line)

        assertAmbigousLayout(container, file: file, line: line)
    }

    static let tolerance: CGFloat = 0.3

    /// verify the snapshot with default iphone size
    ///
    /// - Parameters:
    ///   - view: the view to verify
    ///   - size: the customize view size, default is iPhone 4-inch's size
    ///   - file: source file
    ///   - line: source line
    func verifyInIPhoneSize(view: UIView,
                            extraLayoutPass: Bool = false,
                            size: CGSize = XCTestCase.DeviceSizeIPhone5,
                            file: StaticString = #file,
                            line: UInt = #line) {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: size.height),
            view.widthAnchor.constraint(equalToConstant: size.width)
        ])

        view.layoutIfNeeded()

        verify(view: view,
               extraLayoutPass: extraLayoutPass,
               file: file,
               line: line)
    }

    // MARK: - verify the snapshots in multiple devices

    /// Performs multiple assertions with the given view using the screen sizes of
    /// the common iPhones in Portrait and iPad in Landscape and Portrait.
    /// This method only makes sense for views that will be on presented fullscreen.
    func verifyMultipleSize(view: UIView,
                            extraLayoutPass: Bool,
                            inSizes sizes: [String: CGSize],
                            configuration: ConfigurationWithDeviceType?,
                            file: StaticString = #file,
                            line: UInt = #line) {
        for (deviceName, size) in sizes {
            view.frame = CGRect(origin: .zero, size: size)
            if let configuration = configuration {
                let isIPad = XCTestCase.tabletScreenSizes.values.contains(size)
                UIView.performWithoutAnimation({
                    configuration(view, isIPad)
                })
            }

            verify(view: view,
                   extraLayoutPass: extraLayoutPass,
                   deviceName: deviceName,
                   file: file,
                   line: line)
        }
    }

    func verifyInAllIPhoneSizes(view: UIView,
                                extraLayoutPass: Bool = false,
                                configuration: Configuration? = nil,
                                file: StaticString = #file,
                                line: UInt = #line) {
        verifyMultipleSize(view: view, extraLayoutPass: extraLayoutPass, inSizes: XCTestCase.phoneScreenSizes, configuration: { view, _ in
            configuration?(view)
        }, file: file, line: line)
    }

    func verifyInAllDeviceSizes(view: UIView,
                                extraLayoutPass: Bool = false,
                                file: StaticString = #file,
                                line: UInt = #line,
                                configuration: ConfigurationWithDeviceType? = nil) {

        verifyMultipleSize(view: view,
                           extraLayoutPass: extraLayoutPass,
                           inSizes: XCTestCase.deviceScreenSizes,
                           configuration: configuration,
                           file: file,
                           line: line)
    }

}
