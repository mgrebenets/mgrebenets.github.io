---
layout: post
title: "CocoaPods for Enterprise"
description: "Use CocoaPods for Enterpise"
category: Mobile CI
tags: [cocoapods, ios, apple, ruby]
---
{% include JB/setup %}

A practical example of using CocoaPods for enterprise projects.

<!--more-->

The "Enterpise" definition isn't that clear and is not something standard. I will define it as follows.

- Enterprise is a company that builds more that one app on the same platform.
- Has a large number of in-house libraries and modules.
- Has a rather complex project configuration.

The challenge is to adopt CocoaPods for such projects. This is actually more of a case-study than success story of adopting CocoaPods.

## xcconfig

One thing that "complex" project setup means is extensive use of xcconfig files. The problem is that CocoaPods generates it's own xcconfigs and expects them to be applied to project target. If it detects existing xcconfigs it displays a warning in the end of generation step. Solution is to follow the advise and include Pods xcconfig in the very last xcconfig file which is applied to a target.


{% highlight c %}
// Pods
#include "Pods/Target Support Files/Pods/Pods.debug.xcconfig"
{% endhighlight %}

Make sure you do that for all targets and all configurations.

## $(inherited)

This is next issue which is [known to CocoaPods users](https://github.com/CocoaPods/CocoaPods/issues/1761).

The problem is that CocoaPods assumes it's the only thing in the world using xcconfigs. So it never ever uses `$(inherited)` thus it doesn't pick up any of the previous definitions when included into other xcconfigs.

One of the solutions is to patch Pods xcconfig files as part of `pod upate` or `pod install` command. This is what post-install hooks are for. Consider this example

{% highlight ruby %}
# Podfile for Alfred
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'

link_with 'BT'
pod 'Facebook-iOS-SDK', '~> 3.20.0'

post_install do |installer|
    puts "Running post install hooks"
    puts "Patching Pods xcconfig files"
    workDir = Dir.pwd
    installer.project.targets.each do |target|
        target.build_configurations.each do |config|
            xcconfigFilename = "#{workDir}/Pods/Target Support Files/Pods/Pods.#{config.name.downcase}.xcconfig"
            xcconfig = File.read(xcconfigFilename)
            # insert $(inherited) for HEADER_SEARCH_PATHS and OTHER_LDFLAGS, make sure there's only one occurrence
            patchedXcconfig = xcconfig.gsub(/HEADER_SEARCH_PATHS = (?<first>[^\$])/, 'HEADER_SEARCH_PATHS = $(inherited) \k<first>').gsub(/OTHER_LDFLAGS = (?<first>[^\$])/, 'OTHER_LDFLAGS = $(inherited) \k<first>')
            File.open(xcconfigFilename, "w") { |file| file << patchedXcconfig }
        end
    end
end
{% endhighlight %}

The `post_install` hook iterates through all targets, figures out the full path to generated Pods xcconfig and patches it by prepending `$(inherited)` for all occurrences of `HEADER_SEARCH_PATHS` and `OTHER_LDFLAGS`.

## Git Submodules and Proxy

This another issue that may happen in "enterprise" environment, especially if proxy is involved. CocoaPods is not able to checkout pods with submodules. An example of a pod with such problems is [Facebook SDK](http://stackoverflow.com/questions/25953246/facebook-ios-sdk-installation-via-cocoapods).

To avoid this problem in the first place I would recommend to use pods with static frameworks instead of those that clone whole source base. Well, not for all pods, but this is often useful for 3rd party SDKs that don't update often. This is what pods like Flurry, Crashlytics and others do. For some reason Facebook doesn't have official podspec for framework only, but nothing stops you from creating one yourself and host it in-house.

If you have to have those submodules, use the following git trick:

{% highlight bash %}
git config --global url.https://github.com/.insteadOf git://github.com/
{% endhighlight %}

See discussions on [StackOverflow](http://stackoverflow.com/questions/1722807/git-convert-git-urls-to-http-urls) and [this post](https://coderwall.com/p/sitezg/force-git-to-clone-with-https-instead-of-git-urls). This command will modify your `.gitconfig` by adding this line

{% highlight bash %}
[url "https://"]       insteadOf = git://
{% endhighlight %}

This will solve submodule issue and is much easier than other workarounds like messing up with proxy stuff and tools like `socat`.

## Git Submodules for Internal Components

Another blocker for migration is all those internal libraries you already use as submodules in your project. You still want to be able to change their code right inside submodule directory and work with git in-place. With pure CocoaPods approach this is not possible since all your changes will be reset on next `pod update`.

However, there's a beatufil work-around that allows you to benefit from both worlds (submodules and pods). Here's [a great article](http://albertodebortoli.github.io/blog/2014/03/11/cocoapods-working-with-internal-pods/) on the matter.

The idea is to use so called _Development Pods_. That means in your Podfile you specify the path to a submodule directory which has podspec file. This way CocoaPods ignores version information in podspec and uses latest files from submodule directory to generate pods. You get all the benefits of working with submodules code directly and then get all the flexibility of CocoaPods approach.

## Build Problems

Final paragraph is related to building projects with `xcodebuild` from command line. This is what happens on CI box after all.

If you try to run your old scripts which use custom configuration build directory you may run into link errors with Xcode not being able to find library file for Pods (`libPods.a`). Tools like `xctool` have this problem fixed, but I recall earlier version of `xctool` being prone to the same problem.

The solution is twofold.

- If specifying custom `CONFIGURATION_BUILD_DIR` then make it an **absolute** path

{% highlight bash %}
# Bad
CONFIGURATION_BUILD_DIR=build
# Good
CONFIGURATION_BUILD_DIR=$(pwd)/build
{% endhighlight %}

- If overriding `CONFIGURATION_BUILD_DIR` you **must** also specify `OBJROOT`, `SYMROOT` and `DSTROOT` and make sure all those are **absolute** paths as well

{% highlight bash %}
# example
OBJROOT=$(pwd)/build SYMROOT=$(pwd)/build DSTROOT=$(pwd)/build
{% endhighlight %}

{% highlight bash %}
# Example of complete build command
xcodebuild clean build \
  -workspace Sandbox-ObjC.xcworkspace \
  -scheme Sandbox-ObjC \
  -configuration Release \
  CONFIGURATION_BUILD_DIR=$(pwd)/build \
  OBJROOT=$(pwd)/build \
  SYMROOT=$(pwd)/build \
  DSTROOT=$(pwd)/build
{% endhighlight %}
