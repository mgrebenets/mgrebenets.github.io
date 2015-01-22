---
layout: post
title: "Swift & Objective-C Interoperability"
description: "A practical manifestation of Swift & Objective-C interoperability problems"
category: Swift
tags: [swift, ios, apple, objc]
---
{% include JB/setup %}

I've stumbled on an issue while working on my hobby project. One of the few related to Swift and Objective-C interoperability.

<!--more-->

Let's setup a simple code base.

{% highlight swift %}
import AppKit
typealias BaseObjCClass = NSObject

enum PureSwiftEnum {
  case Value, AnotherValue
}

protocol PureSwiftProtocol {
  var value: PureSwiftEnum { get }
  var size: CGSize { get }
}

class ObjCSubclass: BaseObjCClass, PureSwiftProtocol {
  var value: PureSwiftEnum = .Value
  var size: CGSize = CGSizeZero
}

class GenericClass<T where T: PureSwiftProtocol> {
  var embeddedInstance: T
  init(embeddedInstance: T) {
    self.instance = instance
  }

  func accessValue() -> PureSwiftEnum {
    return instance.value
  }

  func accessSize() -> CGSize {
    return instance.size
  }
}

let objectGeneric = GenericClass(embeddedInstance: ObjCSubclass())

println(objectGeneric.accessValue())
println(objectGeneric.accessSize())
{% endhighlight %}

There's pure Swift enum, protocol and a subclass of Objective-C class that adopts pure Swift protocol. By the way, have you ever tried declaring Swift enum with just one case?

Further on, I declare a generic class with type conforming to pure Swift protocol.

So what happens if I pass an Objective-C subclass to this generic class initializer?

To be honest, nothing happens most away. For reasons unknown to me my project compiled and ran. And it was running OK for a while until at some moment it started crashing consistently.

So the problem in this case is that I'm implicitly checking the conformance of Objective-C object `ObjCSubclass` to a non Objective-C (pure Swift) protocol `PureSwiftProtocol`. This check occurs when calling `return embeddedInstance.value` where `embeddedInstance` is an instance of `ObjCSubclass` but the access to it's property happens by converting it to `PureSwiftProtocol`.

Apparently, this is a known issue. There's a couple of discussions on StackOverflow ([one](http://stackoverflow.com/questions/24132738/swift-set-delegate-to-self-gives-exc-bad-access), [two](http://stackoverflow.com/questions/24174348/calling-method-using-optional-chaining-on-weak-variable-causes-exc-bad-access)).

## Solution A: Back to Roots

The first solution is to turn `PureSwiftProtocol` into Objective-C protocol by using `@objc` notation.

{% highlight swift %}
@objc protocol PureSwiftProtocol {
  var value: PureSwiftEnum { get }
  var size: CGSize { get }
}
{% endhighlight %}

But that won't make compiler happy because it has no idea how to map `PureSwiftEnum` into Objective-C. So you have to take it one step further. You have to declare `PureSwiftEnum` as Objective-C enum (with `NS_ENUM`), obviously you have to do it in Objective-C header file and properly setup bridging header in your project.

{% highlight objective-c %}
typedef NS_ENUM(NSInteger, PureSwiftEnum) {
  PureSwiftEnumValue
};
{% endhighlight %}

# Solution B: Wrap it Up

If you don't want to revert back to adding Objective-C code with the hope that Apple eventually fixes this issue in the future, you can try another ugly trick - wrap your Objective-C class with pure Swift class that conforms to the same protocol.

{% highlight swift %}
class PureSwiftWrapper: PureSwiftProtocol {
  var objcInstance: ObjCSubclass

  init(objcInstance: ObjcSubclass) {
    self.objcInstance = objcInstance
  }

  var value: PureSwiftEnum {
    return objcInstance.value
  }

  var size: CGSize {
    return objcInstance.size
  }
}
{% endhighlight %}

Now you can pass an instance of `PureSwiftWrapper` to `GenericClass`

{% highlight swift %}
let wrapper = PureSwiftWrapper(objcInstance: ObjCSubclass())
let generic = GenericClass(embeddedInstance: wrapper)

println(generic.accessValue())
{% endhighlight %}

With this setup my crash went away and hadn't reappeared since then.

## Summary
Reference to [swift-objc-interop.swift](https://github.com/mgrebenets/mgrebenets.github.io/blob/master/assets/scripts/swift-objc-interop.swift) to experiment and run it from command line or in Playground
