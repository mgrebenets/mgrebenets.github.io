---
layout: post
title: "Swift Refactoring - Implementation - Part 2"
description: "Swift Refactoring - Implementation - Part 2"
category: Swift
tags: [swift, refactoring, apple]
---
{% include JB/setup %}

Implementing [Swift Local Refactoring](https://swift.org/blog/swift-local-refactoring/) action.

Part 2 of 2.

<!--more-->

In the [previous part]({% post_url 2019-02-04-swift-refactoring---implementation-p1 %}) we've implemented `isApplicable` check.

The very same `findNestedIfStatements` can be reused to implement refactoring transformation.

{% gist aad6c1c141df7a1b428ad72e59241057 %}

`// 1`
The first thing to do is check if refactoring can be applicable.
Note that we return `true` to abort the refactoring transformation.

{% gist 7be112d50dbd6c8a7fd3504bd32fd6f7 %}

`// 2`
Next we create a buffer to write transformed code into and then create an output stream for writing to the buffer.

{% gist 82b56fbe2f6a6d3c192d5f57598fa93b %}

`// 3`
A collapsed _if_ statement will still be an _if_ statement, so we write the `if` keyword to output stream using `kw_if` keyword token.

{% gist 7b03325997c013a4ce541ecd85db8ba0 %}

`// 4`
Now we need to write the combined conditions list to output stream.
Conveniently, conditions in the [condition-list](https://docs.swift.org/swift-book/ReferenceManual/Statements.html#grammar_condition-list) can be joined together using commas.

> Grammar of an if statement
>
> if-statement → if condition-list code-block else-clause opt
>
> else-clause → else code-block | else if-statement
>
> condition-list → condition | condition , condition-list

Loop through conditions collected while finding nested _if_ statements:

{% gist 2a3c0d5e52a49ea53e19dc83515a4263 %}

Get the range of the condition statement `SC` in the original source code:

{% gist 48be3adc523999879f687e3dcbb9c7ec %}

Get the string representation of the condition statement from the original source code:

{% gist 3fc86c2abda111e898b84e525c0493e5 %}

`SM` here is an instance of `SourceManager` available to each refactoring action implementation.

Finally write the condition string into output stream joining it with the comma if needed.

{% gist 74fc1d0b468c682574146214359d4d7f %}

On first iteration separator will be an empty string while 2nd and consequent statements are joined by `", "` string.

`// 5`
Now is the time to write the _then_ statement shared by all collapsed _if_ statements.
This is the reason we saved `LastThenStatement` while finding nested if statements.
Again, we get the string representation of the _then_ statement and write it to output stream.

{% gist cfb6a44c0e60853eb50848a0a02dac97 %}

_Then_ statement already contains opening and closing braces (`{` and `}`), so no need to add those.

`// 6`
By this time the new transformed code is saved to output stream `OS`.
Final step is to replace original code with the new code using _Source Manager_ `SM`.

First step is to get the range of the untransformed source code.

{% gist ea9d9e909548ba4febac675f4f09789d %}

Here we take range from the `Start` of the `FirstIfStmt` to the `End` of the _then_ statement.

That range is then transformed into _source_ range, e.g. range in _Source Manager_ `SM`'s coordinates:

{% gist 891da3a2b44f88120477106a3d209456 %}

Finally, the code in `SourceRange` is replaced with contents of `Buffer` and we return `false` to indicate successful transformation (🤷‍♂️)

{% gist 44a6f27a91f24a4655ab1ed1cd1f0279 %}

[Full version of Refactoring.cpp](https://github.com/mgrebenets/swift/blob/feature/collapse-nested-if-statements/lib/IDE/Refactoring.cpp).

The implementation is ready to be tested.
If anything goes wrong, then it's time to debug.

---

[Next - Debugging]({% post_url 2019-02-05-swift-refactoring---debugging %})
