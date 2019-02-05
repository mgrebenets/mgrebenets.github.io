---
layout: post
title: "Swift Refactoring - Debugging"
description: "Swift Refactoring - Debugging"
category: Swift
tags: [swift, refactoring, apple]
---
{% include JB/setup %}

Debugging implementation for [Swift Local Refactoring](https://swift.org/blog/swift-local-refactoring/) action.

<!--more-->

[Previous - Implementation Part 2]({% post_url 2019-02-04-swift-refactoring---implementation-p2 %})

# Ninja

If you have built `swift-refactor` tool using `ninja`, then you'd have to use command line `lldb` debugger to debug the code.
So after building `swift-refactor`, just run `lldb` in the terminal:

{% gist e5096458777a46043e046293e0579364 %}

Next, tell the debugger which executable to debug (`swift-refactor` in this case):

{% gist 6fe00897a20c233b0124a9506ee54cdc %}

Then set the breakpoint, e.g. for `isApplicable` implementation of `RefactoringActionCollapseNestedIfStatement` class:

{% gist 4ff653ecb873a61c4461b1d034bb070e %}

Now tell `lldb` to run the executable with `-source-filename` and `-pos` arguments

{% gist 680846748441ee7b74baaf55592bbd7a %}

The debugger has now stopped on line `1714` and is ready for your further input:

```cpp
-> 1714
```

Same debug commands you'd use in Xcode UI work in command line:

{% gist 0c003ac22de699731108cde0a146cd49 %}

![LLDB]({{ site.url }}/assets/images/swift-refactoring/refactoring-lldb.gif)

# Xcode

If you choose to develop using Xcode, debugging is even easier.

Edit the _swift-refactor_ scheme

![Edit Scheme]({{ site.url }}/assets/images/swift-refactoring/xcode-edit-scheme.png)

and add launch arguments:

![Launch Arguments]({{ site.url }}/assets/images/swift-refactoring/launch-args.png)

Set breakpoint and hit "Run":

![Breakpoint]({{ site.url }}/assets/images/swift-refactoring/breakpoint.png)

---

[Next - Summary]({% post_url 2019-02-06-swift-refactoring---summary %})