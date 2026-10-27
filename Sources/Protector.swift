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
}

/// A lightweight, non-recursive lock backed by `os_unfair_lock`.
///
/// `UnfairLock` is the default lock used by `Protector`. It is available on
/// iOS, iPadOS, macOS, Mac Catalyst, tvOS, watchOS and visionOS.
///
/// - Important: The lock is not recursive. Calling `lock()` again on the same
///   thread before `unlock()` traps at runtime. It must also be unlocked from
///   the same thread that locked it.
public final class UnfairLock: NSLocking, @unchecked Sendable {
    private let unfairLock: os_unfair_lock_t

    /// Creates an unlocked lock.
    public init() {
        unfairLock = .allocate(capacity: 1)
        unfairLock.initialize(to: os_unfair_lock())
    }

    deinit {
        unfairLock.deinitialize(count: 1)
        unfairLock.deallocate()
    }

    /// Acquires the lock, blocking the current thread until it becomes available.
    public func lock() {
        os_unfair_lock_lock(unfairLock)
    }

    /// Releases the lock. Must be called from the thread that acquired it.
    public func unlock() {
        os_unfair_lock_unlock(unfairLock)
    }
}

/// A thread-safe wrapper around a value.
///
/// Every access to the wrapped value is serialized by a lock, so a single
/// `Protector` instance can be shared freely between threads, dispatch queues
/// and Swift concurrency tasks.
///
/// ```swift
/// let numbers = Protector([1, 2, 3])
/// numbers.write { $0.append(4) }
/// let count = numbers.read { $0.count }
/// let first = numbers.first   // dynamic member lookup
/// ```
///
/// - Important: Each call to `read(_:)` or `write(_:)` is atomic on its own,
///   but separate calls are not. Put a check-then-act sequence inside a single
///   `write(_:)` closure. Do not access the same `Protector` from inside its
///   own closures; with the default `UnfairLock` that deadlocks or traps.
@dynamicMemberLookup
public final class Protector<Value> {

    private let lock: NSLocking

    private var value: Value

    /// Creates a protector wrapping the given initial value.
    ///
    /// - Parameters:
    ///   - value: The initial value to protect.
    ///   - lock: The lock used to serialize access. Defaults to a new `UnfairLock`.
    ///     Pass an `NSRecursiveLock` if the closures need to re-enter this protector.
    public init(_ value: Value, lock: NSLocking = UnfairLock()) {
        self.value = value
        self.lock = lock
    }

    /// Synchronously reads or transforms the protected value while holding the lock.
    ///
    /// - Parameter closure: The closure that receives the current value.
    ///
    /// - Returns: The value returned by `closure`.
    public func read<U>(_ closure: (Value) throws -> U) rethrows -> U {
        try lock.around { try closure(self.value) }
    }

    /// Synchronously modifies the protected value in place while holding the lock.
    ///
    /// - Parameter closure: The closure that receives the value as `inout`.
    ///
    /// - Returns: The value returned by `closure`.
    @discardableResult
    public func write<U>(_ closure: (inout Value) throws -> U) rethrows -> U {
        try lock.around { try closure(&self.value) }
    }

    /// Synchronously replaces the protected value.
    ///
    /// - Parameter value: The new value.
    public func write(_ value: Value) {
        write { $0 = value }
    }

    /// Reads or writes a property of the protected value through dynamic member lookup.
    ///
    /// Mutations such as `protector.count += 1` or `protector.items.append(x)`
    /// are performed while holding the lock for the whole read-modify-write.
    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<Value, Property>) -> Property {
        get { lock.around { value[keyPath: keyPath] } }
        _modify {
            lock.lock(); defer { lock.unlock() }
            yield &value[keyPath: keyPath]
        }
    }

    /// Reads a read-only property of the protected value through dynamic member lookup.
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        lock.around { value[keyPath: keyPath] }
    }
}

extension Protector: @unchecked Sendable where Value: Sendable {}
