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

import UIKit
import WireCommonComponents
import XCTest
@testable import Wire

class ZMSnapshotTestCase: XCTestCase {
    var uiMOC: NSManagedObjectContext!
    var coreDataStack: CoreDataStack!

    /// The color of the container view in which the view to
    /// be snapshot will be placed, defaults to UIColor.lightGrayColor
    var snapshotBackgroundColor: UIColor?

    /// If YES the uiMOC will have image and file caches. Defaults to NO.
    var needsCaches: Bool {
        false
    }

    var documentsDirectory: URL?

    override open func setUp() {
        super.setUp()

        XCTAssertEqual(UIScreen.main.scale, 3, "Snapshot tests need to be run on a device with a 3x scale")
        if UIDevice.current.systemVersion
            .compare("17", options: .numeric, range: nil, locale: .current) == .orderedAscending {
            XCTFail("Snapshot tests need to be run on a device running at least iOS 17")
        }
        AppRootRouter.configureAppearance()

        UIView.setAnimationsEnabled(false)
        accentColor = .red
        snapshotBackgroundColor = UIColor.clear

        do {
            documentsDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
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
        let coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: documentsDirectory!,
            inMemoryStore: true
        )

        coreDataStack.loadStores(completionHandler: { error in
            XCTAssertNil(error)
        })
        self.coreDataStack = coreDataStack
        uiMOC = coreDataStack.viewContext
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
        UIColor.setAccentOverride(nil)
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }

    func removeContentsOfDocumentsDirectory() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: documentsDirectory!,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )

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
