//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension XCTestCase {

    func dataInTestBundleNamed(_ name: String) -> Data {
        return try! Data(contentsOf: urlForResource(inTestBundleNamed: name))
    }

    func image(inTestBundleNamed name: String) -> UIImage {
        return UIImage(contentsOfFile: urlForResource(inTestBundleNamed: name).path)!
    }

    func urlForResource(inTestBundleNamed name: String) -> URL {
        let bundle = Bundle(for: type(of: self))

        let url = bundle.url(forResource: name, withExtension: "")

        if let isFileURL = url?.isFileURL {
            XCTAssert(isFileURL)
        } else {
            XCTFail("\(name) does not exist")
        }

        return url!
    }

    var mockImageData: Data {
        return image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9)!
    }
}

extension UIImage {
    public convenience init?(inTestBundleNamed name: String,
                             for aClass: AnyClass) {

        let bundle = Bundle(for: aClass)

        let url = bundle.url(forResource: name, withExtension: "")

        if let isFileURL = url?.isFileURL {
            XCTAssert(isFileURL)
        } else {
            XCTFail("\(name) does not exist")
        }

        self.init(contentsOfFile: url!.path)!
    }

}
