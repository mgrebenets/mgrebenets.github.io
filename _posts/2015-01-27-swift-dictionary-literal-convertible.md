---
layout: post
title: "Swift Dictionary Literal Convertible"
description: "Swift Dictionary Literal Convertible"
category: Swift
tags: [swift, ios, apple, outdated]
---
{% include JB/setup %}

[<font color="red">OUTDATED</font>]

A practical example of Swift's `DictionaryLiteralConvertible` protocol application.

<!--more-->

> Note. This article content refers to Swift version 2.0 or earlier and is now outdated.

If "Literal Convertibles" sounds strange to you then a good place to start is an excellent [NSHipster's post](http://nshipster.com/swift-literal-convertible/).

OK, let's say we have some struct in Swift.

```swift
struct Options {
  let timeout: Double = 1
  let message = "Timeout failed."
}
```

This is a structure holding timeout options for some abstract waiting function. If waiting takes longer that `timeout` then waiting is terminated and the `message` is displayed. For convenience default values are provided.

```swift
func wait(options: Options) {
  println("Waiting for \(options.timeout). Message: \(options.message)")
  // TODO: wait for some condition and fail after timeout
}

wait(Options(timeout: 0.1, message: "Custom timeout failed."))
```

Now, wouldn't it be nice to add some syntactic sugar and pass a dictionary with key-value pairs for waiting options, instead of calling `Options` initializer?

```swift
wait(["timeout": 0.1])
```

Of course compiler doesn't like this code, though it fails to tell us exactly why.

```bash
'Options' does not have a member named 'Value'
```

Let's experiment a bit.

```swift
wait("SomeString")
```

Doesn't make much sense but this time compiler complains with more sane error message.

```bash
Type 'Options' does not conform to protocol 'StringLiteralConvertible'
```

Basically it doesn't know how to construct and instance of `Options` type from `String`.

So when we used dictionary before, compiler had no idea how to create an instance of `Options` from a dictionary, but sadly couldn't communicate it back to us in a human-friendly form.

To be able to create `Options` objects from dictionaries `Options` has to conform to `DictionaryLiteralConvertible` protocol.

```swift
/// Conforming types can be initialized with dictionary literals
protocol DictionaryLiteralConvertible {
  typealias Key
  typealias Value

  /// Create an instance initialized with `elements`.
  init(dictionaryLiteral elements: (Key, Value)...)
}
```

To conform to this protocol we need to implement `init` and define type aliases for `Key` and `Value`. This was somewhat of a surprise for me, even when reading NSHipster's post for the first time I didn't realize that typealias are part of the protocol and had to be "implemented" (declared) too. I must have confused `typealias` with C's `typedef` for a while, hence misunderstanding of `typealias`.

OK, first attempt in conforming to the protocol.

```swift
extension Options: DictionaryLiteralConvertible {
  typealias Key = String
  typealias Value = AnyObject

  init(dictionaryLiteral elements: (Key, Value)...) {
    for (key, value) in elements {
      switch key {
        case "timeout": self.timeout = value as Double
        case "message": self.message = value as String
        default:
        fatalError("Unknown key: \(key)")
      }
    }
  }
}
```

For dictionary keys the `String` type is used, and for values use `AnyObject` since we can pass either `Double` or `String` as a value.

I'm sure there's a better more type-safe way to type alias `Value` to make it more "functional". Probably using enums. I'm still learning though.

The `init` iterates over the contents of the dictionary and initializes struct's members with values from the dictionary. The `as` is used to type cast `AnyObject` to `Double` or `String`.

I'm aware that use of `self` is not strictly required in this case and `self.timeout =` works same as just `timeout =`, but I tend to explicitly use `self.` syntax in initializers, kind of rule of thumb.

Let's try it again.

```swift
wait(["timeout": 0.1])
```

It works. Also notice that we can now provide partial arguments, like only timeout but no message in this case, something we couldn't with default struct initializer (would have to implement additional initializers).

Yet there are few things that smell in this code (apart from `AnyObject` I suppose).

- Use of hard-coded string literals like "timeout" is not good, typos happen all the time and it's quite painful to debug this type of errors.
- Default `case` statement with `fatalError` plug.

Let's now fix both these issues. First we will use a custom enum type for keys.

```swift
enum OptionKey {
  case Timeout, Message
}
```

Note that's it not even backed up by a raw `String` type, there's no need for that at the moment.

Now can rewrite the `Options` extension.

```swift
extension Options: DictionaryLiteralConvertible {
  typealias Key = OptionKey
  typealias Value = AnyObject

  init(dictionaryLiteral elements: (Key, Value)...) {
    for (key, value) in elements {
      switch key {
        case .Timeout: timeout = value as Double
        case .Message: message = value as String
      }
    }
  }
}
```

Main changes are

- Use `OptionKey` for `Key` type alias.
- Get rid of `default:` case, wrong key errors are now handled at compile time, not at run time.

Using the `wait` function is now as simple as

```swift
wait([.Timeout: 0.1])
wait([.Timeout: 0.1, .Message: "Custom timeout failed."])
```

You can [grab the swift code](https://gist.github.com/mgrebenets/ae93a434f3b15026c150) and try it yourself in playground or just by running from command line with `xcrun swift`.
