---
layout: post
title: "Swift Refactoring - Intro"
description: "Swift Refactoring - Intro"
category: Swift
tags: [swift, refactoring, apple]
---
{% include JB/setup %}

Introduction to a series of articles detailing how to implement a new type of [Swift Local Refactoring](https://swift.org/blog/swift-local-refactoring/).

<!--more-->

So you thought about contributing to Swift code base but never knew where and how to start? Well then, [Swift Local Refactoring](https://swift.org/blog/swift-local-refactoring/) is a very good place to start.

In a series of articles I'll take you through my experience with implementing a single local Swift refactoring action.
The refactoring action I chose as an example is "Collapse Nested If Statements".

In short, it changes code like this

{%- gist befa9b767c9ac8ebe33d9b51b1b61ff9 -%}

into this

{%- gist 3e516cd309e63c24796ebf754f890d9b -%}

The steps:

- [Setup]({% post_url 2019-02-02-swift-refactoring---setup %}) Swift build environment.
- Follow TDD approach and Write [tests]({% post_url 2019-02-03-swift-refactoring---tests %}) first.
- [Implement Part 1]({% post_url 2019-02-04-swift-refactoring---implementation-p1 %}) refactoring action.
- [Implement Part 2]({% post_url 2019-02-04-swift-refactoring---implementation-p2 %}) refactoring action.
- [Debug]({% post_url 2019-02-05-swift-refactoring---debugging %}) the code.
- [Summary]({% post_url 2019-02-06-swift-refactoring---summary %}) and my thoughts on Xcode's refactoring feature.

# P.S.

You may notice that [Collapse Nested If Statements](https://bugs.swift.org/browse/SR-5739) refactoring action is already implemented and available in latest versions of Xcode.

A disclaimer though, I **did not** implement that action, but I surely took learnings from the current implementation.

The major difference between an action currently available in Xcode and the one described in these articles, is that current Xcode's version collapses only 2 statements at a time, so if you have 3 or more nested statements, you have to repeat the action to collapse them all.

(_Reload to play gifs_)

![Example 1]({{ site.url }}/assets/images/swift-refactoring/swift-refactoring-one-at-a-time.gif)

While the action implemented in these articles collapses all nested if statements at once.

![Example 2]({{ site.url }}/assets/images/swift-refactoring/swift-refactoring-all-at-once.gif)

---

[Next - Setup]({% post_url 2019-02-02-swift-refactoring---setup %})
