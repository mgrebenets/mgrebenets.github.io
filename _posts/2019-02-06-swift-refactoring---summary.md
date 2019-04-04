---
layout: post
title: "Swift Refactoring - Summary"
description: "Swift Refactoring - Summary"
category: Swift
tags: [swift, refactoring, apple]
---
{% include JB/setup %}

A summary for the [series of articles]({% post_url 2019-02-01-swift-refactoring---intro %}) about implementing [Swift Local Refactoring](https://swift.org/blog/swift-local-refactoring/) action.

<!--more-->

If you came here after going through previous 6 articles, you may have a few questions to ask:

_Was it worth it?_

Sure it was.

I learned the basics of working with Swift code base.
How to [build it]({% post_url 2019-02-02-swift-refactoring---setup %}), how to [write tests]({% post_url 2019-02-03-swift-refactoring---tests %}) and [debug]({% post_url 2019-02-05-swift-refactoring---debugging %}) the code.

This whole exercise took me one tiny step closer to understanding the rest of the Swift project.

_Would you do it again?_

The answer is "Yes" and "No".

No, I would probably not try to implement another refactoring action via `swift-refactor`.
Instead, I'd look into using [libSyntax](https://github.com/apple/swift/tree/master/lib/Syntax) library.

Yes, if I had more time to spare I'd look at one of the many [Swift starter tasks](https://bugs.swift.org/browse/TF-130?jql=labels%20%3D%20StarterBug).
