//
//  HeightsCalculator.swift
//  Wire-iOS
//
//  Created by Nicola Giancecchi on 22.09.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation

@objc class HeightsProvider: NSObject {
    
    static let standardCellHeight : CGFloat = 200.0
    static let compressedCellHeight : CGFloat = 160.0
    static let videoViewHeight : CGFloat = 160.0
    
    static func heightForImage(_ image: UIImage?) -> CGFloat {
        var height : CGFloat = 0.0
        if let image = image, image.size.height < standardCellHeight {
            height = image.size.height
        } else {
            height = standardCellHeight
        }
        return getFinalHeight(for: height)
    }
    
    static func heightForVideo() -> CGFloat {
        return getFinalHeight(for: videoViewHeight)
    }
    
    static func compressedSizeForView(_ view: UIView) -> CGFloat {
        return view.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height;
    }
    
    private static func getFinalHeight(for height: CGFloat) -> CGFloat {
        return min((UIScreen.isCompact() ? compressedCellHeight : standardCellHeight), height)
    }
}
