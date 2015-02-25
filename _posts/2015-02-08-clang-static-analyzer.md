---
layout: post
title: "Clang Static Analyzer"
description: "Clang Static Analyzer for iOS projects"
category: Mobile CI
tags: [mobile, ci, clang, xcode, ios, analyze]
---
{% include JB/setup %}

A brief post about [Clang Static Analyzer](http://clang-analyzer.llvm.org/).

<!--more-->

Clang Static Analyzer is a source code analysis tool that finds bugs in C, C++, and Objective-C programs. Yep, no Swift yet.

You may have used it already since a specific and stable build of clang static analyzer comes bundled with Xcode installation. It's `⇧⌘B` (Shift + Command + B) shortcut in Xcode or `analyze` action when building from command line.

{% highlight bash %}
xcodebuild analyze -project MyProject.xcodeproj -scheme MyScheme
{% endhighlight %}

Time to answer your question "Why not using bundled analyzer then?". I can give two reasons. First is that latest static analyzer build can have some fixes and new features, though some of those will be experimental. The second reason is more important for me, that is generating reports. Well, Xcode does generate compelling reports so to say. It highlights all the problems with those nice arrows and messages. However, the only way to look at those is in IDE itself. Most likely somewhere in configuration build directory one can dig out analyzer results and convert them to HTML or other report format. Standalone clang static analyzer makes report generation task much easier, and report are important for CI.

## Installation

Unlike [OCLint]({% post_url 2015-02-08-oclint %}) Clang Static Analyzer is not available for installation neither via [Homebrew](http://brew.sh/) nor via [Homebrew Cask](https://github.com/caskroom/homebrew-cask). So installation is a bit manual and consists of usual steps

Get the tar-ball and unzip it, then move or copy to `/usr/local` and update the path in your shell profile (`.bash_profile` in this example).

{% highlight bash %}
# get the tarball
wget http://clang-analyzer.llvm.org/downloads/checker-276.tar.bz2

# tar xzf (extract zee filez)
tar xzf checker-276.tar.bz2

# move to /usr/local (aka install)
mv checker-276 /usr/local/llvm-checker

# put these lines in shell profile (e.g. .bash_profile)
# Clang Static Analyzer
LLVM_CHECKER_HOME=/usr/local/llvm-checker
export PATH=$LLVM_CHECKER_HOME:$PATH

{% endhighlight %}

Restart your shell session or source profile and you are good to go. Run `scan-build` to make sure installation is successful.

## Usage

You can use it in two ways, from Xcode or from command line.

To learn how to use it from Xcode [read this documentation](http://clang-analyzer.llvm.org/xcode.html). I never actually did it, default analyzer output was more than enough for me when running it in IDE. Aware that others mention [a number of caveats](http://loufranco.com/blog/xcode-better-build-and-analyze) with this approach, some not so obvious configuration tweaks required to make it work properly.

I'm more interested in running it from command line and generating reports for CI tasks. [Here's the original documentation](http://clang-analyzer.llvm.org/scan-build.html) with some good examples.

The basic usage is supposed to be as simple as this

{% highlight bash %}
# build a scheme
scan-buld -k -v -v xcodebuild clean build -project MyProject.xcodeproj -scheme MyScheme -configuration Debug
{% endhighlight %}

But in practice I find it not working as advertised if your project has custom build configuration and specifies a lot of warning flags. In those cases I find that falling back to clang static analyzer bundled with Xcode is more robust option.

{% highlight bash %}
# build a scheme
scan-buld -k -v -v --use-analyzer Xcode \
  xcodebuild clean build -project MyProject.xcodeproj -scheme MyScheme -configuration Debug
{% endhighlight %}

Like I said, I'm after reports most of the time, so not using some cutting edge analyzer features is OK with regards to the goals I have to achieve.

Another note is that using `-scheme` will require code signing in the end. Try switching to `-target` if that is a problem, otherwise explicitly specify `CODE_SIGN_IDENTIFY` to `xcodebuild`.

{% highlight bash %}
# build a scheme
scan-buld -k -v -v --use-analyzer Xcode \
  xcodebuild clean build -project MyProject.xcodeproj -target MyTarget -configuration Debug
{% endhighlight %}

## Reports

Use `-o` (output) option to specify output directory for reports.

{% highlight bash %}
# build a scheme
mkdir -p clang-reports

scan-buld -k -v -v \
  --use-analyzer Xcode \
  -o clang-reports \
  xcodebuild clean build -project MyProject.xcodeproj -target MyTarget -configuration Debug
{% endhighlight %}

## CI

I've already touched this topic in my [Jenkins vs Bamboo]({% post_url 2015-01-29-bamboo-vs-jenkins %}) comparison. For both CI servers your best option is to publish clang static analyzer reports as HTML page. Analyzer warnings and errors will also be picked up by [Warnings plugin](https://wiki.jenkins-ci.org/display/JENKINS/Warnings+Plugin) in case of Jenkins, and you are up to some grepping or other voodoo if you are dealing with Bamboo.

All in all clang static analyzer is another great tool to have at your disposal, especially if you are working on CI tasks.
