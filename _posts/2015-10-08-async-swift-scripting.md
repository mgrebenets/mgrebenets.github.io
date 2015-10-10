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

Anyway, I wanted to use [Alamofire](https://github.com/Alamofire/Alamofire) in a simple Swift script. So I have copy-paste-edited sample code from their GitHub page and saved it as a `alamofire.swift` file.

{% highlight swift %}
import Alamofire

Alamofire.request(.GET, "http://httpbin.org/get", parameters: ["foo": "bar"])
         .responseJSON { response in
             print(response.result)   // Result of response serialization
         }

print("Done", separator: "\n")         
{% endhighlight %}

# Build Alamofire

To run this script I need to build Alamofire framework first. There are two ways to do that: using CocoaPods or Carthage.

Before I go on, it's important to specify versions of the tools I use.

- Xcode 7.0.1
- cocoapods gem version 0.38.2
- [cocoapods-rome](https://github.com/neonichu/Rome) gem version 0.2.0
- carthage version 0.8.0

## CocoaPods

Start with a `Podfile` that looks like this.

{% highlight ruby %}
platform :osx, '10.10'
use_frameworks!
plugin 'cocoapods-rome'

pod 'Alamofire', :git => 'https://github.com/Alamofire/Alamofire.git', :branch => 'master'
{% endhighlight %}

Note that I'm building off the tip of the `master` branch, that's because I need latest Swift 2.0 source code for Xcode 7. Now I can build the framework using new `--no-integrate` option.

{% highlight bash %}
# If Xcode 7 is not the default toolchain - use path to Xcode 7 app
export DEVELOPER_DIR=/Applications/Xcode7.app/Contents/Developer

# Install without integration (Rome feature)
pod install --no-integrate
{% endhighlight %}

You may want to use `bundle exe pod install` if you installed gems with Gemfile and bundler. The exact version of Alamofire I got built is `3.0.0-beta.3`. Now I have `Alamofire.framework` ready for use in `Rome` directory.

## Carthage

Start with a `Cartfile`.

{% highlight ruby %}
github "Alamofire/Alamofire" "master"
{% endhighlight %}

Then build.

{% highlight bash %}
# If your default Xcode toolchain is not Xcode 7
export DEVELOPER_DIR=/Applications/Xcode7.app/Contents/Developer

# Update and build
carthage update --platform mac
{% endhighlight %}

Note the `--platform mac` option. The option is not really well documented, but it's extremely important in this case. It tells carthage to build only Mac OS X targets, and that's exactly what you need for Swift scripting.

You should now have `Alamofire.framework` ready for use in `Carthage/Build/Mac` directory.

# Run

Time to run the script. To point Swift compiler to location of 3rd party frameworks use `-F` option and make sure you put it _before_ the name of the Swift file.

{% highlight bash %}
# If your default Xcode toolchain is not Xcode 7
export DEVELOPER_DIR=/Applications/Xcode7.app/Contents/Developer

# Run using framework built with CocoaPods
swift -F Rome alamofire.swift

# Run using framework built with Carthage
swift -F Carthage/Build/Mac alamofire.swift
{% endhighlight %}

And the output is...

{% highlight bash %}
Done
{% endhighlight %}

Wait a sec. How come? Well, that's because...

# It's Async!
Yes, the callback from Alamofire is asynchronous. So the script finishes execution before it gets the response callback from Alamofire.

That means we have to keep the script alive and kicking until we get all async callbacks. You have probably thought about semaphores or mutexes right now. Good guess, but that won't work. Consider this pseudo-code.

{% highlight swift %}
MUTEXT = CREATE_MUTEX()
LOCK(MUTEX) // Main queue
Alamofire.request(.GET, "http://httpbin.org/get", parameters: ["foo": "bar"])
         .responseJSON { response in
             UNLOCK(MUTEX) // Main queue!
         }
WAIT(MUTEX) // Main queue   
{% endhighlight %}

The problem is that callback block (colsure) is dispatched to the same queue it was originally enqueued from. This is the case for Alamofire and I'm pretty sure for most of the libraries with async callbacks.

`WAIT(MUTEX)` code will lock the main queue and `UNLOCK(MUTEX)` line will never be executed.

# Run Loop

The answer to this particular problem is [Run Loop](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html). Each OS X or iOS application has a main run loop that keeps the app alive and reacts to all kinds of input sources, such as timer events or selector calls. As a matter of fact, our Swift script has a run loop too, all we have to do is to keep it running until all async callbacks are received. The draft solution looks like this:

{% highlight swift %}
import Alamofire

var keepAlive = true
Alamofire.request(.GET, "http://httpbin.org/get", parameters: ["foo": "bar"])
         .responseJSON { response in
             print(response.result)   // Result of response serialization
             keepAlive = false
         }

let runLoop = NSRunLoop.currentRunLoop()
while keepAlive &&
    runLoop.runMode(NSDefaultRunLoopMode, beforeDate: NSDate(timeIntervalSinceNow: 0.1)) {
    // Run, run, run
}
{% endhighlight %}

In this example we get current run loop (`runLoop`) and then keep it running with help of `runMode(_: beforeDate:)` method. [According to the documentation](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSRunLoop_Class/#//apple_ref/occ/instm/NSRunLoop/runMode:beforeDate:) this method will return `YES` if the run loop ran and processed an input source or if the specified timeout value was reached; otherwise, `NO` if the run loop could not be started.

That's the main difference from using mutexes or semaphores. `runMode` doesn't block main queue, it just puts run loop to _sleep_ until specified time in the future (for `0.1`s in this example) and while _asleep_ the run loop can be _woken up_ by an input source. Asynchronous call to our JSON response closure is exactly the type of input source that can wake up a sleeping run loop, so each time `runMode` returns `YES` we also check for value of `keepAlive` and if it's false, that means we have handled our async callback and the script can stop its execution.

# Swift Script Runner

To make the task of writing scripts with async callbacks easier, I have created a [SwiftScriptRunner](https://github.com/mgrebenets/SwiftScriptRunner) framework. Here's how you'd use it:

{% highlight ruby %}
# In Podfile
pod 'SwiftScriptRunner'

# In Cartfile
github "mgrebenets/SwiftScriptRunner"
{% endhighlight %}

Then in `alamofire.swift`:

{% highlight swift %}
import Alamofire
import SwiftScriptRunner

var runner = SwiftScriptRunner()
runner.lock() // Lock

Alamofire.request(.GET, "http://httpbin.org/get", parameters: ["foo": "bar"])
         .responseJSON { response in
             print(response.result)   // Result of response serialization
             runner.unlock() // Unlock
         }

runner.wait() // Wait
{% endhighlight %}

You can call `lock()` multiple times before `wait()`, just make sure you balance each `lock()` with `unlock()` to avoid _deadlocks_.
