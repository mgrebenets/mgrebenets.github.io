---
layout: post
title: "AppStore Version Territory"
description: "AppStore Version Territory"
category: Mobile CI
tags: [mobile, ci, ios, apple, appstore, itunesconnect]
---
{% include JB/setup %}

Homegrown research on iOS app short and bundle version strings and how to specify them properly in respect to iTunes Connect and TestFlight.

<!--more-->

# Version Strings Intro

A typical iOS app needs 2 version strings to be defined. This is an example of Xcode 6.3.2 UI.

![Xcode Version Settings]({{ site.url }}/assets/images/app-version/xcode-version-build-ui.png)

The first version string is referred to as just "Version". It is also know as Short Bundle Version String and is stored under `CFBundleShortVersionString` key in the app's Info.plist.

This is what your users expect to see on the "About" screen in the app, if they care. The general rule is to use [Semantic Versioning](http://semver.org/) scheme in the `Major.Minor.Patch` form, e.g. `1.0.0`. It is also possible to use more user-friendly lightweight option `Major.Minor`, for example `1.0`, or even use just `1`, the decision is up to you. Later in this post and in the Summary section, I will give you the exact guidelines for short version string.

Second is Bundle Version. In Xcode UI it is called just "Build" and is stored under `CFBundleVersion` key in Info.plist. Another common name for this version string is "Build Version" or even "Build Number". Its purpose is to uniquely identify this particular bundle (aka build) among all the other builds for the current app version. Often bundle version can be unique across all versions of the app ever, though this is not mandatory any more.

![App Versions]({{ site.url }}/assets/images/app-version/short-n-bundle-full-spelling-xcode-ui.png)

![App Versions Raw Values]({{ site.url }}/assets/images/app-version/short-n-bundle-xcod-ui-raw-values.png)

You are free to put whatever you want as version strings, it will be compiled, linked and archived with no errors or warnings of any kind. Here's the ultimate proof for my words.

![Anything Goes]({{ site.url }}/assets/images/app-version/build-ok-with-poop.png)

![Anything Goes Indeed]({{ site.url }}/assets/images/app-version/poop-app-version.png)

The real fun begins when you try to upload that app bundle to TestFlight. At this time it actually matters what you put as app version strings. Let's dissect each version string separately and figure out what the rules are. But first let's create a test app in iTunes Connect.

![App Versions Raw Values]({{ site.url }}/assets/images/app-version/test-app-in-itc-1.0.0.png)

## Short Bundle Version String

So what happens if I try to upload an app bundle with short version string saying "poop"? Naturally it fails.

![Poop Upload Fails]({{ site.url }}/assets/images/app-version/invalid-value-poop.png)

I was totally expecting arbitrary strings to be a "no no" in iTunes Connect. But guess what? Big surprise!

![Poop Version in iTunes Connect]({{ site.url }}/assets/images/app-version/poop-version-in-itc.png)

Well, don't do that anyway.

Let's use a valid version string this time, e.g. `1.0.0` and for now set build version to `1`. I will use the `short-version (build-version)` format from this moment on to indicate both versions, so I'm trying to upload `1.0.0 (5)`. Why `5`? Well, I just want it to be `5`, it doesn't really matter.

![Upload Success]({{ site.url }}/assets/images/app-version/itc-upload-success.png)

Great, so it worked. Note that the app short version string exactly matches the version string in iTunes Connect. Back in a while, before Apple integrated TestFlight into iTunes Connect, it used to be a mandatory requirement, but not any more. I'm sure you want a proof, so I'll just upload `1.0 (1)` this time.

![Upload Success]({{ site.url }}/assets/images/app-version/success.png)

It worked! But that's not convincing enough. What if there's some advanced matching happening and `1.0` is kind of the same as `1.0.0`? OK then, I will upload `2.0 (1)`.

![Upload Success]({{ site.url }}/assets/images/app-version/success.png)

Worked again! Just to make sure I'm not uploading to a black hole, I'll try `1.0.0 (0)` again. Note the `0` build version, that's on purpose.

![0 is less than 5]({{ site.url }}/assets/images/app-version/upload-0-less-than-5.png)

Aha! A very interesting error message! I personally like the `train version` term. Apparently each distinct version in TestFlight has its own _train_, whatever that means, I like to imagine an actual Illawarra line train with carriages. Every time you upload a new prerelease version, a new train is created. The order in which you upload the builds does not matter, you can upload `1.0` after `2.0`.

However, if your app already has a live version in App Store, then your new uploads must have a greater version that the live app. _Greater_ in this case means _semantically_ greater, that means components of the version string are compared left to right. For example, `1.0.1` is less than `1.1`, because `1 == 1` and `0 < 1`. Here's the proof.

![1.0.1 is less than 1.1]({{ site.url }}/assets/images/app-version/1.0.1-less-than-1.1.png)

Finally, to dot all the `i`s, or should I say to dot all the short version string components, I will try to upload `2.1.1.1 (1)` to see what happens.

![At Most 3 Non-negative Ints]({{ site.url }}/assets/images/app-version/at-most-3-non-negative-ints.png)

And here's the rule for creating a short version string.

> A period-separated list of at most three non-negative integers.

Very clear and simple to remember.

One more thing, before I move on to bundle version. You can upload new prerelease builds to iTunes Connect _even if you don't have a new version created there yet_. That's right, just upload the builds and they will show up in Prerelease tab anyway. That also explains why the version string of uploaded bundle doesn't have to match the version with Prepare for Submission status. As usual, I can prove it.

![Prepare for Submission and Prerelease]({{ site.url }}/assets/images/app-version/prepare-for-submission-and-prerelease.png)

![Ready for Sale and Prerelease]({{ site.url }}/assets/images/app-version/ready-for-sale-and-prerelease.png)

OK, enough of short version string. Don't worry if facts look a bit scattered around the text, I'll summarize them all in the end. Now it's time for...

## Bundle Version

The rules for bundle version are not the same as for short version string. For convenience and to reduce tautology in the text, I will call it _build version_ by default.

There are many ways to compose a build version. The most popular options are

- Integer value (Build Number)
- Period-separated non negative integers
- Date string in `YYYYMMDD` or similar format
- Git commit hash
- Some weird stuff

Let's look at each option in detail.

### Build Number

This is the most basic and simple way to manage a bundle/build version. An _incremental_ non-negative integer. Any CI server gives you this number in some way. The _incremental_ part really matters. As I demonstrated before by uploading `1.0.0 (0)` after `1.0.0 (5)`, the build version of each new upload must be greater than the previous build version _on the same train_. This time there is no special meaning for _greater_, just good old integer comparison, so `11` is less than `101`.

Another important note is that build versions need to increment in the scope of the same train only. In the past, build version had to be incremental _across all versions_. So if you had `1.0 (10)` live and then tried to upload `2.0 (1)` it would fail because `1 < 10`. Thankfully that's not the case any more.

So to sum it up, build number used as bundle version

- Must be incremental
- Independent for each short version string train

### Period-separated

This is a little less popular way to manage build version, but still can be found "in the wild" so to say. For example, a build version is composed by joining short version string with the build number, like `major.minor.patch.build`: `1.0.0.1`, `2.0.42` and so on.

So what happens with this build version string when it gets to iTunes Connect? I will first tell you what happens, then will prove it with concrete examples.

- The build version is separated into components using `.`s as separators
- Each component is stripped of _leading_ zeroes
- Processed components are joined back together to form one big integer

The resulting integer is non negative, to be more specific it's `unsigned long` integer.

Some examples.

- `1.0.0.0` -> `1`, `0`, `0`, `0` -> `1000`
- `2.001.030` -> `2`, `001`, `003` -> `2`, `1`, `30` -> `2130`
- `1.000.02.03.04` -> `1`, `000`, `02`, `03`, `04` -> `1`, `0`, `2`, `3`, `4` -> `10234`

As you can see in the last example, the number of period-separated components is not limited this time. At least I tried all the way up to 4, can't tell what happens when you have 5 or more of them, but I am about 99% sure the sky is the limit, I mean there's some limit on the maximum length of the string.

Once the build version string is converted into an integer, the same rules apply as for the simple incremental build number. The newly uploaded build version for the given train must be greater than any previous build version.

Some examples again.

- `2 < 1.1` [`2 < 11`]
- `1.0 < 1.0.0` [`10 < 100`]
- `1.0 == 1.01` [`10 == 10`]
- `1.0.1.020 == 1.001.1.20` [`10120 == 10120`]

When you try to upload the same version more than once, you get a "Redundant Binary Upload" error message.

![Redundant Upload Error]({{ site.url }}/assets/images/app-version/redundant-upload-error.png)

I think I can stop now, the rules are pretty clear.

### Date String

Date string is another way to compose a build version. For example, when using `YYYYMMDD` format your build version may look like `20150604`. Actually, this is a very good option. The resulting integer will be always incremental, thanks to the way the world around us works.

If you have an advanced CI setup, you should think about adding more components to the date format. Such as hours and minutes `YYYYMMDDHHmm`. This way if you have more than one build happening within the same hour you will be able to tell them apart.

If you choose to go with this option, don't use any kind of separators, such as periods, colons or alike. With periods you will have unwanted side effects when leading zeroes are removed from components. Stuff like colons falls into Weird Stuff category, which I will describe later on.

### Git Commit Hash

Another quite popular approach is to use git commit hash as build version string, or as a part of build version string. One useful property of commit hashes is uniqueness. But that's not enough for TestFlight.

I tried quite a few things, such as hex numbers like `a`, `f`, `e`, `e4`, `5e` and even real life git commit hashes. So I lay the evidence before your eyes.

![Invalid Value "e"]({{ site.url }}/assets/images/app-version/invalid-value-e.png)

![Invalid Value "e4"]({{ site.url }}/assets/images/app-version/invalid-value-e4.png)

![Invalid Value "5e"]({{ site.url }}/assets/images/app-version/invalid-value-5e.png)

![Invalid Value Git Hash]({{ site.url }}/assets/images/app-version/invalid-value-git-hash.png)

Obviously, going outside the `a - f` range will take you nowhere, the `poop` example in the beginning of the article covers that well, and I tried things like `xyz` too.

### Weird Stuff

Finally, the weird stuff. I'll just list some of the things I tried.

- `1+0-2/5`
- `1+++0---2***5`
- `1...0...2...20`

Some error messages from iTunes Connect.

![Invalid Value Arithmetics]({{ site.url }}/assets/images/app-version/invalid-value-arithmetic.png)

![Invalid Value Lots Of Dots]({{ site.url }}/assets/images/app-version/invalid-value-lotta-dots.png)

Surprisingly though, despite the fact that upload fails, validation is successful. Whatever validation does it doesn't check the validity of version strings.

# Legacy

I subjectively call things like HockeyApp a _legacy_ in this article. You may have different opinion. What I really want to say is that all these iTunes Connect and TestFlight rules do not apply to things like HockeyApp or in-house Over The Air distribution. Despite that fact, it would be reasonable to start making changes towards TestFlight guidelines.

# Summary

In conclusion I will make an attempt to summarize the version string rules.

_Short Bundle Version String_

- A period-separated list of at most three non-negative integers
- Must be _semantically_ incremental
- Must be greater than current live version

_Bundle Version_

- Converted to unsigned long integer
- Periods are removed
- Leading zeroes removed from each period-separated component
- Resulting integer must be incremental
  - But only among other bundle versions for the same short version string (_version train_)
- Alphabet characters and git hashes in particular will not work
- Various punctuation marks will not work

Of course, I'm not claiming that this is the complete guide. I don't know what is the limit for maximum version string length. Could be that some punctuation marks are legal, I didn't try them all. Obviously I am giving no reference to any official documentation, could not find it or didn't look hard enough. In any case, this information should be enough for you to come up with a robust and reliable versioning strategy for your apps.
