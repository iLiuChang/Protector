# Protector
A thread-safe wrapper around a value.

### Example
The following code may cause crashes or data errors in concurrent situations:

```swift
var numbers = [1, 2, 3, 4, 5]

DispatchQueue.concurrentPerform(iterations: 10) { _ in
    if let firstEven = numbers.first(where: { $0 % 2 == 0 }) {
        print(firstEven)
    }
    // Another thread modifies the array concurrently
    numbers.append(Int.random(in: 1...100))
}
```

In this case, the `first(where:)` and `append` operations may cause data races, leading to program instability.

---

The code is modified using `Protector`:

```swift
let numbers = Protector([1, 2, 3, 4, 5])

DispatchQueue.concurrentPerform(iterations: 10) { _ in
    
    if let firstEven = numbers.read ({ ns in
        ns.first(where: { $0 % 2 == 0 })
    }) {
        print(firstEven)
    }
    // Another thread modifies the array concurrently
    numbers.write({ $0.append(Int.random(in: 1...100)) })
}
```

After the modification, there will be no data competition problem.
