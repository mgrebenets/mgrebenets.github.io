---
layout: post
title: "Uncrustify Objective-C"
description: "Uncrustify Objective-C"
category: Objective-C
tags: [objective-c, apple, import, xcode, ios, style, format]
---
{% include JB/setup %}

My personal journey to mastering (to some level) [uncrustify](TODO:) and [clang-format](TODO:) code formatting tools for Objective-C.

<!--more-->

# Background

There's always a reason for doing something, even if you are not fully aware of it yourself. Someone once wrote in a blog post stuff like "Live is too short to drive your code to perfection." I couldn't agree more. _My_ life is too short to spend time neck deep buried into someone else's code, which they didn't care to drive even to a sub-sub-perfection level.

When your team grows to a size of 2+ developers, lots of tiny small details start to matter, and they matter more and more with each new developer joining the team. It is often the case that the code "outlives" its authors, meaning the authors quit the job and the code stays. More than once in my career I had to deal with code written 5 or more years ago.

Well, that's enough of trying to mark the importance of clean and readable code. Let's just say you decided to use one of the few formatting tools for your Objective-C code base. Let's make it more fun by assuming you are dealing with existing code base, some parts of it as old as 5 or more years. I'll tell you how [uncrustify](TODO:) and [clang-format](TODO:) can help you with the task.


# Uncrustify vs Clang-format

Compared to clang-format, uncrustify is like a Swiss army knife. The default config file for uncrustify is over 480 lines (excluding comments and blank lines). Compare that to clang-format's roughly 70 lines. However, that army knife is also a bit rusty. Major contribution to the project on GitHub didn't happen for quite a while, number of issues, on the other hand, is constantly growing, especially number of issues related to Objective-C. Clang-format looks more up-to-date, but it offers much less options to configure it.

That was a brief comparison, I will dig deeper into each of the tools next. Before I do that, let's agree on some common formatting guidelines for the code.

- TODO: tabs size, etc....

# Uncrustify
_Version 0.61_

So, uncrustify is powerful, but just like C language, it's too easy to shoot

# Clang-format



# Swift

issues one by one from that Evernote and how to address them

which could be fixed and which will just stay there
