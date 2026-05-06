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

/// Text styles defined in Wire's design system.

public enum WireTextStyle: String, CaseIterable, Sendable {

    /// Style iOS & Figma: ?
    case largeTitle

    /// Style iOS & Figma: Title 3
    case h1

    /// Style iOS & Figma: Title 3 (bold) - Emphasized
    case h2

    /// Style iOS & Figma: Headline
    case h3

    /// Style iOS & Figma: Subheadline
    case h4

    /// Style iOS & Figma: Footnote
    case h5
    
    /// Style iOS & Figma: Body
    case body1
    
    /// Style iOS & Figma: Body 2 (custom)
    case body2
    
    /// Figma: Callout (bold) - Emphasized
    case body3
    
    /// Style iOS & Figma: Caption 1
    case subline1
    
    /// Style iOS & Figma: Caption 1 (bold) - Emphasized
    case subline2
    
    /// Style iOS & Figma: Button Small (custom)
    case buttonSmall
    
    /// Style iOS & Figma: Button Big (custom)
    case buttonBig

}
