//
//  Dictionary+Mapping.swift
//  ZMCDataModel
//
//  Created by Sabine Geithner on 26/01/17.
//  Copyright © 2017 Wire Swiss GmbH. All rights reserved.
//

import Foundation

extension Dictionary {
    
    public init(keys: [Key], repeatedValue: Value) {
        self.init()
        for key in keys {
            updateValue(repeatedValue, forKey: key)
        }
    }
    
    public func mapping<NewKey, NewValue>(keysMapping: ((Key) -> NewKey), valueMapping: ((Key, Value) -> NewValue?)) -> Dictionary<NewKey, NewValue> {
        var dict = Dictionary<NewKey, NewValue>()
        for (key, value) in self {
            if let newValue = valueMapping(key, value) {
                dict.updateValue(newValue, forKey: keysMapping(key))
            }
        }
        return dict
    }
    
    public func updated(other:Dictionary) -> Dictionary {
        var newDict = self
        for (key,value) in other {
            newDict.updateValue(value, forKey:key)
        }
        return newDict
    }
}


extension Array where Element : Hashable {
    
    public func mapToDictionary<Value>(with block: (Element) -> Value?) -> Dictionary<Element, Value> {
        var dict = Dictionary<Element, Value>()
        forEach {
            if let value = block($0) {
                dict.updateValue(value, forKey: $0)
            }
        }
        return dict
    }
    public func mapToDictionaryWithOptionalValue<Value>(with block: (Element) -> Value?) -> Dictionary<Element, Value?> {
        var dict = Dictionary<Element, Value?>()
        forEach {
            dict.updateValue(block($0), forKey: $0)
        }
        return dict
    }
}

extension Set {
    
    public func mapToDictionary<Value>(with block: (Element) -> Value?) -> Dictionary<Element, Value> {
        var dict = Dictionary<Element, Value>()
        forEach {
            if let value = block($0) {
                dict.updateValue(value, forKey: $0)
            }
        }
        return dict
    }
}

public protocol Mergeable {
    func merged(with other: Self) -> Self
}

extension Dictionary where Value : Mergeable {
    
    public func merged(with other: Dictionary) -> Dictionary {
        var newDict = self
        other.forEach{ (key, value) in
            newDict[key] = newDict[key]?.merged(with: value) ?? value
        }
        return newDict
    }
}


