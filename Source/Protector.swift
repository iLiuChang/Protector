//
//  Protector.swift
//  Protector
//
//  Created by LC on 2024/12/6.
//

import Foundation

extension NSLocking {
    /// Executes a closure returning a value while acquiring the lock.
    ///
    /// - Parameter closure: The closure to run.
    ///
    /// - Returns: The value the closure generated.
    func around<T>(_ closure: () throws -> T) rethrows -> T {
        lock(); defer { unlock() }
        return try closure()
    }

    /// Execute a closure while acquiring the lock.
    ///
    /// - Parameter closure: The closure to run.
    func around(_ closure: () throws -> Void) rethrows {
        lock(); defer { unlock() }
        try closure()
    }
}

/// An `os_unfair_lock` wrapper.
public final class UnfairLock: NSLocking, @unchecked Sendable {
    let unfairLock: os_unfair_lock_t

    public init() {
        unfairLock = .allocate(capacity: 1)
        unfairLock.initialize(to: os_unfair_lock())
    }

    deinit {
        unfairLock.deinitialize(count: 1)
        unfairLock.deallocate()
    }

    public func lock() {
        os_unfair_lock_lock(unfairLock)
    }

    public func unlock() {
        os_unfair_lock_unlock(unfairLock)
    }
}

/// A thread-safe wrapper around a value.
@dynamicMemberLookup
public final class Protector<Value> {
    
    private let lock: NSLocking

    #if compiler(>=6)
    private nonisolated(unsafe) var value: Value
    #else
    private var value: Value
    #endif

    
    /// Initialize the variable with the given initial value.
    ///
    /// - Parameters:
    ///   - value: Initial value for `self`.
    ///   - lock: NSLocking
    public init(_ value: Value, lock: NSLocking = UnfairLock()) {
        self.value = value
        self.lock = lock
    }

    /// Synchronously read or transform the contained value.
    ///
    /// - Parameter closure: The closure to execute.
    ///
    /// - Returns: The return value of the closure passed.
    public func read<U>(_ closure: (Value) throws -> U) rethrows -> U {
        try lock.around { try closure(self.value) }
    }

    /// Synchronously modify the protected value.
    ///
    /// - Parameter closure: The closure to execute.
    ///
    /// - Returns: The modified value.
    @discardableResult
    public func write<U>(_ closure: (inout Value) throws -> U) rethrows -> U {
        try lock.around { try closure(&self.value) }
    }

    /// Synchronously update the protected value.
    ///
    /// - Parameter value: The `Value`.
    public func write(_ value: Value) {
        write { $0 = value }
    }

    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<Value, Property>) -> Property {
        get { lock.around { value[keyPath: keyPath] } }
        set { lock.around { value[keyPath: keyPath] = newValue } }
    }

    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        lock.around { value[keyPath: keyPath] }
    }
}
