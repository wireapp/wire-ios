//
//  String+WireLocales.swift
//  Wire-iOS
//
//  Created by Kevin Taniguchi on 9/18/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation


extension NSString {
    
    var uppercasedWithCurrentLocale: String? {
        return uppercased(with: NSLocale.current)
    }
    
    var lowercasedWithCurrentLocale: String? {
        return lowercased(with: NSLocale.current)
    }
    
    private var slashCommandMatcher: NSRegularExpression? {
        struct Singleton {
            static let sharedInstance = try? NSRegularExpression(pattern: "^\\/", options: [])
        }
        return Singleton.sharedInstance
    }
    
    var matchesSlashCommand: Bool {
        let range = NSMakeRange(0, length)
        return slashCommandMatcher?.matches(in: self as String, options: [], range: range).count > 0
    }
    
    var args: [String]? {
        guard self.matchesSlashCommand else {
            return []
        }
        
        let slashlessString = replacingCharacters(in: NSMakeRange(0, 1), with: "")
        return slashlessString.components(separatedBy: CharacterSet.whitespaces)
    }
}
