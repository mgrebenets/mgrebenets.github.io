---
layout: post
title: "Swift Refactoring - Implementation - Part 1"
description: "Swift Refactoring - Implementation - Part 1"
category: Swift
tags: [swift, refactoring, apple]
---
{% include JB/setup %}

Implementing [Swift Local Refactoring](https://swift.org/blog/swift-local-refactoring/) action.

Part 1 of 2.

<!--more-->

[Previous article - Tests]({% post_url 2019-02-03-swift-refactoring---tests %})

# Add Refactoring Kind

The chosen "Collapse Nested If Statement" refactoring is a cursor-based refactoring, so the first thing to do is to add this code to [RefactoringKinds.def](https://github.com/apple/swift/blob/master/include/swift/IDE/RefactoringKinds.def):

{% gist ee4558e598803b3bef404323bdda3928 %}

This macro will generate bare bones for new `RefactoringActionCollapseNestedIfStatement` class.

A new `-collapse-nested-if-statement` command line option needs to be added to `swift-refactor` tool in [swift-refactor.cpp](https://github.com/apple/swift/blob/master/tools/swift-refactor/swift-refactor.cpp):

{% gist 3076b4459139b1e606b8463b820c0f9d %}

Now, to finish off the refactoring action implementation, the following two methods have to be implemented in [Refactoring.cpp](https://github.com/apple/swift/blob/master/lib/IDE/Refactoring.cpp).

{% gist 3b76c4b1f52145ee19e988ddddb3f167 %}

Both methods require current cursor info for implementation.
While `isApplication` takes it as a `CursorInfo` input argument, for `performChange` current cursor info is available as a member of auto-generated `RefactoringActionCollapseNestedIfStatement` class.

# Is Applicable

The way I approached this implementation task is asking myself a question first.

_When is "Collapse Nested If Statements" refactoring action applicable?_

The obvious answer is:

_When there are more then 1 nested if statements._

So the approach is to _find nested if statements_ at current position and count them.

Let's first define a simple structure that will hold information about nested if statements:

{% gist 116b8da6ff4f19d2cc9bc0c6fad2009e %}

It's very straightforward, we keep track of the first _if_ statement (`FirstIfStmt`) and last **_then_** statement (`LastThenStmt`).

One important thing about collapsible nested _if_ statements is that **they all share a single _then_ statement**, they wouldn't be collapsible otherwise.

We also save all the _if_ statement conditions into `Conditions` list.

To decide whether a refactoring action is applicable, we need to have non-null first _if_ and last _then_ statements and more than 1 condition in the list:

{% gist 37aeac21570edc7611f83e4bdb3d9f86 %}

With this new structure in mind, we can define a new helper method that finds all nested _if_ statements under the cursor and then use it to implement `isApplicable`:

{% gist 033fbafd5b1d61fd0303640a5839a756 %}

## Find Nested If Statements

This is the part where we finally get down to using cursor info provided to us by refactoring engine.

It's easier to reason about the code in terms of _declarations_, _statements_ and _conditions_. For example, for a code like this:

{% gist 665c96f2eb401593586268c930f89ff8 %}

The high level view could be this:

![High Level View]({{ site.url }}/assets/images/swift-refactoring/abstract-view.png)

The (very rough) Abstract Syntax Tree sketch for this code:

![AST]({{ site.url }}/assets/images/swift-refactoring/ast.png)

If the cursor is pointing at the start of the first _if_ statement, then the AST we need to analyze looks like this:

![If Statement AST]({{ site.url }}/assets/images/swift-refactoring/if-stmt-ast.png)

So the very first thing to check is to make sure cursor info is pointing at the _start of the statement_ (`StmtStart`), the refactoring can't be applied otherwise:

{% gist 792157b920a56cc575cad032154ad0c9 %}

The returned empty `NestedIfStatementsInfo()` indicates that refactoring cannot be applied because `NestedIfStatementsInfo().canProceed()` is `false`.

### Walk the Tree

Next thing to do is to start walking Abstract Syntax Tree.

{% gist ebf53606957fb4cce81ef1d47ecf6d23 %}

`// 1`
For that we create a new type called `NestedIfStatementsFinder`, which inherits from `SourceEntityWalker` - the base class for walking the source code tree.

`// 2`
We also initialize an instance of `NestedIfStatementsFinder` called `Walker`.

`// 3`
Additionally, our walker should collect nested if statements info into the `Result` property.

`// 4` and `// 5`
Finally tell walker to `walk` the AST starting from `CursorInfo.TrailingStmt` and return the result.

Next let's have a look at some of the `SourceEntityWalker` interface.

It has a handful of methods to walk the AST, specifically it can walk the _statement_, _declaration_ or _expression_.

{% gist 23643ff1eb9fcc09c495b32478567338 %}

For our implementation we have used `bool walk(Stmt *S)`.

The type also offers customization points:

{% gist e3a136f327eeb99fff8c8ac157978216 %}

These methods can be overridden in types inheriting from `SourceEntityWalker`.
When `true` is returned, the walker will keep walking the tree, otherwise it will stop.

For out implementation, we choose to override `walkToStmtPre`, which is called when walker is _about to walk the statement_.

{% gist 60b2415aece5d205baefa7ec70bcf127 %}

Let's _walk_ this code step by step:

`// 1`
We are only interested in nested _if_ statements, so when statement kind (`S->getKind()`) is not `StmtKind::If` then there's no point to continue (return `false`).

{% gist e03b84f3744a24b3ee032997c91e6d32 %}

`// 2`
Now that we checked the statement kind, we can safely typecast it to `IfStmt`.

{% gist 964eb1be034b837de024a66ac065807c %}

`// 3`
We want to keep track of the first _if_ statement in the `Result` variable, so save it if this is the first _if_ statement we encounter.

{% gist e5546ad7c6b5809ebc3c2d4e160f92fd %}

`// 4`
If current _if_ statement has an _else_ statement, it cannot be collapsed, so there's no point to keep going.

{% gist cd9c8a93f87bb5732f82f8daaa00bfd9 %}

{% gist f34e876a1ab08859417c148c0b48dfed %}

`// 5`
We also need to keep track of last _then_ statement, which will be useful while applying refactoring transformation.

{% gist 44a80720186eb7b70f21f9fcb390d53e %}

`// 6`
If the _then_ statement of current _if_ statement has more than one elements, then the refactoring cannot be applied from this point on and need to stop.

{% gist 040f9e6337f3364c04370ab6ba266729 %}

Here's an example of Swift code:

{% gist d737b9c8b3998ae6690312efd0389503 %}

The `if a < 2` _if_ statement has 2 elements in the _then_ statement: `print(a)` and `if b > 1` statements.

`// 7`
Keep track of the _if_ statement conditions in `Conditions` list:

{% gist 6e7635dff6ba01e29df83e69b1d91311 %}

`// 8`
Finally, recursively walk the first statement inside the _then_-block.

{% gist 30d23e616474b37ef06bf63225835a7d %}

# Test

Now it's a good time to run the tests [created in previous article]({% post_url 2019-02-03-swift-refactoring---tests %}) to make sure implementation of `isApplicable` works as expected.

---

[Next - Implementation - Part 2]({% post_url 2019-02-04-swift-refactoring---implementation-p2 %})
