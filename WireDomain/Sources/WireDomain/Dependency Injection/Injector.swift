//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

protocol OptionalProtocol {
    static var wrappedType: Any.Type { get }
}

extension Optional: OptionalProtocol {
    public static var wrappedType: Any.Type {
        Wrapped.self
    }
}

enum Injector {
    private nonisolated(unsafe) static var services: [ServiceKey: ServiceEntryProtocol] = [:]

    // MARK: - Register

    static func register<Service>(
        _ serviceType: Service.Type,
        factory: @escaping () -> Service
    ) {
        _register(serviceType, factory: factory)
    }

    static func register<Service, Arg1>(
        _ serviceType: Service.Type,
        factory: @escaping (Arg1) -> Service
    ) {
        _register(serviceType, factory: factory)
    }

    static func register<Service, Arg1, Arg2>(
        _ serviceType: Service.Type,
        factory: @escaping (Arg1, Arg2) -> Service
    ) {
        _register(serviceType, factory: factory)
    }

    static func register<Service, Arg1, Arg2, Arg3>(
        _ serviceType: Service.Type,
        factory: @escaping (Arg1, Arg2, Arg3) -> Service
    ) {
        _register(serviceType, factory: factory)
    }

    static func register<Service, Arg1, Arg2, Arg3, Arg4>(
        _ serviceType: Service.Type,
        factory: @escaping (Arg1, Arg2, Arg3, Arg4) -> Service
    ) {
        _register(serviceType, factory: factory)
    }

    static func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5>(
        _ serviceType: Service.Type,
        factory: @escaping (Arg1, Arg2, Arg3, Arg4, Arg5) -> Service
    ) {
        _register(serviceType, factory: factory)
    }

    static func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(
        _ serviceType: Service.Type,
        factory: @escaping (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) -> Service
    ) {
        _register(serviceType, factory: factory)
    }

    private static func _register<Service, Arguments>(
        _ serviceType: Service.Type,
        factory: @escaping (Arguments) -> Any
    ) {

        let key = ServiceKey(serviceType: Service.self, argumentsType: Arguments.self)

        let entry = ServiceEntry(
            serviceType: serviceType,
            argumentsType: Arguments.self,
            factory: factory
        )
        services[key] = entry
    }

    // MARK: - Resolve

    static func resolve<Service>() -> Service {
        typealias FactoryType = () -> Any
        return _genericResolve(serviceType: Service.self) { (factory: FactoryType) in
            factory(())
        }
    }

    static func resolve<Service, Arg1>(
        argument: Arg1
    ) -> Service {
        typealias FactoryType = (Arg1) -> Any
        return _genericResolve(serviceType: Service.self) { (factory: FactoryType) in
            factory(argument)
        }
    }

    static func resolve<Service, Arg1, Arg2>(
        arguments arg1: Arg1, _ arg2: Arg2
    ) -> Service {
        typealias FactoryType = ((Arg1, Arg2)) -> Any
        return _genericResolve(serviceType: Service.self) { (factory: FactoryType) in
            factory((arg1, arg2))
        }
    }

    static func resolve<Service, Arg1, Arg2, Arg3>(
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3
    ) -> Service {
        typealias FactoryType = ((Arg1, Arg2, Arg3)) -> Any
        return _genericResolve(serviceType: Service.self) { (factory: FactoryType) in
            factory((arg1, arg2, arg3))
        }
    }

    static func resolve<Service, Arg1, Arg2, Arg3, Arg4>(
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4
    ) -> Service {
        typealias FactoryType = ((Arg1, Arg2, Arg3, Arg4)) -> Any
        return _genericResolve(serviceType: Service.self) { (factory: FactoryType) in
            factory((arg1, arg2, arg3, arg4))
        }
    }

    static func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5>(
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5
    ) -> Service {
        typealias FactoryType = ((Arg1, Arg2, Arg3, Arg4, Arg5)) -> Any
        return _genericResolve(serviceType: Service.self) { (factory: FactoryType) in
            factory((arg1, arg2, arg3, arg4, arg5))
        }
    }

    static func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6
    ) -> Service {
        typealias FactoryType = ((Arg1, Arg2, Arg3, Arg4, Arg5, Arg6)) -> Any
        return _genericResolve(serviceType: Service.self) { (factory: FactoryType) in
            factory((arg1, arg2, arg3, arg4, arg5, arg6))
        }
    }

    static func _genericResolve<Service, Arguments>(
        serviceType: Service.Type,
        invoker: @escaping ((Arguments) -> Any) -> Any
    ) -> Service {
        var resolvedInstance: Service?
        var type: Any.Type = if let optionalType = Service.self as? OptionalProtocol.Type {
            optionalType.wrappedType
        } else {
            Service.self
        }

        let key = ServiceKey(serviceType: type, argumentsType: Arguments.self)

        if let entry = services[key] {
            resolvedInstance = resolve(entry: entry, invoker: invoker)
        }

        if let resolvedInstance {
            return resolvedInstance
        } else {
            fatalError("You need to register concrete type for \(Service.self)")
        }
    }

    private static func resolve<Service, Factory>(
        entry: ServiceEntryProtocol,
        invoker: (Factory) -> Any
    ) -> Service? {
        let resolvedInstance = invoker(entry.factory as! Factory)
        return resolvedInstance as? Service
    }
}
