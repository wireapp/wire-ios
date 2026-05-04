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

@preconcurrency import KaliumBackup

extension Array where Element: AnyObject {

    init(_ pager: BackupImportDataPager<Element>) {

        var elements = [Element]()
        while pager.hasMorePages() {
            let page = pager.nextPage()
            elements += [Element](page)
        }
        self = elements

    }

    private init(_ page: KotlinArray<Element>) {

        var elements = [Element]()
        if let capacity = Int(exactly: page.size) {
            elements.reserveCapacity(capacity)
        }
        for index in 0 ..< page.size {
            guard let element = page.get(index: index) else { continue }
            elements += [element]
        }
        self = elements

    }

}
