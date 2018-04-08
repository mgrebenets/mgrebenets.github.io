---
layout: post
title: "Equatable NSObject With Swift 2"
description: "Equatable NSObject With Swift 2"
category: Swift
tags: [swift, swift-2.0, playground, xcode, ios, apple, outdated]
---
{% include JB/setup %}

[<font color="red">Swift 2.0</font>]

Subtle differences in implementing `Equatable` protocol for `NSObject` subclasses in Swift 1.2 and 2.0.

<!--more-->

> The best way to read this post is in Xcode playground, so go ahead and [Download Playground]({{ site.url }}/assets/playgrounds/NSObjectEquatable.playground.zip)

# Equatable

Instances of the type that conform to `Equatable` protocol can be compared for value equality using operators `==` and `!=`.

When adopting `Equatable`, only the `==` operator is required to be
implemented.  The standard library provides an implementation for `!=`.

This was pretty much a copy-paste from documentation. Let's try it in practice.

## Swift Structs

If you just have a simple struct, you will not be able to compare two instances of it.

```swift
struct CardStruct {
    let rank: Int

    init(rank: Int) {
        self.rank = rank
    }
}
```

Uncomment next line to see the following error:

> Error: Binary operator `==` cannot be applied to two CardStruct operands

```swift
//print(CardStruct(rank: 4) == CardStruct(rank: 4))
```

To fix it, make sure that your structure conforms to `Equatable` protocol first.

```swift
struct EquatableCardStruct: Equatable {
    let rank: Int

    init(rank: Int) {
        self.rank = rank
    }
}
```

Then implement `==` operator as prescribed by `Equatable`.

```swift
func ==(lhs: EquatableCardStruct, rhs: EquatableCardStruct) -> Bool {
    return lhs.rank == rhs.rank
}
```

Now two instances of `EquatableCardStruct` are equal if they have the same rank.

```swift
print(EquatableCardStruct(rank: 5) == EquatableCardStruct(rank: 5))
// true

print(EquatableCardStruct(rank: 5) == EquatableCardStruct(rank: 3))
// false
```

Since collection types are equatable by default, you can equate two arrays of `EquatableCardStruct`s as well with no additional effort.

```swift
let equatableCardStructs1 = [EquatableCardStruct(rank: 1), EquatableCardStruct(rank: 2), EquatableCardStruct(rank: 3)]
let equatableCardStructs2 = [EquatableCardStruct(rank: 1), EquatableCardStruct(rank: 2), EquatableCardStruct(rank: 3)]

print(equatableCardStructs1 == equatableCardStructs2)
// true
print([EquatableCardStruct(rank: 2)] == [EquatableCardStruct(rank: 5)])
// false
```

## NSObject Subclass

So it all works well for structs, but what if you are dealing with `NSObject` subclass? Let's declare one to start with.

```swift
class CardObject: NSObject {
    var rank: Int

    init(rank: Int) {
        self.rank = rank
    }
}
```

Now pay close attention to next line.

With Swift 1.2 (Xcode 6.3.2) it will work fine, uncomment and see for yourself.

With Swift 2.0 (Xcode 7) it will produce a compiler error.

> Error: Redundant conformance of 'CardObject' to protocol 'Equatable'

```swift
// This is "line 93" for future reference
//extension CardObject: Equatable {}
```

Usual implementation for `==`.

```swift
func ==(left: CardObject, right: CardObject) -> Bool {
    return left.rank == right.rank
}
```

Now let's try to equate some objects.

Look at the next two lines while using Swift 1.2. Notice that commenting and uncommenting line `93` doesn't change the behavior. Despite the fact that `CardObject` is not declared to conform to `Equatable`, the code still works. Most likely this is due to the fact that all code is in one playground, this `==` operator would most definitely fail if it were in another file.

```swift
print(CardObject(rank: 5) == CardObject(rank: 5))
// true

print(CardObject(rank: 5) == CardObject(rank: 3))
// false
```

This is where we can verify previous statement. Again, toggle comments on line `93` to see how result of the next `==` changes.

```swift
let cardObjects1 = [CardObject(rank: 1), CardObject(rank: 2), CardObject(rank: 3)]
let cardObjects2 = [CardObject(rank: 1), CardObject(rank: 2), CardObject(rank: 3)]
print(cardObjects1 == cardObjects2)
// false when line 93 commented
// true otherwise
```

So when `CardObject` is conforming to `Equatable` explicitly equating collections works as expected, otherwise it doesn't, most likely `isEqual:` method of `NSObject` is used, which compares object hashes.

But give it a try with Swift 2.0 now. First of all you will be told that `NSObject` already conforms to `Equatable`, so line `93` has redundand conformance. Once you comment that line `cardObjects1` and `cardObjects2` are not equal any more, because it's all back to comparing hash values now.

In order to fix this problem, you will have to override `isEqual` method.

```swift
class EquatableCardObject: NSObject {
    var rank: Int

    init(rank: Int) {
        self.rank = rank
    }

    override func isEqual(object: AnyObject?) -> Bool {
        if let rhs = object as? EquatableCardObject {
            return rank == rhs.rank
        }
        return false
    }
}
```

This class is almost identical to `CardObject`, except for the `isEqual` method. Another difference is that there's no global `==` implemented to compare 2 instances of `EquatableCardObject`.

Nevertheless the comparison works.

```swift
print(EquatableCardObject(rank: 5) == EquatableCardObject(rank: 5))
// true

print(EquatableCardObject(rank: 5) == EquatableCardObject(rank: 3))
// false
```

And not just for single values, but for arrays as well.

```swift
let equatableCardObjects1 = [EquatableCardObject(rank: 1), EquatableCardObject(rank: 2), EquatableCardObject(rank: 3)]
let equatableCardObjects2 = [EquatableCardObject(rank: 1), EquatableCardObject(rank: 2), EquatableCardObject(rank: 3)]
print(equatableCardObjects1 == equatableCardObjects2)
// true
```

# Summary

This sure looks like a breaking change from 1.2 to 2.0. I wonder if that's intentional or not. It does look strange that writing implementation of `==` operator doesn't actually change anything, in fact, it is never even called for `NSObject` subclasses, but then the whole conformance to `Equatable` is broken.
