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
import WireDesign

final class SectionFooter: UICollectionReusableView {

    let footerView = SectionFooterView()

    var titleLabel: UILabel {
        return footerView.titleLabel
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(footerView)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.fitIn(view: self)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    static func register(collectionView: UICollectionView) {
        collectionView.register(SectionFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "SectionFooter")
    }
}

final class SectionTableFooter: UITableViewHeaderFooterView {

    let footerView = SectionFooterView()

    var titleLabel: UILabel {
        return footerView.titleLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubview(footerView)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.fitIn(view: self)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

}
