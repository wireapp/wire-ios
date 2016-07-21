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


import UIKit

class PreviewImagesViewController: UIViewController, UIScrollViewDelegate {
    
    /// MARK: - Module interface
    
    internal var numberOfPreviewImages: Int = 0 {
        didSet {
            self.setupPreviewImageViewsForPreviewCount(numberOfPreviewImages)
            self.previewImagesPageControl.numberOfPages = numberOfPreviewImages
            self.previewImagesPageControl.currentPage = 0
        }
    }
    
    internal func setImage(image: UIImage?, forPreviewAtIndex index: Int) {
        self.previewImageViews[index].image = image
    }
    
    /// MARK: - IBOutlets
    
    @IBOutlet private weak var previewImagesScrollView: UIScrollView!
    @IBOutlet private weak var previewImagesPageControl: UIPageControl!
    
    private var previewImageViews = Array<UIImageView>()

    /// MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Layout
    
    internal var previewImageSize: CGFloat {
        get {
            return 70
        }
    }
    
    private func rectForPreviewImageAtIndex(index: Int) -> CGRect {
        let offset: CGFloat = 2
        let imageSize = self.previewImageSize
        let offsetedImageSize: CGFloat = imageSize - 2.0 * offset
        return CGRectMake(offset + CGFloat(index) * imageSize, offset, offsetedImageSize, offsetedImageSize)
    }
    
    private func setupPreviewImageViewsForPreviewCount(count:Int) {
        for view in self.previewImageViews {
            view.removeFromSuperview()
        }
        self.previewImageViews.removeAll(keepCapacity: true)
        
        let imageSize = self.previewImageSize
        self.previewImagesScrollView.contentSize = CGSizeMake(imageSize * CGFloat(count), imageSize)
        for var i = 0; i < count; i++ {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = true
            imageView.contentMode = .ScaleAspectFill
            imageView.clipsToBounds = true
            self.previewImagesScrollView.addSubview(imageView)
            self.previewImageViews.append(imageView)
            imageView.frame = self.rectForPreviewImageAtIndex(i)
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func pageControllPressed(sender: AnyObject) {
        let index = self.previewImagesPageControl.currentPage
        self.previewImagesScrollView.scrollRectToVisible(self.rectForPreviewImageAtIndex(index), animated: true)
    }
    
    @IBAction func tapToScroll(sender: AnyObject) {
        let newPage = (self.previewImagesPageControl.currentPage + 1) % self.numberOfPreviewImages
        self.previewImagesScrollView.scrollRectToVisible(self.rectForPreviewImageAtIndex(newPage),
            animated: false)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView == self.previewImagesScrollView) {
            // + 0.5 makes page to be changed on the middle of transition
            let numberOfPage = Int(CGFloat(self.previewImageViews.count) * (scrollView.contentOffset.x / scrollView.contentSize.width) + 0.5)
            self.previewImagesPageControl.currentPage = numberOfPage
        }
    }

}
