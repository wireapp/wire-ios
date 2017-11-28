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


import Ono

final class OpenGraphScanner: NSObject {
    
    typealias ParserCompletion = (OpenGraphData?) -> Void
    
    let xmlString: String
    var contentsByProperty = [OpenGraphPropertyType: String]()
    var images = [String]()
    var completion: ParserCompletion
    var originalURL: URL
    
    init(_ xmlString: String, url: URL, completion: @escaping ParserCompletion) {
        self.xmlString = xmlString
        self.completion = completion
        originalURL = url
        super.init()
    }
    
    func parse() {
        guard let document = try? ONOXMLDocument.htmlDocument(with: xmlString, encoding: String.Encoding.utf8.rawValue) else { return }
        parseXML(document)
        createObjectAndComplete(document)
    }

    private func parseXML(_ xmlDocument: ONOXMLDocument) {
        xmlDocument.enumerateElements(withXPath: "//meta", using: { [weak self] (element, _, _) in
            guard let `self` = self,
                let property = element?[OpenGraphAttribute.property.rawValue] as? String,
                let content = element?[OpenGraphAttribute.content.rawValue] as? String,
                let type = OpenGraphPropertyType(rawValue: property) else { return }

            self.addProperty(type, value: content)
        })
    }
    
    private func addProperty(_ property: OpenGraphPropertyType, value: String) {
        guard let content = value.resolvedXMLEntityReferences() else { return }
        if property == .image {
            images.append(content)
        } else {
            contentsByProperty[property] = content
        }
    }

    private func createObjectAndComplete(_ xmlDocument: ONOXMLDocument) {
        insertMissingUrlIfNeeded()
        insertMissingTitleIfNeeded(xmlDocument)
        let data = OpenGraphData(propertyMapping: contentsByProperty, resolvedURL: originalURL, images: images)
        completion(data)
    }

    private func insertMissingUrlIfNeeded() {
        guard !contentsByProperty.keys.contains(.url) else { return }
        contentsByProperty[.url] = originalURL.absoluteString
    }

    private func insertMissingTitleIfNeeded(_ xmlDocument: ONOXMLDocument) {
        guard !contentsByProperty.keys.contains(.title) else { return }
        xmlDocument.enumerateElements(withXPath: "//title", using: { [weak self] (element, _, stop) in
            guard let `self` = self, let value = element?.stringValue() else { return }
            self.addProperty(.title, value: value)
            stop?.pointee = ObjCBool(true)
        })
    }
}
