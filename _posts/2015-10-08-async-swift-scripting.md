---
layout: post
title: "Async Swift Scripting"
description: "Swift Scripts and Async Callbacks"
category: Swift
tags: [swift, osx, xcode, script]
---
{% include JB/setup %}

A trick to use asynchronous callbacks in Swift scripts.

<!--more-->

I was really inspired by [this talk by Ayaka Nonaka](https://realm.io/news/swift-scripting/). I personally believe that writing scripts in Swift will become A Thing very soon. It's already happening for Mac OS X, the upcoming Linux compiler will bring it to a next level. There's already plenty of useful frameworks available via [CocoaPods](http://cocoapods.org) or [Carthage](https://github.com/Carthage/Carthage). The only thing that's missing is a decent package manager for Swift frameworks, something like [Homebrew](http://brew.sh). Swift Package Manager (SPAM) sounds like a nice name :)

Anyway, I wanted to use [Alamofire](https://github.com/Alamofire/Alamofire) in a simple Swift script. So I have copy-paste-edited sample code from their GitHub page and saved it as a `Example.swift` file.

{% gist fecc3cfe5e1fad74cb1ef5a0565312d0 Example.swift %}

# Build Alamofire

To run this script I need to build Alamofire framework first. There are two ways to do that: using CocoaPods or Carthage.

Before I go on, it's important to specify versions of the tools I use.

- Xcode 9.2
- [cocoapods](https://github.com/CocoaPods/CocoaPods) gem version 1.4.0
- [cocoapods-rome](https://github.com/neonichu/Rome) gem version 0.8.0
- [carthage](https://github.com/Carthage/Carthage) version 0.28.0

## CocoaPods

Start with a `Podfile` that looks like this:

{% gist 07aff08e446119223d85db40f3410028 %}

Note that a file named `.swift-version` must exist in your working directory.
The contents of the file are "4.0" indicating Swift language version to use.

Next run `pod install` to build the frameworks.

%{ gist 4654b77f53c1982ceee1de7e0f73b772 %}

You may want to use `bundle exe pod install` if you installed gems with `Gemfile` and bundler.
Now you have `Alamofire.framework` ready for use in `Rome` directory.

## Carthage

Start with a `Cartfile`.

{% gist b3ea270bf558ce839e59fc6f574bb12a %}

Then build.

{% gist ae936eba2cc5d36a7c1217ae51e688cf %}

Note the `--platform mac` option. The option is not really well documented, but it's extremely important in this case. It tells carthage to build only Mac OS X targets, and that's exactly what you need for Swift scripting.

You should now have `Alamofire.framework` ready for use in `Carthage/Build/Mac` directory.

# Run

Time to run the script. To point Swift compiler to location of 3rd party frameworks use `-F` option and make sure you put it _before_ the name of the Swift file.

{% gist 988716a627370d78d49befa865c0b132 %}

And the output is...

```bash
Done
```

Wait a sec. How come? Well, that's because...

# It's Async!

Yes, the callback from Alamofire is asynchronous. So the script finishes execution before it gets the response callback from Alamofire.

That means we have to keep the script alive and kicking until we get all async callbacks. You have probably thought about semaphores or mutexes right now. Good guess, but that won't work. Consider this pseudo-code.

{% gist b93c9fbacdd2e42afa830777640649fe %}

The problem is that callback block (closure) is dispatched to the same queue it was originally enqueued from. This is the case for Alamofire and I'm pretty sure for most of the libraries with async callbacks.

`WAIT(MUTEX)` code will lock the main queue and `UNLOCK(MUTEX)` line will never be executed.

# Run Loop

The answer to this particular problem is [Run Loop](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html).
Each OS X or iOS application has a main run loop that keeps the app alive and reacts to all kinds of input sources, such as timer events or selector calls.
As a matter of fact, our Swift script has a run loop too, all we have to do is to keep it running until all async callbacks are received. The draft solution looks like this:

%{ gist 0f51d4036a48ca31f1178f14aab66e65 %}

In this example we get current run loop (`runLoop`) and then keep it running with help of `runMode(_: beforeDate:)` method. [According to the documentation](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSRunLoop_Class/#//apple_ref/occ/instm/NSRunLoop/runMode:beforeDate:) this method will return `YES` if the run loop ran and processed an input source or if the specified timeout value was reached; otherwise, `NO` if the run loop could not be started.

That's the main difference from using mutexes or semaphores. `runMode` doesn't block main queue, it just puts run loop to _sleep_ until specified time in the future (for `0.1`s in this example) and while _asleep_ the run loop can be _woken up_ by an input source. Asynchronous call to our JSON response closure is exactly the type of input source that can wake up a sleeping run loop, so each time `runMode` returns `YES` we also check for value of `keepAlive` and if it's false, that means we have handled our async callback and the script can stop its execution.

# Swift Script Runner

To make the task of writing scripts with async callbacks easier, I have created a [SwiftScriptRunner](https://github.com/mgrebenets/SwiftScriptRunner) framework. Here's how you'd use it:

{% gist 06ec6cff5ec302f179020e5f2356a89b %}

Then in `Example.swift`:

{% gist c3930a814d7ea58e2e26fbde8ebac469 %}

You can call `lock()` multiple times before `wait()`, just make sure you balance each `lock()` with `unlock()` to avoid _deadlocks_.
