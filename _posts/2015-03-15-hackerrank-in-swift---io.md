---
layout: post
title: "HackerRank in Swift - StdIn"
description: "HackerRank in Swift - Standard Input"
category: HackerRank
tags: [hackerrank, io, stdin, swift, haskell]
---
{% include JB/setup %}

[<font color="red">OUTDATED</font>]

A way to read standard input for [HackerRank](https://hackerrank.com) assignments in Swift.

<!--more-->

[HackerRank](https://hackerrank.com) is an amazing resource. It features lots of programming assignments from multitude of domains. This is a perfect place to prep yourself up for upcoming interview, to improve your problem solving skills and even to learn a new language.

For all those who follows Swift programming language closely, it is now [supported by HackerRank](https://www.hackerrank.com/environment). So if you are desperate to write some Swift code and don't have any real projects to apply it, HackerRank might be an excellent place to do just that.

> Well, Swift support with HackerRank has been on and off lately. Few months after I wrote this post Swift 1.2 was released, few days later it disappeared from HackerRank. Probably they have problems catching up with Swift development schedule. In any case you can still solve the problems in Swift and then submit them in bulk once HackerRank engineers get it working.

Most (if not all) of the assignments require reading data from standard input. The format is usually like this.

```bash
<N>
<test-case-1>
<test-case-2>
...
<test-case-N>
```

In this example `N` is total number of test cases. It is then followed by `N` lines each corresponding to an input for a test case. This is common, but not the only way to provide input. Some assignments would have 2-line test cases or other format. In any case, one common feature between all assignments is that you need to read data line by line. So let's start with implementation of core `getLine` function in Swift.

# Get Line

```swift
import Foundation

// MARK: Standard Input

/// Reads a line from standard input
///:returns: string form stdin
public func getLine() -> String {
    var buf = String()
    var c = getchar()
    // 10 is ascii code for newline
    while c != EOF && c != 10 {
        buf.append(UnicodeScalar(UInt32(c)))
        c = getchar()
    }
    return buf
}
```

The code is straightforward.

- Declare `buf` variable used to accumulate the result string.
- Declare `c` variable used to read next character from stdin with `getchar`
- Loop until reach the end of file (`EOF`), or newline (ASCII code `10`)
  - On each iteration append newly read character to the accumulator string

You've probably heard lots of things about Swift. Among all the things, one very important feature is its interoperability with Objective-C and C languages. This small code snippet isn't a 100% "pure" Swift code. First of all, it's using [getchar](http://www.opensource.apple.com/source/gcc/gcc-926/libio/stdio/getchar.c) function from C Standard Library made available via `Foundation` framework import. No worries though, all these APIs are toll-free bridged to Swift. This also explains a chain of initializers / type-casts when appending new character to accumulator string. `getchar()` returns ASCII code of the character of `Int32` type. The thing is that Swift's [String](http://swiftdoc.org/type/String/) is not your good old ASCII null-teminated C string, it is actually a collection of [Unicode scalars](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/StringsAndCharacters.html). Bear in mind, that _collection_ isn't just a figure of speech, it actually means that `String` type conforms to [CollectionType](http://swiftdoc.org/protocol/CollectionType/) protocol. Anyway, to create an instance of [UnicodeScalar](http://swiftdoc.org/type/UnicodeScalar/) you need to have a value of `UInt32` type, hence the conversion of `c` to `UInt32`.

> An important note. This code _will not_ work properly with actual Unicode input. Anything outside of standard ASCII table will be rendered as some gibberish. Obviously `getchar` is not up for the job of reading unicode characters. However, on HackerRank you would never get non-ASCII input (at least for assignments that I saw), so this function does perfect job for its targeted application area.

# Read Line

Now when you can get a line, next thing you will want is to convert that line into something else. For example, if the line is just one integer, you would like to convert into a value of `Int` type. It it's a list of integers (space- or comma-, or whatever- separated), you would obviously want to convert it to `Array<Int>` or `[Int]`. And so on and so forth.

I am actually inspired by Haskell here. It has a core `getLine` function to get a line as string, then it also has `readLn` method, which doesn't just get the line, but also allows converting it into a value of desired type.

```haskell
-- Haskell

-- Read a line and convert to IO Int
n <- readLn :: IO Int

-- Get a line and convert (read) it as array of Int
line <- getLine
let input = read line :: [Int]
```

So I wanted to have something similar or alike to use in Swift. This is _one of_ solutions.

```swift
/// Read line from standard input
///:returns: string
public func readLn() -> String {
    return getLine()
}

/// Read line from standard input and convert to integer
///:returns: integer value
public func readLn() -> Int {
    return getLine().toInt()!
}

/// Read line and convert to array of strings (words)
///:returns: array of strings
public func readLn() -> [String] {
    return getLine().componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
}

/// Read line and convert to array of integers
///:returns: array of integers
public func readLn() -> [Int] {
    let words: [String] = readLn()
    return words.map { $0.toInt()! }
}
```

Let's review each function.

- `public func readLn() -> String`
  - This is really just an alias for `getLine()` as you can clearly see from its implementation.
- `public func readLn() -> Int`
  - This function gets the line and converts it to `Int` using `toInt()` method. Since `toInt()` returns an optional, we have to use explicit unwrapping (`!` operator). Needless to say that if the string can't be parsed into an integer, the code will crash.
- `public func readLn() -> [Strings]`
  - Get the line and parse it into an array of strings. It works from the assumption that default separator is whitespace. Luckily, this is the case with all HackerRank assignments I've seen so far. It's possible to improve this function and pass custom separator string as an argument.
- `public func readLn() -> [Int]`
  - Get the line and parse it into an array of integers. You might have thought that this function _kind of_ calls itself. Of course it's not true and there's no recursion here. Because the line `let words: [String] = readLn()` explicitly specifies the type of the `words` constant, Swift compiler calls the `public func readLn() -> [String]` function matching the `[String]` type of `words`. Once it gets an array of strings, it maps each value to its integer counterpart with `toInt()` call.

Obviously, you can define as many `readLn` functions as you wish, but the sane thing to do is to define new function when particular assignment requires it. For example, somewhere down the middle of Warmup section in Algorithms domain, you will need a function like this.

```swift
// An array of (Int, String) tuples
public func readLn() -> [(Int, String)] {
     // ...
}
```

## Generics?

OK, so when you see 4 `readLn` functions that differ by return type only, what does the common sense tell you? And what does each and every functional programming text book recommend in this case? Right - use generics.

But hold on, this is probably the case where generics wouldn't work right away (I'd be happy to be proven wrong). Generics really work well when lots of functions differ only in types they use, but still have the _same_ implementation details. In this case, each `readLn` implementation is specific and there aren't lots of common patterns to be reused. Let's have a pseudo-code-thought experiment though.

```swift
public func readLn<T>() -> T {
     // Not a real Swift code!
     switch T {
     case String:
        return getLine()
     case Int:
        return getLine().toInt()!
     case [String]:
        return getLine().componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
     case [Int]:
        let words: [String] = readLn()
        return words.map { $0.toInt()! }
     default:
        return getLine()
     }
}
```

Now, this is not a real code and would never compile. The reason is that there's no simple way to do a switch by the type `T`. I have found an ugly way to work around this limitation.

```swift
public func readLn<T>() -> T {
    if (T.self as? String.Type != nil) {
        return getLine()
    } else if (T.self as? Int.Type != nil) {
        return getLine().toInt()!
    } else if (T.self as? [String].Type != nil) {
        return getLine().componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    } else if (T.self as? [Int].Type != nil) {
        let words: [String] = readLn()
        return words.map { $0.toInt()! }
    } else {
        return getLine()
    }
}
```

The conditions for `if`s are actually a valid Swift code, though they don't look pretty. The code still doesn't compile. The problem is that each return statement returns one of these types: `String`, `Int`, `[String]` or `[Int]`, and compiler doesn't know how to initialize an instance of type `T` with any of these types. Compiler doesn't really know anything about `T`, but it does know that `T` gives no guarantee to provide `init(_: Int)` or any other initializer.

What you could do next, is to try to come up with a protocol which `T` would conform to. Pack all these initializers inside the protocol, and then much more; and probably this path of generic functional madness would take you somewhere after all. But look at this from another angle: even if you succeed in making this generic function to compile and work, you effectively have implementations of each and every separate functions sitting right there, each in its own if-clause. So what's the point then?

My personal takeaway from this exercise is: do not overcomplicate things. Just think of a group of N different `readLn` functions as some single abstract generic function. After all, when you use it in code, that's exactly how it looks and works.

# Use

Finally, after all this abstract talk, it is time to put these standard input functions to a good use.

Let's start with [Solve me first](https://www.hackerrank.com/challenges/solve-me-first). Here's the solution in Swift.

```swift
let a: Int = readLn()   // calls readLn() -> Int, because a is of Int type
let b: Int = readLn()
println(a + b)
```

To test it, make a simple `solve-me-first-tc0.txt` file with test input.

```bash
2
3

```

Then run this command in the terminal.

```bash
# Mac OS X 10.9+
cat solve-me-first-tc0.txt | xcrun swift solve-me-first.swift

# Mac OS X 10.10+
cat solve-me-first-tc0.txt | swift solve-me-first.swift
```

As expected, the output is `5` and you've just got your first assignment solved in Swift.

While we are at it, let's solve the [Solve me second](https://www.hackerrank.com/challenges/solve-me-second). You have to read an array of integers from each line and sum them up. Calculating the sum of all elements in an array is a text book example of using `reduce` method.

```swift
let n: Int = readLn()

for _ in 0..<n {
    let ints: [Int] = readLn()  // calls readLn() -> [Int]
    let sum = ints.reduce(0, +)
    println(sum)
}
```

Now, if you are one of fresh functional programming converts, you might frown at the for-loop. I had the same feeling originally. Reading a lot about functional approach made me think that _any_ for-loop should be effectively replaced with map, reduce or filter. But is it really so? Swift does have a number of features which are part of functional programming paradigm, but that doesn't mean that for-loop is now banned from use. For-loop is one of the native Swift idioms and does have its own use where appropriate. As an example, check [this post](http://inessential.com/2015/02/19/looping_through_objects_in_an_array?utm_campaign=This_Week_in_Swift_30&utm_medium=email&utm_source=This%2BWeek%2Bin%2BSwift) and [related discussion on Apple Developers forum](https://devforums.apple.com/message/1105131).

## Summary

You now have a handy stdin Swift library to get you going with most of assignments. If you are not a big fan of copy-pasting these functions each time, check out my other posts about [HackerRank makefiles]({% post_url 2015-03-16-hackerrank-in-swift---makefiles %}) and [reusing Swift IO library]({% post_url 2015-03-17-hackerrank-in-swift---reuse-io %}).
