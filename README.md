# Protector

![Swift](https://img.shields.io/badge/Swift-5.5%2B-orange.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-lightgrey.svg)
![Version](https://img.shields.io/badge/Version-1.1.0-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![SPM](https://img.shields.io/badge/SPM-supported-brightgreen.svg)
![CocoaPods](https://img.shields.io/badge/CocoaPods-supported-blueviolet.svg)

## Overview

A thread-safe wrapper around a value. Every access is serialized by a lock, so a single `Protector` can be shared across threads, dispatch queues, and Swift concurrency tasks.

```swift
let numbers = Protector([1, 2, 3])
numbers.write { $0.append(4) }
let count = numbers.read { $0.count }
let first = numbers.first   // dynamic member lookup
```

## Features

- **Thread-safe access** — `read` and `write` run while holding the lock
- **Dynamic member lookup** — read or mutate nested properties as if they were properties of `Protector`
- **Atomic read-modify-write** — expressions like `protector.count += 1` hold the lock for the whole update
- **Custom lock** — defaults to `UnfairLock`; pass `NSRecursiveLock` when re-entrancy is needed
- **Swift concurrency** — `Sendable` when `Value` is `Sendable`
- **Apple platforms** — iOS, iPadOS, macOS, Mac Catalyst, tvOS, watchOS, and visionOS

## Requirements

- iOS 12.0+ / macOS 10.13+ / tvOS 12.0+ / watchOS 4.0+ / visionOS 1.0+
- Swift 5.5+

## Installation

### CocoaPods

```ruby
pod 'Protector'
```

Then run:

```bash
pod install
```

### Swift Package Manager

In Xcode: **File → Add Packages…** and enter:

```
https://github.com/iLiuChang/Protector.git
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/iLiuChang/Protector.git", from: "1.1.0")
]
```

### Manual

1. Download the files in the `Sources` folder
2. Drag them into your Xcode project

## Usage

### Why Protector

Concurrent reads and writes on a plain value can race:

```swift
var numbers = [1, 2, 3, 4, 5]

DispatchQueue.concurrentPerform(iterations: 10) { _ in
    if let firstEven = numbers.first(where: { $0 % 2 == 0 }) {
        print(firstEven)
    }
    numbers.append(Int.random(in: 1...100))
}
```

Wrap the value with `Protector` so each access is serialized:

```swift
import Protector

let numbers = Protector([1, 2, 3, 4, 5])

DispatchQueue.concurrentPerform(iterations: 10) { _ in
    if let firstEven = numbers.read({ $0.first(where: { $0 % 2 == 0 }) }) {
        print(firstEven)
    }
    numbers.write { $0.append(Int.random(in: 1...100)) }
}
```

### Read and Write

```swift
let box = Protector(["a": 1, "b": 2])

let sum = box.read { $0.values.reduce(0, +) }

box.write { $0["c"] = 3 }
box.write(["a": 0])
```

Each call is atomic on its own. Put a check-then-act sequence inside a single `write` closure:

```swift
box.write { value in
    if value["a"] == 0 {
        value["a"] = 1
    }
}
```

### Dynamic Member Lookup

```swift
struct Counter {
    var count = 0
    var items: [Int] = []
}

let counter = Protector(Counter())
counter.count += 1
counter.items.append(42)
print(counter.count)
```

### Custom Lock

`UnfairLock` is not recursive. If a `read` / `write` closure needs to re-enter the same protector, pass an `NSRecursiveLock`:

```swift
let box = Protector(0, lock: NSRecursiveLock())
```

## API Reference

### Protector

| Property / Method | Description |
|---|---|
| `init(_:lock:)` | Wraps a value. `lock` defaults to `UnfairLock()`. |
| `read(_:)` | Runs a closure with the current value while holding the lock. |
| `write(_:)` | Runs a closure with `inout Value`, or replaces the value entirely. |
| `subscript(dynamicMember:)` | Reads or writes a property through a key path while holding the lock. |

`Protector` is `@unchecked Sendable` when `Value` is `Sendable`.

### UnfairLock

A lightweight, non-recursive `NSLocking` wrapper around `os_unfair_lock`. It is the default lock used by `Protector`. Calling `lock()` again on the same thread before `unlock()` traps; unlock from the same thread that locked it.

## License

MIT License. See [LICENSE](LICENSE) for details.
