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


final class MetaStreamContainer {
    
    var bytes = Data()
    
    var stringContent: String? {
        return String(data: bytes, encoding: String.Encoding.utf8)
    }
    
    var head: String? {
        guard let content = stringContent else { return nil }
        let startRange = content.range(of: OpenGraphXMLNode.headStart.rawValue)
        let endRange = content.range(of: OpenGraphXMLNode.headEnd.rawValue)
        
        guard let start = startRange?.lowerBound, let end = endRange?.upperBound else { return nil }
        let result = content.characters[start..<end].map { String($0) }.joined(separator: "")
        return result
    }
    
    var reachedEndOfHead = false
    
    @discardableResult func addData(_ data: Data) -> Data {
        updateReachedEndOfHead(withData: data)
        bytes.append(data)
        return bytes as Data
    }

    private func updateReachedEndOfHead(withData data: Data) {
        guard let string = String(data: data, encoding: String.Encoding.utf8)?.lowercased() else { return }
        if string.contains(OpenGraphXMLNode.headEnd.rawValue) {
            reachedEndOfHead = true
        }
    }

}
