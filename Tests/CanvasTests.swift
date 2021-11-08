//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import FBSnapshotTestCase
@testable import WireCanvas

final class CanvasTests: FBSnapshotTestCase {
    
    func testTrimmedImage_isClippedToViewport() {
        // given
        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 375, height: 667))
        let canvas = Canvas(frame: frame)
        let image = UIImage(testImageNamed: "unsplash_small.jpg")!
        
        // when placing image half way outside the viewport
        canvas.insert(image: image, at: CGPoint(x: -image.size.width / 2, y: frame.midY))
        
        // then it should be clipped by the viewport
        let imageView = UIImageView(image: canvas.trimmedImage)
        FBSnapshotVerifyView(imageView)
    }
    
    func testTrimmedImage_isClippedToViewport_withReferenceImage() {
        // given
        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 375, height: 667))
        let canvas = Canvas(frame: frame)
        
        canvas.referenceImage = UIImage(testImageNamed: "unsplash_matterhorn.jpg")!
        let image = UIImage(testImageNamed: "unsplash_small.jpg")!
        
        // when placing image half way outside the viewport
        canvas.insert(image: image, at: CGPoint(x: -image.size.width / 2, y: frame.midY - image.size.height / 2))
        
        // then it should be clipped by the viewport
        let imageView = UIImageView(image: canvas.trimmedImage)
        FBSnapshotVerifyView(imageView)
    }
    
}
