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

enum OpenGraphAttribute: String {
    case Property = "property"
    case Content = "content"
}

enum OpenGraphXMLNode: String {
    case HeadStart = "<head"
    case HeadEnd = "</head>"
}

enum OpenGraphPropertyType: String {
    case Title = "og:title"
    case Type = "og:type"
    case Image = "og:image"
    case Url = "og:url"
    case Description = "og:description"
    case SiteName = "og:site_name"
    case UserGeneratedImage = "og:image:user_generated"
    
    // MARK: Foursquare
    case LatitudeFSQ = "playfoursquare:location:latitude"
    case LongitudeFSQ = "playfoursquare:location:longitude"
}

enum OpenGraphSiteName: String {
    case Other
    case Twitter = "twitter"
    case Vimeo = "vimeo"
    case YouTube = "youtube"
    case Instagram = "instagram"
    case Foursquare = "foursquare"
    
    init?(string: String) {
        self.init(rawValue: string.lowercaseString)
    }
}

enum OpenGraphTypeType: String {
    case Article = "article"
    case Website = "website"
    case Foursqaure = "playfoursquare:venue"
    case Instagram = "instapp:photo"
}
