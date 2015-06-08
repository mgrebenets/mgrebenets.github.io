---
layout: post
title: "Fix Objective-C Imports"
description: "Fix Objective-C Imports"
category: Objective-C
tags: [objective-c, apple, import, xcode, ios, style, format]
---
{% include JB/setup %}

A way to change Objective-C `#import <Framework/Framework.h>` to modern `@import Framework;`.

<!--more-->

# Modules Syntax

[Objective-C modules](http://clang.llvm.org/docs/Modules.html) were first introduced with iOS 7. Modules came to live for a reason, for lots of reasons. They are designed to overcome shortcomings of current preprocessor, specifically the way `#import`s are handled. You can find more information (here)[https://stoneofarc.wordpress.com/2013/06/25/introduction-to-objective-c-modules/] and (here)[http://www.raywenderlich.com/49850/whats-new-in-objective-c-and-foundation-in-ios-7].

If your app minimum deployment target is iOS 7.0, you are free to switch to using modules for all system frameworks, such as `UIKit`, `Foundation` and the rest. With iOS 8.0 and support for custom dynamic frameworks, even your own frameworks can be imported as modules, but in the scope of this article we will look at system frameworks only. In terms of syntax your change would look like this

{% highlight objective-c %}
// Old code
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>       // Just an example

// New code
@import UIKit;
@import Foundation;
@import UIKit.UIImage;
{% endhighlight %}

A totally valid question to ask is "Should I even bother with fixing this?". And the answer is "No, not necessarily". As soon as you enabled modules for your project all `#include` and `#import` statements are automatically mapped to corresponding `@import` statement. This is described in some detail [here](http://clang.llvm.org/docs/Modules.html#id15) and [here](http://useyourloaf.com/blog/2014/12/07/modules-and-precompiled-headers.html).

So, technically, fixing imports in legacy code is the question of code base maintenance and code style. It does look a bit off when both `#import` and `@import` are sitting few lines apart in the same file. Weigh all pros and cons before making a final decision. Keep in mind the fact that if you already have the script at hand, the conversion will take no time at all.

# Fixing Recipe

Xcode is know to offer code migration features, such as "Convert to ARC" or "Convert to Modern Objective-C Syntax". However, converting all `#import`s to `@import`s is not part of Xcode feature set. I would add "yet", because I believe sooner or later Apple will proclaim iOS 7.0 as minimum OS supported by Xcode and force all imports conversion. Until that happens we need to handle this migration ourselves.

So what would be the recipe to fix imports for all system frameworks? Here's one I have in mind

- Get a list of all system frameworks
- For each framework
    - Replace `#import <Framework/Framework.h>` with `@import Framework;`
    - Replace `#import <Framework/Header.h>` with `@import Framework.Header;`


## System Frameworks

Let's solve the first part and get a list of system frameworks. Naturally, I googled first and ended up [here](https://developer.apple.com/library/ios/documentation/Miscellaneous/Conceptual/iPhoneOSTechOverview/iPhoneOSFrameworks/iPhoneOSFrameworks.html). My desire to scrape the web page luckily died off right away, reading through the first paragraph I found out that all system frameworks are located in

{% highlight bash %}
<Xcode.app>Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/<iOS_SDK>/System/Library/Frameworks
{% endhighlight %}

That path looked a bit familiar to me and I knew I could get at least some of it with help of `xcrun`, so this is what I got in the end

{% highlight bash %}
xcrun --sdk iphoneos --show-sdk-path
{% endhighlight %}

Then just append the missing bit and list the directory. Everything that ends with `.framework` is (quite logically) a system framework.

{% highlight bash %}
ls $(xcrun --sdk iphoneos --show-sdk-path)/System/Library/Frameworks | grep .framework
{% endhighlight %}

Now I would like to turn this into a regular expression. What I want to have is a regex that says something like `UIKit OR Foundation OR iAd` and so on, with POSIX regex syntax it will look like this `UIKit|Foundation|iAd`. So I loop through results of `ls`, drop the `.framework` bit and create a string of or-ed framework names. My bash skills do not shine really bright in this example, but the code does the job.

{% highlight bash %}
# Get the list of all system frameworks
LIBS=$(ls $(xcrun --sdk iphoneos --show-sdk-path)/System/Library/Frameworks | grep .framework)

# Collect all library components and combine into or-ed regex
for lib in ${LIBS}; do
    BASE_NAME=${lib/.framework/}
    [[ -z "${LIB_COMPONENTS}" ]] \
        && LIB_COMPONENTS="${BASE_NAME}" \
        || LIB_COMPONENTS="${LIB_COMPONENTS}|${BASE_NAME}"
done

echo "${LIB_COMPONENTS}"
{% endhighlight %}

The output is like this

{% highlight bash %}
AVFoundation|AVKit|Accelerate|Accounts|AdSupport|AddressBook|AddressBookUI|AssetsLibrary|AudioToolbox|AudioUnit|CFNetwork|CloudKit|CoreAudio|CoreAudioKit|CoreAuthentication|CoreBluetooth|CoreData|CoreFoundation|CoreGraphics|CoreImage|CoreLocation|CoreMIDI|CoreMedia|CoreMotion|CoreTelephony|CoreText|CoreVideo|EventKit|EventKitUI|ExternalAccessory|Foundation|GLKit|GSS|GameController|GameKit|HealthKit|HomeKit|IOKit|ImageIO|JavaScriptCore|LocalAuthentication|MapKit|MediaAccessibility|MediaPlayer|MediaToolbox|MessageUI|Metal|MobileCoreServices|MultipeerConnectivity|NetworkExtension|NewsstandKit|NotificationCenter|OpenAL|OpenGLES|PassKit|Photos|PhotosUI|PushKit|QuartzCore|QuickLook|SafariServices|SceneKit|Security|Social|SpriteKit|StoreKit|SystemConfiguration|Twitter|UIKit|VideoToolbox|WatchKit|WebKit|iAd
{% endhighlight %}

With this regex pattern it is now possible to fix the imports. For the live of me I couldn't win the battle with `sed` or `awk` and use regex back-reference in the pattern itself. This is not to say anything bad about `sed` or `awk` as such, this is just me lacking the skills. However, I still managed to stay purely within a realm of Unix-based system by using `perl`.

## Framework/Framework.h

This is exactly the case where back reference needs to be used in the pattern expression itself, not in the replacement. This is an illustration to explain what I actually mean

{% highlight bash %}
# Use back-reference in match pattern
"s,(group-capture)/\1,replacement,"

# Use back-reference in replacement
"s,(group-capture),\1,"
{% endhighlight %}

The `()` parenthesis are capturing a group and then captured content can be back-referenced using `\1`, `\2` and so on. In this example `(group-capture)/\1` used in pattern match literally means string "group-capture" repeated 2 times and separated by `/`: "group-captureg/group-capture".

Anyway, assuming the source file name is stored in `FILE_PATH` variable, the in-place replacement with Perl looks like this

{% highlight bash %}
FILE_PATH=SourceFile.m

# LIB_COMPONENTS are set previously
perl -pi -e "s/#import[ \t]*<(${LIB_COMPONENTS})\/\1.h>/\@import \1;/" "${FILE_PATH}"
{% endhighlight %}

Here you can see that regex accounts for missing or varying number of spaces after `#import` and that `\1` back-reference works perfect with perl.

## Framework/Header.h

This bit is almost the same as the previous case. In fact, regex is a little bit more common and doesn't use back-reference in match patter, instead uses 2 back-references in replacement string. It is important to note that these perl commands must be applied exactly in the order they are described, so you don't end up with `@import Framework.Framework;`.

{% highlight bash %}
FILE_PATH=SourceFile.m

# LIB_COMPONENTS are set previously
perl -pi -e "s/#import[ \t]*<(${LIB_COMPONENTS})\/(.*).h>/\@import \1.\2;/" "${FILE_PATH}"
{% endhighlight %}

# Other Modules

In fact, you know of course there are other modules as well, such as runtime modules, e.g.

{% highlight objective-c %}
// Old style
#import <objc/runtime.h>

// Module
@import ObjectiveC.runtime;
{% endhighlight %}

This case is somewhat more complicated than fixing system frameworks. I played a bit with `--show-sdk-platform-path` option of `xcrun` command and tried other things, but overall there's no straightforward obvious solution to this problem. You may have to fix these imports by hand or wait until Xcode automates it.

# Summary

As a traditional TL;DR; part, I will just post the link to the [upgraded shell script version](https://gist.github.com/mgrebenets/40eaa2b8d2c724733bd5).
