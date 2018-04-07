---
layout: post
title: "Hacker Rank in Swift - Reuse Code"
description: "Hacker Rank in Swift - Reuse Code"
category: HackerRank
tags: [hackerrank, swift, io, stdin, makefile, xcode]
---
{% include JB/setup %}

Reuse Swift IO code for multiple [HackerRank](https://hackerrank.com) assignments.

<!--more-->

If you have read [this article]({% post_url 2015-03-15-hackerrank-in-swift---io %}), you have probably noticed that code to read from stdin must be copied to each assignment file. Even though you need to copy-paste entire solution to HackerRank web site, this goes against [DRY](http://en.wikipedia.org/wiki/Don%27t_repeat_yourself) principle. In this post I'll explain how you can keep all stdin code in one file and use it to run code for assignments.

Start by grabbing Swift code, you can use [this file](https://github.com/mgrebenets/hackerrank/blob/master/StdIO.swift) for example. Put it in a file, name it `StdIO.swift` and put it in the root of your HackerRank folder alongside the makefile from [this post]({% post_url 2015-03-16-hackerrank-in-swift---makefiles %}) (you'll need that makefile later on).

# Swift Module

For next step you should have 2 files. A `StdIO.swift` file created earlier and, say, `solve-me-first.swift` for the [warmup assignment](https://www.hackerrank.com/challenges/solve-me-first).

```swift
let a: Int = readLn()
let b: Int = readLn()
println(a + b)
```

If you try to run `solve-me-first.swift` with makefile created in the article mentioned before, you'll get nowhere. Swift compiler has no idea where to look for `readLn` methods, so it can't interpret this script file alone. We have to build a Swift Module for `StdIO.swift` and then link it with our main Swift file.

Check out [this](http://railsware.com/blog/2014/06/26/creation-of-pure-swift-module/) and [this](http://stackoverflow.com/questions/25860471/xcrun-swift-on-command-line-generate-unknown0-error-could-not-load-shared-l) link to find out more about building a Swift module. I'll just provide a summary here. Once a Swift Module for `StdIO.swift` is built, it will consist of 3 files:

- `StdIO.swiftmodule` - public interface and definitions. An analogue of header files from Objective-C world.
- `StdIO.swiftdoc` - documentation.
- `libStdIO.dylib` - a shared (aka dynamic) library. That's actually a binary that has all all your code compiled, much alike dynamic library for C, C++, Objective-C and so on. There's a way to build a static (`.a`) library as well.

In general, Swift Module can include more than one Swift file. It just so happens that we have only one. To build a module you need to run this command

```bash
# Get location of OS X SDK.
export OSX_SDK=$(xcrun --show-sdk-path --sdk macosx)

# Build StdIO module (use `xcrun swiftc` for OS X 10.9).
swiftc -sdk ${OSX_SDK} \
    -emit-library \
    -emit-module StdIO.swift \
    -module-name StdIO
```

The options are instructing compiler to emit Swift module and shared library. Compiler also needs to know which SDK to build for. As expected, you should have 3 new files created.

```bash
StdIO.swiftdoc
StdIO.swiftmodule
libStdIO.dylib
```

That's great, the module is ready. Next step is to link it with your main Swift file and run the code. Before you run any command in the shell, you need to add one more line to `solve-me-first.swift` file.

```swift
# This line is new, import StdIO module
import StdIO

let a: Int = readLn()
let b: Int = readLn()
println(a + b)
```

Now it's time to link the two and run the code. This time we can use `swift` command.

```bash
# Get location of OS X SDK
export OSX_SDK=$(xcrun --show-sdk-path --sdk macosx)

cat tc/solve-me-first-tc0.txt | \
    swift \
        -sdk ${OSX_SDK} \
        -l$(pwd)/libStdIO.dylib \
        -I $(pwd) -module-link-name StdIO \
        solve-me-first.swift
```

Let's talk about each option separately.

- `-l<library>` - this is a flag that should be followed by the name of the library to link with.
  - Actually, `-lStdIO` works as well, but that's because `libStdIO.dylib` is sitting in the same folder. I choose to be more verbose and use the full path to shared library. My intentions will become clear later when we talk about makefiles.
- `-I <import-path>` - this flag is used to specify import path. Similar to include path in Objective-C world, this way we tell the compiler where to look for Swift modules to resolve `import` statements in the code.
  - Once again, instead of specifying current folder as `.`, I'm using full path. That will be explained later.
- `-module-link-name <name>` - well, it expects a name of the module to link with.

> Actually, this is a bit of a cheat. This second command does not compile the code, but interprets it while linking with existing module. There is a way to use Swift compiler here as well, you can find the reference in the end of this post.

OK, so run this command and you should get a (high) `5` as output. Replace the name of the test case file and the name of Swift file and you can run code for any other assignment. But that is too verbose. It should be automated with...

## Makefile

... with Makefile, of course. With small effort we can convert shell script into a makefile script.

```makefile
# Makefile

# Actual directory of this Makefile, not where it is called form
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

# Build directory
BUILD_DIR := $(CURDIR)/build

# OSX SDK
OSX_SDK := $(shell xcrun --show-sdk-path --sdk macosx)

# Swift executables and StdIO library name
# TODO: 10.9 use 'xcrun swift(c)', since 10.10 can use just 'swift(c)'
SWIFT = swift
SWIFTC = swiftc
SWIFT_STDIO = StdIO
SWIFT_STDIO_LIB_NAME = lib$(SWIFT_STDIO).dylib

# Test cases configuration
TC_DIR = tc
TC = 0
tc-path = $(TC_DIR)/$(patsubst %.$(2),%-tc$(1).txt,$(3))


# Enable phony targets
.PHONY:

# Swift compile and run
%.swift: .PHONY
	@mkdir -p $(BUILD_DIR)

	@# build stdio module
	@$(SWIFTC) \
		-sdk $(OSX_SDK) \
		-emit-library \
		-o $(BUILD_DIR)/$(SWIFT_STDIO_LIB_NAME) \
		-emit-module $(SELF_DIR)/$(SWIFT_STDIO).swift \
		-module-name $(SWIFT_STDIO)

	@# run linking against stdio module
	@cat $(call tc-path,$(TC),swift,$@) \
		| $(SWIFT) \
			-sdk $(OSX_SDK) \
			-l$(BUILD_DIR)/$(SWIFT_STDIO_LIB_NAME) \
			-I $(BUILD_DIR) -module-link-name $(SWIFT_STDIO) \
			$@
```

OK, so let's walk the code.

First we declare 3 variables: `SELF_DIR`, `BUILD_DIR` and `OSX_SDK`.

- `SELF_DIR` is an absolute path to the location of the makefile itself. We need to know this information, because we also know that `StdIO.swift` is located in the same folder as `Makefile`. It is _not_ the same as `$(CURDIR)`, `$(CURDIR)` is the folder you run makefile _from_.
- `BUILD_DIR` is the place to put build output. Don't forget to put it in your `.gitignore` and remove it as part of `clean` target.
- `OSX_SDK` is the path to current Mac OS X SDK.

One important note is the use of `:=` instead of just `=` when assigning values to the variables. If right side of assignment is one of the makefile functions, like `shell` to execute shell command, or `dir`, then each time you reference a variable, for example `$(OSX_SDK)`, the shell command will be executed. If the command is expensive, this will slow down execution of your makefile targets. Using `:=` ensures that variable is assigned a value only when initialized, when it's reference later on it uses that initial value.

Next block declares group of variables used as a reference to Swift executables, StdIO module and library name.

Then there are 2 variables and 2 functions related to test cases configuration. To get more details about `tc-path` function, check out [previous post]({% post_url 2015-03-16-hackerrank-in-swift---makefiles %}). Declaring targets as phony is something that's explained in that article as well.

Finally, the `%.swift` target runs all the compile commands. This code is almost identical to the shell code we had before, with minor differences.

- `-o <library-name>` option is used to explicitly tell compiler to put library file and accompanying module files into a build directory. That's just to keep your workspace clean of compiler output.
- file name for `-emit-module` is referencing `$(SELF_DIR)` variable to find `StdIO.swift` in the same folder as `Makefile` file.

Give it a try and run it.

```bash
# Using `make` directly
make -f ../../Makefile solve-me-first.swift

# Using `hrrun` alias
hrrun solve-me-first.swift
```

`hrrun` is an alias defined in [previous article]({% post_url 2015-03-16-hackerrank-in-swift---makefiles %}) as well.

So it works now and you can keep stdin code separately and reuse it in assignments source. By now you know how to run code in interpreter and how to compile it, wouldn't it be nice to be able to choose any of the two options?

## Interpret or Compile

Since makefiles support if-else flow control statements, you can add a conditional statement and split your makefile code in 2 parts, one for running code using interpreters, another to compile before running. It's as easy as this

```makefile
# Makefile

# Compile (YES) vs interpret (NO)
COMPILE = NO

# Enable phony targets
.PHONY:

ifeq ($(COMPILE), NO)	# Interpret

# Swift
%.swift: .PHONY
	# TODO: Interpret

else	# Compile and run

# Swift compile and run
%.swift: .PHONY
	# TODO: Compile and run

endif
```

By controlling value of `COMPILE` variable you can choose one of the two ways to run assignments code. Another alias would be handy as well.

```bash
HACKER_RANK_HOME="${HOME}/Projects/hackerrank"
alias hrrun="make -f ${HACKER_RANK_HOME}/Makefile"
alias hrrunc="make -f ${HACKER_RANK_HOME}/Makefile COMPILE=YES"
```

## Summary

You can now do the same thing for Haskell, Python, C, C++, Java or any other language that support compilation. Grab the latest version of [Makefile](https://github.com/mgrebenets/hackerrank/blob/master/Makefile) for your reference, and happy HackerRanking!
