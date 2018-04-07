---
layout: post
title: "Xcode Derived Data"
description: "Xcode Derived Data"
category: Mobile CI
tags: [xcode, mobile, ci]
---
{% include JB/setup %}

What is Xcode Derived Data and why is it important?

<!--more-->

"Clean derived data". You might have heard this phrase each time you face some extremely strange build problems.

DerivedData is a folder located in `~/Library/Developer/Xcode/DerivedData` by default. It's the location where Xcode stores all kinds of intermediate build results, generated indexes, etc. DerivedData location can be configured in Xcode preferences (Locations tab).

So now and then you run into odd build problems. The more complex your project is the more chances you have to face them. Using Swift increases that probability a fair bit. DerivedData folder is also infamous for growing up to gargantuan sizes.

I have faced this issue when dealing with Jenkins CI server running as Launch Daemon. Special jenkins non-login user would run `xcodebuild` and that would create intermediate build files in DerivedData folder. But these new files would have access rights configured for non-login user. If you manually build the same project in the same folder while logged in as a "normal" login user you will mess up with files created previously by jenkins user. You will then see further build jobs failing while trying to write to DerivedData. Same applies to Bamboo or any other CI server running as Launch Daemon.

The lesson is - don't mess up and run things manually in your CI server's guts. Another lesson, [don't run CI Xcode build jobs as non-login user]({% post_url 2015-02-01-mobile-ci-daemon-vs-agent %}) to avoid permissions problems. A practical advice to take home - clean Xcode Derived Data on regular basis on your CI box(es). You could create a cron job to do that, make it run some time after midnight and execute this simple shell command

```bash
rm -rf /Users/username/Library/Developer/Xcode/DerivedData/*
```

Note the use of full path in the command. That's in case you do have multiple user accounts as part of your CI setup and the plan can run under any of those accounts.

If you happen to have multiple build agents running on multiple machines (either physical or virtual), then each of those agents should do it's own cleanup.

Cleaning derived data might increase the time of first build for each project next day, but it's a minor drawback. You will also claim free space back by killing DerivedData's huge appetite.

For daily use on your development machine create a type alias in your bash profile.

```bash
typealias xcode-clean-derived="rm -rf /Users/i4niac/Library/Developer/Xcode/DerivedData/*"
```
