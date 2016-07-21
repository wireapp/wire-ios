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
import AwesomeTableAnimationCalculator
import CocoaLumberjackSwift

private class ConversationListSectionModel: ASectionModel, Equatable {
    private let index: UInt
    
    private init(index: UInt) {
        self.index = index
        super.init()
    }
}

private func ==(lhs: ConversationListSectionModel, rhs: ConversationListSectionModel) -> Bool {
    return lhs.index == rhs.index
}

private struct ConversationListCellModel: ACellModel {
    private let item: NSObject
    private let index: UInt
    private let sectionIndex: UInt
    
    init(item: NSObject, index: UInt, sectionIndex: UInt) {
        self.item = item
        self.index = index
        self.sectionIndex = sectionIndex
    }
    
    private init(copy other: ConversationListCellModel) {
        self.item = other.item
        self.index = other.index
        self.sectionIndex = other.sectionIndex
    }

    private func contentIsSameAsIn(another: ConversationListCellModel) -> Bool {
        if self.sectionIndex != another.sectionIndex {
            return false
        }
        
        if self.item != another.item {
            return false
        }
        
        return true
    }
}

private func ==(lhs: ConversationListCellModel, rhs: ConversationListCellModel) -> Bool {
    if lhs.sectionIndex != rhs.sectionIndex {
        return false
    }
    
    if lhs.item != rhs.item {
        return false
    }
    
    return true
}

private class ConversationListCellSectionModel: ACellSectionModel {
    required init() {
    }
    
    func cellsHaveSameSection(one one:ConversationListCellModel, another:ConversationListCellModel) -> Bool {
        return one.sectionIndex == another.sectionIndex
    }
    
    func createSection(forCell cell:ConversationListCellModel) -> ConversationListSectionModel {
        return ConversationListSectionModel(index: cell.sectionIndex)
    }
}


@objc public class ConversationListUpdateCalculator: NSObject {
    private let backingUpdateCalculator = ATableAnimationCalculator(cellSectionModel: ConversationListCellSectionModel())
    
    override init() {
        backingUpdateCalculator.cellModelComparator = { left, right in
            return left.sectionIndex < right.sectionIndex
                ? true
                : left.sectionIndex > right.sectionIndex
                ? false
                : left.index < right.index
        }
    }
}


private extension ConversationListViewModel {
    private func itemsModel() -> [ConversationListCellModel] {
        return (0..<self.sectionCount).flatMap { sectionIndex in
            self.sectionAtIndex(sectionIndex).enumerate().map { (index, item) in
                ConversationListCellModel(item: item as! NSObject, index: UInt(index), sectionIndex: sectionIndex)
            }
        }
    }
}

extension ConversationListContentController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func createUpdateCalculator() {
        self.updateCalculator = ConversationListUpdateCalculator()
        self.updateItemsAnimated(false)
    }
    
    public func updateItemsAnimated(animated: Bool, completion: (Void -> Void)? = .None) {
        guard let collectionView = self.collectionView else {
            return
        }
        
        do {
            let changeset = try self.updateCalculator.backingUpdateCalculator.setItems(self.listViewModel.itemsModel())
            if animated {
                changeset.applyTo(collectionView: collectionView, completionHandler: completion)
            }
            else {
                collectionView.reloadData()
                completion?()
            }
        }
        catch let error {
            DDLogError("Cannot update collection view: \(error)")
            self.reload()
            completion?()
        }
    }
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.updateCalculator.backingUpdateCalculator.sectionsCount()
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.updateCalculator.backingUpdateCalculator.itemsCount(inSection:section)
    }

    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let item = self.updateCalculator.backingUpdateCalculator.item(forIndexPath:indexPath)
        return self.cellForItem(item.item, indexPath: indexPath)
    }

    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let item = self.updateCalculator.backingUpdateCalculator.item(forIndexPath:indexPath)
        self.didSelectItem(item.item)
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let height = WAZUIMagic.floatForIdentifier("list.tile_height")
        return CGSizeMake(CGRectGetWidth(self.view.bounds), CGFloat(height))
    }
}
