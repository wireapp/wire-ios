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
    
    typealias ParserCompletion = OpenGraphData? -> Void
    
    let xmlString: String
    var contentsByProperty = [OpenGraphPropertyType: String]()
    var images = [String]()
    var completion: ParserCompletion
    var originalURL: NSURL
    
    init(_ xmlString: String, url: NSURL, completion: ParserCompletion) {
        self.xmlString = xmlString
        self.completion = completion
        originalURL = url
        super.init()
    }
    
    func parse() {
        guard let document = try? ONOXMLDocument(string: xmlString, encoding: NSUTF8StringEncoding) else { return }
        parseXML(document)
        createObjectAndComplete(document)
    }

    private func parseXML(xmlDocument: ONOXMLDocument) {
        xmlDocument.enumerateElementsWithXPath("//meta", usingBlock: { [weak self] (element, _, _) in
            guard let `self` = self,
                property = element[OpenGraphAttribute.Property.rawValue] as? String,
                content = element[OpenGraphAttribute.Content.rawValue] as? String,
                type = OpenGraphPropertyType(rawValue: property) else { return }

            self.addProperty(type, value: content)
        })
    }
    
    func addProperty(property: OpenGraphPropertyType, value: String) {
        guard let content = value.resolvingXMLEntityReferences() else { return }
        if property == .Image {
            images.append(content)
        } else {
            contentsByProperty[property] = content
        }
    }

    func createObjectAndComplete(xmlDocument: ONOXMLDocument) {
        insertMissingUrlIfNeeded()
        insertMissingTitleIfNeeded(xmlDocument)
        let data = OpenGraphData(propertyMapping: contentsByProperty, images: images)
        completion(data)
    }

    func insertMissingUrlIfNeeded() {
        guard !contentsByProperty.keys.contains(.Url) else { return }
        contentsByProperty[.Url] = originalURL.absoluteString
    }

    func insertMissingTitleIfNeeded(xmlDocument: ONOXMLDocument) {
        guard !contentsByProperty.keys.contains(.Title) else { return }

        xmlDocument.enumerateElementsWithXPath("//title", usingBlock: { [weak self] (element, _, _) in
            guard let `self` = self else { return }
            self.addProperty(.Title, value: element.stringValue())
        })
    }
}
