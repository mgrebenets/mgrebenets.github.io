---
layout: post
title: "Clang Static Analyzer"
description: "Clang Static Analyzer for iOS projects"
category: Mobile CI
tags: [mobile, ci, clang, xcode, ios, analyze, scan-build]
---
{% include JB/setup %}

A brief post about [Clang Static Analyzer](http://clang-analyzer.llvm.org/) and [scan-build](http://clang-analyzer.llvm.org/scan-build.html) tool.

<!--more-->

Clang Static Analyzer is a source code analysis tool that finds bugs in C, C++, and Objective-C programs. Yep, no Swift yet.

# Xcode and xcodebuild
You may have used it already since a stable build of clang static analyzer comes bundled with Xcode. It's `⌘⇧B` (Command + Shift + B) shortcut in Xcode or `analyze` action when building from command line.

{% highlight bash %}
xcodebuild analyze -project MyProject.xcodeproj -scheme MyScheme -configuration Debug
{% endhighlight %}

When running Analyze action in Xcode you get a beautiful report with nice arrows rendered right on top of the source code.
While running from command line the analyzer errors will show up in build log.  

The build log by itself should be enough for integration with CI servers, but you can actually get more out of standard `xcodebuild analyze` action. Using `CLANG_ANALYZER_OUTPUT` and `CLANG_ANALYZER_OUTPUT_DIR` you can control in which form analyzer creates report and where. Valid options for `CLANG_ANALYZER_OUTPUT` are `text`, `html` and `plist`. You can combine multiple options using dash: `plist-html`.

{% highlight bash %}
xcodebuild analyze -project MyProject.xcodeproj -scheme MyScheme -configuration Debug \
    CLANG_ANALYZER_OUTPUT=plist-html \
    CLANG_ANALYZER_OUTPUT_DIR="$(pwd)/clang"
{% endhighlight %}

There will be a lot of output files in `clang` directory, using `find` you can locate HTML report.

{% highlight bash %}
find clang -name "*.html"
# It will find a file named like report-f27e58.html
{% endhighlight %}

Open it in a browser and it looks just like the one in Xcode.

## Under the Hood
If you are curious what are those not-so-much-documented `CLANG_ANALYZER_` build settings, this section may shed some light for you.

`CLANG_ANALYZER_OUTPUT=html` translates into `-Xclang -analyzer-output=html` when `xcodebuild` composes and executes `clang` command. Similar story for `CLANG_ANALYZER_OUTPUT_DIR`. You can call `clang -cc1 --help` yourself, there are a lot of interesting things in the help message. For example, running `clang -cc1 -analyze -analyzer-checker-help` will list all the available checkers. If you look at build log closely now, you will see how `xcodebuild` configures all those checkers using `-Xclang -analyzer-config` and `-Xclang -analyzer-checker` flags.

With this knowledge, you should be able to tweak default Xcode Analyze configuration by modifying Xcode build settings. To be honest, I never had to do that. If you really want more control over static analyzer, you should look at [scan-build](http://clang-analyzer.llvm.org/scan-build.html) tool.

# scan-build
[scan-build](http://clang-analyzer.llvm.org/scan-build.html) is a command line utility that enables a user to run the static analyzer over their codebase as part of performing a regular build (from the command line).

> Since scan-build comes with bundled clang executable, it can be outdated. For example, build 277 does not support some of the compiler flags which work with Xcode 7. If you see an error like the one below, you'd better fall back to using `xcodebuild analyze`.

{% highlight bash %}
clang: error: unknown argument: '-fembed-bitcode-marker'
{% endhighlight %}

## Installation

Unlike [OCLint]({% post_url 2015-02-08-oclint %}) Clang Static Analyzer is not available for installation neither via [Homebrew](http://brew.sh/) nor via [Homebrew Cask](https://github.com/caskroom/homebrew-cask). Well, there's a [pull request for a new cask](https://github.com/caskroom/homebrew-cask/pull/17456), so probably by the time you read this `brew cask install scan-build` will just work... Otherwise installation is a bit manual and consists of usual steps

Get the tar-ball and unzip it, then move or copy to `/usr/local` and update the path in your shell profile (`.bash_profile` in this example).

{% highlight bash %}
# Get the tarball
wget http://clang-analyzer.llvm.org/downloads/checker-277.tar.bz2

# Untar - xzf (extract zee filez)
tar xzf checker-276.tar.bz2

# Move to /usr/local (aka install)
mv checker-276 /usr/local/llvm-checker

# Put these lines in shell profile (e.g. .bash_profile)
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
# Build a scheme
scan-build -k -v -v xcodebuild clean build -project MyProject.xcodeproj -scheme MyScheme -configuration Debug
{% endhighlight %}

But in practice it doesn't always find the static analyzer this way. One way to avoid this problem is to specify clang static analyzer bundled with Xcode. Another option is to give it a full path to `clang-check`

{% highlight bash %}
# Use analyzer bundled with xcode
scan-build -k -v -v --use-analyzer Xcode \
  xcodebuild clean build -project MyProject.xcodeproj -scheme MyScheme -configuration Debug

# Use path to clang-check executable
CLANG_CHECK=$(dirname $(which scan-build))/bin/clang-check

scan-build -k -v -v --use-analyzer ${CLANG_CHECK} \
  xcodebuild clean build -project MyProject.xcodeproj -scheme MyScheme -configuration Debug
{% endhighlight %}

Another note is that using `-scheme` will require code signing in the end. Try switching to `-target` if that is a problem, otherwise explicitly specify `CODE_SIGN_IDENTIFY` to `xcodebuild`.

{% highlight bash %}
# Build a target
scan-build -k -v -v --use-analyzer Xcode \
  xcodebuild clean build -project MyProject.xcodeproj -target MyTarget -configuration Debug
{% endhighlight %}

## Reports

Use `-o` (output) option to specify output directory for reports.

{% highlight bash %}
mkdir -p clang-reports

# Build a target
scan-build -k -v -v \
  --use-analyzer Xcode \
  -o clang-reports \
  xcodebuild clean build -project MyProject.xcodeproj -target MyTarget -configuration Debug
{% endhighlight %}

There are dozens of other options you can use to customize `scan-build`, try `scan-build -h` to see all of them.

It is also supposed to be easier to customize checkers with `scan-build`. I had never had a chance to do that, you must have some compelling reason to go beyond default configuration.

# CI

I've already touched this topic in my [Jenkins vs Bamboo]({% post_url 2015-01-29-bamboo-vs-jenkins %}) comparison. For both CI servers your best option is to publish clang static analyzer reports as HTML page. Analyzer warnings and errors will also be picked up by [Warnings plugin](https://wiki.jenkins-ci.org/display/JENKINS/Warnings+Plugin) in case of Jenkins, and you are up to some grepping or other voodoo if you are dealing with Bamboo.

All in all clang static analyzer is another great tool to have at your disposal, especially if you are working on CI tasks.

# References

- [clang -cc1 options list](https://gist.github.com/masuidrive/5231110)
- [Clang Command Guide](http://clang.llvm.org/docs/CommandGuide/clang.html)
- [SO discussion wrt xcodebuild analyze output 1](http://stackoverflow.com/questions/14277773/getting-html-output-from-xcodes-built-in-static-analysis)
- [SO discussion wrt xcodebuild analyze output 2](http://stackoverflow.com/questions/22371789/how-to-make-the-clang-static-analyzer-output-its-working-from-command-line)
