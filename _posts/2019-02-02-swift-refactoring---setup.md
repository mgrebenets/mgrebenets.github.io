---
layout: post
title: "Swift Refactoring - Setup"
description: "Swift Refactoring - Setup"
category: Swift
tags: [swift, refactoring, apple]
---
{% include JB/setup %}

Getting Swift sources and setting up build environment to implement [Swift Local Refactoring](https://swift.org/blog/swift-local-refactoring/) action.

<!--more-->

[Previous article - Intro]({% post_url 2019-02-01-swift-refactoring---intro %})

When it comes to cloning source code and building it, there's not that much that I can add to the [Swift repository README](https://github.com/apple/swift), but I'll try to highlight some moments that I find to be important.

# Latest Xcode

I can't stress enough how important this step is!

If you use wrong version of Xcode you will be banging your head against the wall trying to figure out why the build is OK, the tests pass, but you changes do not show up in the Xcode when you choose your new toolchain.

Don't forget to use latest Xcode when building from command line, for example, if you installed latest Xcode 10.2 beta to `/Applications/Xcode-10.2.app`, then run this in terminal

{% gist bd58fc8b49ba6e257acdc085852d4aef %}

# Stable Source

If you want to use source code that has passed [Swift CI](https://swift.org/continuous-integration/#configuration) then, after pulling in all the code, you can customize your `update-checkout` command like so

{% gist 72f71393af95cf891072f63e17e64294 %}

If the build was tagged, it means it passed all the tests and had a successful Xcode toolchain build. It may be a good idea to work on top of a stable code.

# Building Xcode Toolchain

Apple docs just tell you to run `./utils/build-toolchain $BUNDLE_PREFIX` command to build a new toolchain. It works, however, the command takes really long time and doesn't seem to take advantage of incremental builds when you re-run it.

Instead, you can package a toolchain using build artifacts created with `build-script`.

[This](https://johnfairh.github.io/site/swift_source_basics.html) and [this](https://samsymons.com/blog/exploring-swift-part-2-installing-custom-toolchains/) articles provide more details. Both recommend to use the following command to build Swift code:

{% gist 7202fa9024061bdfec37990a53ff2807 %}

Once the build is over, you can use [this script](https://gist.github.com/mgrebenets/1475448a3220e9559ae2ac9ed5955629) to create a toolchain in just few seconds.

Set the `SWIFT_SOURCE_PATH` to root of your Swift sources location and run the script from that location. Optionally customize `CONFIGURATION` and `BUILD_DIR`.

{% gist afb417f8690660ba5543ebed24e46840 %}

---

[Next - Tests]({% post_url 2019-02-03-swift-refactoring---tests %})
