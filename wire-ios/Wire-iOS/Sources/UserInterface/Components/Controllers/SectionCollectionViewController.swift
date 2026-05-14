//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireSystem

protocol CollectionViewSectionController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var isHidden: Bool { get }

    func prepareForUse(in collectionView: UICollectionView?)

}

final class SectionCollectionViewController: NSObject {

    var collectionView: UICollectionView? {
        didSet {
            collectionView?.dataSource = self
            collectionView?.delegate = self

            sections.forEach {
                $0.prepareForUse(in: collectionView)
            }

            collectionView?.reloadData()
        }
    }

    var sections: [CollectionViewSectionController] {
        didSet {
            sections.forEach {
                $0.prepareForUse(in: collectionView)
            }

            collectionView?.reloadData()
        }
    }

    var visibleSections: [CollectionViewSectionController] {
        state.visibleSections
    }

    var isEmpty: Bool {
        state.isEmpty
    }

    init(sections: [CollectionViewSectionController] = []) {
        self.sections = sections
    }

    private var state: SectionCollectionViewState {
        SectionCollectionViewState(sections: sections)
    }
}

private struct SectionCollectionViewState {

    let sections: [CollectionViewSectionController]

    var visibleSections: [CollectionViewSectionController] {
        sections.filter { !$0.isHidden }
    }

    var numberOfSections: Int {
        visibleSections.count
    }

    var isEmpty: Bool {
        visibleSections.isEmpty
    }

    func section(at index: Int) -> CollectionViewSectionController? {
        let currentVisibleSections = visibleSections
        guard currentVisibleSections.indices.contains(index) else { return nil }

        return currentVisibleSections[index]
    }
}

extension SectionCollectionViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let section = state.section(at: indexPath.section) else { return true }

        return section.collectionView?(collectionView, shouldHighlightItemAt: indexPath) ?? true
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let section = state.section(at: indexPath.section) else { return true }

        return section.collectionView?(collectionView, shouldSelectItemAt: indexPath) ?? true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = state.section(at: indexPath.section) else { return }

        section.collectionView?(collectionView, didSelectItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let section = state.section(at: indexPath.section) else { return }

        section.collectionView?(collectionView, didDeselectItemAt: indexPath)
    }

}

extension SectionCollectionViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        state.numberOfSections
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let section = state.section(at: indexPath.section) else { return }

        section.collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sectionController = state.section(at: section) else { return 0 }

        return sectionController.collectionView(collectionView, numberOfItemsInSection: 0)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let section = state.section(at: indexPath.section) else {
            fatal("Unknown section, indexPath: \(indexPath)")
        }

        return section.collectionView(collectionView, cellForItemAt: indexPath)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard let section = state.section(at: indexPath.section) else {
            fatal("Unknown section, indexPath: \(indexPath)")
        }

        return section.collectionView!(
            collectionView,
            viewForSupplementaryElementOfKind: kind,
            at: indexPath
        )
    }

}

extension SectionCollectionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        state.visibleSections[section].collectionView?(
            collectionView,
            layout: collectionViewLayout,
            referenceSizeForHeaderInSection: section
        ) ?? .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        state.visibleSections[section].collectionView?(
            collectionView,
            layout: collectionViewLayout,
            referenceSizeForFooterInSection: section
        ) ?? .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        state.visibleSections[indexPath.section].collectionView?(
            collectionView,
            layout: collectionViewLayout,
            sizeForItemAt: indexPath
        ) ?? .zero
    }

}
