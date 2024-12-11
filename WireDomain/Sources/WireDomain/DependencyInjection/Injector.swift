//
//  Injector.swift
//
//
//  Created by Jullian Mercier on 06/05/2022.
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

final class Injector {
    nonisolated(unsafe) static private(set) public var shared = Injector()
    private var services: [ServiceKey: ServiceEntryProtocol] = [:]
    
    // MARK: - Object lifecycle
    
    private init() {}
    
    
    // MARK: - Register
    
    @discardableResult
    func register<Service>(_ serviceType: Service.Type, factory: @escaping () -> Service) -> ServiceEntry<Service> {
        return _register(serviceType, factory: factory)
    }
    
    @discardableResult
    func register<Service, Arg1>(_ serviceType: Service.Type, factory: @escaping (Arg1) -> Service) -> ServiceEntry<Service> {
        return _register(serviceType, factory: factory)
    }
    
    @discardableResult
    func register<Service, Arg1, Arg2>(_ serviceType: Service.Type, factory: @escaping (Arg1, Arg2) -> Service) -> ServiceEntry<Service> {
        return _register(serviceType, factory: factory)
    }
    
    @discardableResult
    func register<Service, Arg1, Arg2, Arg3>(_ serviceType: Service.Type, factory: @escaping (Arg1, Arg2, Arg3) -> Service) -> ServiceEntry<Service> {
        return _register(serviceType, factory: factory)
    }
    
    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4>(_ serviceType: Service.Type, factory: @escaping (Arg1, Arg2, Arg3, Arg4) -> Service) -> ServiceEntry<Service> {
        return _register(serviceType, factory: factory)
    }
    
    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5>(_ serviceType: Service.Type, factory: @escaping (Arg1, Arg2, Arg3, Arg4, Arg5) -> Service) -> ServiceEntry<Service> {
        return _register(serviceType, factory: factory)
    }
    
    private func _register<Service, Arguments>(_ serviceType: Service.Type, factory: @escaping (Arguments) -> Any) -> ServiceEntry<Service> {
        let key = ServiceKey(serviceType: Service.self, argumentsType: Arguments.self)
        let entry = ServiceEntry(
            serviceType: serviceType,
            argumentsType: Arguments.self,
            factory: factory
        )
        services[key] = entry

        return entry
    }
    
    
    // MARK: - Resolve
    
    func resolve<Service>() -> Service {
        typealias FactoryType = ((Void)) -> Any
        return _genericResolve(serviceType: Service.self) { (factory: FactoryType) in factory(()) }
    }
    
    func resolve<Service, Arg1>(argument: Arg1) -> Service {
        typealias FactoryType = ((Arg1)) -> Any
        return _genericResolve(serviceType: Service.self) { (factory: FactoryType) in factory((argument)) }
    }
    
    func resolve<Service, Arg1, Arg2>(arguments arg1: Arg1, _ arg2: Arg2) -> Service {
        typealias FactoryType = ((Arg1, Arg2)) -> Any
        return _genericResolve(serviceType: Service.self) { (factory: FactoryType) in factory((arg1, arg2)) }
    }
    
    func resolve<Service, Arg1, Arg2, Arg3>(arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3) -> Service {
        typealias FactoryType = ((Arg1, Arg2, Arg3)) -> Any
        return _genericResolve(serviceType: Service.self) { (factory: FactoryType) in factory((arg1, arg2, arg3)) }
    }
    
    func resolve<Service, Arg1, Arg2, Arg3, Arg4>(arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4) -> Service {
        typealias FactoryType = ((Arg1, Arg2, Arg3, Arg4)) -> Any
        return _genericResolve(serviceType: Service.self) { (factory: FactoryType) in factory((arg1, arg2, arg3, arg4)) }
    }
    
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5>(arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5) -> Service {
        typealias FactoryType = ((Arg1, Arg2, Arg3, Arg4, Arg5)) -> Any
        return _genericResolve(serviceType: Service.self) { (factory: FactoryType) in factory((arg1, arg2, arg3, arg4, arg5)) }
    }
    
    func _genericResolve<Service, Arguments>(serviceType: Service.Type, invoker: @escaping ((Arguments) -> Any) -> Any) -> Service {
        var resolvedInstance: Service?
        var type: Any.Type
        
        if let optionalType = Service.self as? OptionalProtocol.Type {
            type = optionalType.wrappedType
        } else {
            type = Service.self
        }
        
        let key = ServiceKey(serviceType: type, argumentsType: Arguments.self)

        if let entry = services[key] {
            resolvedInstance = resolve(entry: entry, invoker: invoker)
        }

        if let resolvedInstance = resolvedInstance {
            return resolvedInstance
        } else {
            fatalError("You need to register concrete type for \(Service.self)")
        }
    }
    
    private func resolve<Service, Factory>(entry: ServiceEntryProtocol, invoker: (Factory) -> Any) -> Service? {
        let resolvedInstance = invoker(entry.factory as! Factory)
        return resolvedInstance as? Service
    }
}

