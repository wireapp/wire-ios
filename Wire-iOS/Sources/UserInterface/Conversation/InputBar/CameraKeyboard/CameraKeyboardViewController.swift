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


import Foundation
import Photos
import Cartography

@objc public protocol CameraKeyboardViewControllerDelegate: NSObjectProtocol {
    func cameraKeyboardViewController(controller: CameraKeyboardViewController, didSelectAsset: PHAsset)
    func cameraKeyboardViewController(controller: CameraKeyboardViewController, didSelectImageData: NSData)
    func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(controller: CameraKeyboardViewController)
    func cameraKeyboardViewControllerWantsToOpenCameraRoll(controller: CameraKeyboardViewController)
}


public class CameraKeyboardViewController: UIViewController {
    private let assetLibrary = AssetLibrary()
    
    private let collectionViewLayout = UICollectionViewFlowLayout()
    private var collectionView: UICollectionView!
    
    private let leftSidebarView = UIView()
    private let goBackButton = IconButton()
    private let rightSidebarView = UIView()
    private let cameraRollButton = IconButton()
    private var lastLayoutSize = CGSizeZero

    private var leftSidebarRevealed: Bool = false {
        didSet {
            self.leftSidebarView.hidden = !self.leftSidebarRevealed
        }
    }
    
    public let splitLayoutObservable: SplitLayoutObservable
    
    private enum CameraKeyboardSection: UInt {
        case Camera = 0, Photos = 1
    }

    public weak var delegate: CameraKeyboardViewControllerDelegate?

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @objc init(splitLayoutObservable: SplitLayoutObservable) {
        self.splitLayoutObservable = splitLayoutObservable
        super.init(nibName: nil, bundle: nil)
        self.assetLibrary.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(splitLayoutChanged(_:)), name: SplitLayoutObservableDidChangeToLayoutSizeNotification, object: self.splitLayoutObservable)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !CGSizeEqualToSize(self.lastLayoutSize, self.view.bounds.size) {
            self.lastLayoutSize = self.view.bounds.size
            self.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.createCollectionView()
        
        self.view.backgroundColor = UIColor.blackColor()
        self.view.addSubview(self.collectionView)
        
        self.leftSidebarView.translatesAutoresizingMaskIntoConstraints = false
        self.leftSidebarView.backgroundColor = UIColor(white: 0, alpha: 0.88)
        self.view.addSubview(self.leftSidebarView)
        
        self.goBackButton.translatesAutoresizingMaskIntoConstraints = false
        self.goBackButton.setIcon(.BackArrow, withSize: .Tiny, forState: .Normal)
        self.goBackButton.setIconColor(UIColor.whiteColor(), forState: .Normal)
        self.goBackButton.accessibilityIdentifier = "goBackButton"
        self.goBackButton.addTarget(self, action: #selector(goBackPressed(_:)), forControlEvents: .TouchUpInside)
        self.leftSidebarView.addSubview(self.goBackButton)
        
        self.rightSidebarView.translatesAutoresizingMaskIntoConstraints = false
        self.rightSidebarView.backgroundColor = UIColor(white: 0, alpha: 0.88)
        self.view.addSubview(self.rightSidebarView)
        
        self.cameraRollButton.translatesAutoresizingMaskIntoConstraints = false
        self.cameraRollButton.setIcon(.Photo, withSize: .Tiny, forState: .Normal)
        self.cameraRollButton.setIconColor(UIColor.whiteColor(), forState: .Normal)
        self.cameraRollButton.accessibilityIdentifier = "cameraRollButton"
        self.cameraRollButton.addTarget(self, action: #selector(openCameraRollPressed(_:)), forControlEvents: .TouchUpInside)
        self.rightSidebarView.addSubview(self.cameraRollButton)
        
        constrain(self.view, self.collectionView, self.leftSidebarView, self.rightSidebarView) { view, collectionView, leftSidebarView, rightSidebarView in
            collectionView.edges == view.edges
            
            leftSidebarView.left == view.left
            leftSidebarView.top == view.top
            leftSidebarView.bottom == view.bottom
            leftSidebarView.width == 48
            
            rightSidebarView.right == view.right
            rightSidebarView.top == view.top
            rightSidebarView.bottom == view.bottom
            rightSidebarView.width == 48
        }
        
        constrain(self.leftSidebarView, self.goBackButton) { leftSidebarView, goBackButton in
            goBackButton.edges == leftSidebarView.edges
        }
        
        constrain(self.rightSidebarView, self.cameraRollButton) { rightSidebarView, cameraRollButton in
            cameraRollButton.edges == rightSidebarView.edges
        }
    }
    
    private func createCollectionView() {
        self.collectionViewLayout.scrollDirection = .Horizontal
        self.collectionViewLayout.minimumLineSpacing = 0
        self.collectionViewLayout.minimumInteritemSpacing = 0
        self.collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: collectionViewLayout)
        self.collectionView.registerClass(CameraCell.self, forCellWithReuseIdentifier: CameraCell.reuseIdentifier)
        self.collectionView.registerClass(AssetCell.self, forCellWithReuseIdentifier: AssetCell.reuseIdentifier)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.allowsSelection = true
        self.collectionView.backgroundColor = UIColor.clearColor()
        self.collectionView.bounces = false
    }
    
    func goBackPressed(sender: AnyObject) {
        self.collectionView.scrollRectToVisible(CGRectMake(0, 0, 10, 10), animated: true)
    }
    
    func openCameraRollPressed(sender: AnyObject) {
        self.delegate?.cameraKeyboardViewControllerWantsToOpenCameraRoll(self)
    }
    
    @objc func splitLayoutChanged(notification: NSNotification!) {
        self.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
    }
}


extension CameraKeyboardViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch CameraKeyboardSection(rawValue: UInt(section))! {
        case .Camera:
            return 1
        case .Photos:
            return Int(assetLibrary.count)
        }
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        switch CameraKeyboardSection(rawValue: UInt(indexPath.section))! {
        case .Camera:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CameraCell.reuseIdentifier, forIndexPath: indexPath) as! CameraCell
            cell.delegate = self
            return cell
        case .Photos:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(AssetCell.reuseIdentifier, forIndexPath: indexPath) as! AssetCell
            cell.asset = try! assetLibrary.asset(atIndex: UInt(indexPath.row))
            return cell
        }
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        switch CameraKeyboardSection(rawValue: UInt(indexPath.section))! {
        case .Camera:
            switch self.splitLayoutObservable.layoutSize {
            case .Compact:
                return CGSizeMake(self.view.bounds.size.width / 2, self.view.bounds.size.height)
            case .RegularPortrait:
                fallthrough
            case .RegularLandscape:
                return CGSizeMake(self.splitLayoutObservable.leftViewControllerWidth, self.view.bounds.size.height)
            }
        case .Photos:
            let photoSize = self.view.bounds.size.height / 3
            return CGSizeMake(photoSize, photoSize)
        }
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let asset = try! assetLibrary.asset(atIndex: UInt(indexPath.row))
        
        self.delegate?.cameraKeyboardViewController(self, didSelectAsset: asset)
    }
    
    public func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if cell is CameraCell {
            self.leftSidebarRevealed = true
        }
    }
    
    public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if cell is CameraCell {
            self.leftSidebarRevealed = false
        }
    }
}


extension CameraKeyboardViewController: CameraCellDelegate {
    public func cameraCellWantsToOpenFullCamera(cameraCell: CameraCell) {
        self.delegate?.cameraKeyboardViewControllerWantsToOpenFullScreenCamera(self)
    }
    
    public func cameraCell(cameraCell: CameraCell, didPickImageData imageData: NSData) {
        self.delegate?.cameraKeyboardViewController(self, didSelectImageData: imageData)
    }
}

extension CameraKeyboardViewController: AssetLibraryDelegate {
    public func assetLibraryDidChange(library: AssetLibrary) {
        self.collectionView.reloadData()
    }
}
