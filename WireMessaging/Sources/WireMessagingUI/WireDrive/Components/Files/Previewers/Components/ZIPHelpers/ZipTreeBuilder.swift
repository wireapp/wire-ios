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

import Foundation
import ZIPFoundation

enum ZipTreeBuilder {
    static func build(from url: URL) throws -> ZipNode {
        let archive = try Archive(
            url: url,
            accessMode: .read
        )

        var root = ZipNode(
            name: "Root",
            path: "",
            children: [],
            isDirectory: true
        )

        for entry in archive {
            let path = entry.path

            // Skip macOS metadata
            if shouldIgnore(path: path) { continue }

            insert(path, into: &root)
        }

        return root
    }

    private static func insert(
        _ path: String,
        into node: inout ZipNode
    ) {
        let parts = path
            .split(separator: "/")
            .map(String.init)

        insert(
            parts,
            fullPath: path,
            into: &node
        )
    }

    private static func insert(
        _ parts: [String],
        fullPath: String,
        into node: inout ZipNode
    ) {
        guard let first = parts.first else {
            return
        }

        if parts.count == 1 {
            let isDirectory =
                fullPath.hasSuffix("/")

            node.children.append(
                ZipNode(
                    name: first,
                    path: fullPath,
                    children: [],
                    isDirectory: isDirectory
                )
            )
            return
        }

        if let index = node.children.firstIndex(where: { $0.name == first && $0.isDirectory }) {
            var child = node.children[index]

            insert(
                Array(parts.dropFirst()),
                fullPath: fullPath,
                into: &child
            )

            node.children[index] = child
        } else {
            var folder = ZipNode(
                name: first,
                path: first,
                children: [],
                isDirectory: true
            )

            insert(
                Array(parts.dropFirst()),
                fullPath: fullPath,
                into: &folder
            )

            node.children.append(folder)
        }
    }

    /// Returns whether a ZIP entry should be ignored.
    ///
    /// Filters macOS-specific metadata commonly found in ZIP archives,
    /// including `__MACOSX`, `.DS_Store`, and AppleDouble (`._*`) files.
    private static func shouldIgnore(path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        let name = url.lastPathComponent

        if path.contains("__MACOSX") {
            return true
        }

        if name == ".DS_Store" {
            return true
        }

        if name.hasPrefix("._") {
            return true
        }

        return false
    }
}
