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

import Foundation
import WireCommonComponents

// MARK: - SettingsPropertyValue

enum SettingsPropertyValue: Equatable {
    case bool(value: Bool)
    case number(value: NSNumber)
    case string(value: String)
    case none

    init(_ bool: Bool) {
        self = .number(value: NSNumber(value: bool))
    }

    init(_ uint: UInt) {
        self = .number(value: NSNumber(value: uint))
    }

    init(_ int: Int) {
        self = .number(value: NSNumber(value: int))
    }

    init(_ int: Int16) {
        self = .number(value: NSNumber(value: int))
    }

    init(_ int: UInt32) {
        self = .number(value: NSNumber(value: int))
    }

    static func propertyValue(_ object: Any?) -> SettingsPropertyValue {
        switch object {
        case let number as NSNumber:
            SettingsPropertyValue.number(value: number)

        case let stringValue as Swift.String:
            SettingsPropertyValue.string(value: stringValue)

        default:
            .none
        }
    }

    func value() -> Any? {
        switch self {
        case let .number(value):
            value as AnyObject?
        case let .string(value):
            value as AnyObject?
        case let .bool(value):
            value as AnyObject?
        case .none:
            .none
        }
    }
}

// MARK: - SettingsProperty

///  Generic settings property
protocol SettingsProperty {
    var propertyName: SettingsPropertyName { get }
    func value() -> SettingsPropertyValue
    func set(newValue: SettingsPropertyValue) throws
    var enabled: Bool { get set }
}

extension SettingsProperty {
    func rawValue() -> Any? {
        value().value()
    }
}

/// Set value to property
///
/// - parameter property: Property to set the value on
/// - parameter expr:     Property value (raw)
func << (property: inout SettingsProperty, expr: @autoclosure () -> Any) throws {
    let value = expr()

    try property.set(newValue: SettingsPropertyValue.propertyValue(value))
}

/// Set value to property
///
/// - parameter property: Property to set the value on
/// - parameter expr:     Property value
func << (property: inout SettingsProperty, expr: @autoclosure () -> SettingsPropertyValue) throws {
    let value = expr()

    try property.set(newValue: value)
}

/// Read value from property
///
/// - parameter value:    Value to assign
/// - parameter property: Property to read the value from
func << (value: inout Any?, property: SettingsProperty) {
    value = property.rawValue()
}

// MARK: - SettingsUserDefaultsProperty

/// Generic user defaults property
final class SettingsUserDefaultsProperty: SettingsProperty {
    var enabled = true

    func set(newValue: SettingsPropertyValue) throws {
        userDefaults.set(newValue.value(), forKey: userDefaultsKey)
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: propertyName.changeNotificationName),
            object: self
        )
        trackNewValue()
    }

    func value() -> SettingsPropertyValue {
        switch userDefaults.object(forKey: userDefaultsKey) as AnyObject? {
        case let numberValue as NSNumber:
            SettingsPropertyValue.propertyValue(numberValue.intValue as AnyObject?)
        case let stringValue as String:
            SettingsPropertyValue.propertyValue(stringValue as AnyObject?)
        default:
            .none
        }
    }

    func trackNewValue() {
        Analytics.shared.tagSettingsChanged(for: propertyName, to: value())
    }

    let propertyName: SettingsPropertyName
    let userDefaults: UserDefaults

    let userDefaultsKey: String

    init(propertyName: SettingsPropertyName, userDefaultsKey: String, userDefaults: UserDefaults) {
        self.propertyName = propertyName
        self.userDefaultsKey = userDefaultsKey
        self.userDefaults = userDefaults
    }
}

typealias GetAction = (SettingsBlockProperty) -> SettingsPropertyValue
typealias SetAction = (SettingsBlockProperty, SettingsPropertyValue) throws -> Void

// MARK: - SettingsBlockProperty

/// Genetic block property
final class SettingsBlockProperty: SettingsProperty {
    var enabled = true

    let propertyName: SettingsPropertyName
    func value() -> SettingsPropertyValue {
        getAction(self)
    }

    func set(newValue: SettingsPropertyValue) throws {
        try setAction(self, newValue)
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: propertyName.changeNotificationName),
            object: self
        )
        trackNewValue()
    }

    func trackNewValue() {
        Analytics.shared.tagSettingsChanged(for: propertyName, to: value())
    }

    private let getAction: GetAction
    private let setAction: SetAction

    init(propertyName: SettingsPropertyName, getAction: @escaping GetAction, setAction: @escaping SetAction) {
        self.propertyName = propertyName
        self.getAction = getAction
        self.setAction = setAction
    }
}
