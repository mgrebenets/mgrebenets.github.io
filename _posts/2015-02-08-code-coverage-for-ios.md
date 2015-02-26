---
layout: post
title: "Code Coverage for iOS"
description: "Code Coverage for iOS"
category: Mobile CI
tags: [mobile, ci, test, ios, coverage]
---
{% include JB/setup %}

Create code coverage reports for iOS unit tests.

<!--more-->

Calculating [Code Coverage](http://en.wikipedia.org/wiki/Code_coverage) is a way to get more out of your unit tests, given that you have those and run on regular basis. With minor changes you can get coverage reports that include stats for

- Packages
- Files
- Classes
- Lines
- Conditionals

## Enable

Good staring point is [documentation from Apple](https://developer.apple.com/library/ios/qa/qa1514/_index.html). Important takeaway from that article is that you need 2 sets of files to generate coverage reports. The `.gcno` files contain information to reconstruct the basic block graphs and assign source line numbers to blocks. The `.gcda` files are generated when the tests are executed and contain transition counts and some summary information. Check [this link](http://gcc.gnu.org/onlinedocs/gcc-4.24/gcc/Gcov-Data-Files.html) for more details.

The Apple's article recommends to create a separate configuration and set the following LLVM 5.0 Code Generation options to `YES`.

- Generate Debug Symbols (`GCC_GENERATE_DEBUGGING_SYMBOLS`)
- Generate Test Coverage Files (`GCC_GENERATE_TEST_COVERAGE_FILES`)
  - This is required to generate `.gcno` files.
- Instrument Program Flow (`GCC_INSTRUMENT_PROGRAM_FLOW_ARCS`)
  - This is required to get `.gcda` files.

I have also specified the GCC settings names so you'd know how to enable these flags when building from command line or when using xcconfigs. The benefit of building from command line is that you don't have to create new configuration in the project, instead you can customize existing Debug configuration.

{% highlight bash %}
xcodebuild test -project MyProject.xcodeproj -scheme MyScheme \
  -configuration Debug \
  -sdk iphonesimulator8.1 \
  -destination OS=8.1,name="iPad Retina" \
  GCC_GENERATE_DEBUGGING_SYMBOLS=YES \
  GCC_GENERATE_TEST_COVERAGE_FILES=YES \
  GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES
{% endhighlight %}

If you've just ran this command you will be surprised to find no `.gcda` files anywhere. Apparently, writing these files to disk is a costly operation so this data needs to be flushed with explicit command. The way to do that is to call `__gcov_flush` in your app's code. Apple recommends to do that when the app is sent to background, here's the quote

> Set the UIApplicationExitsOnSuspend key to YES in your Info.plist file and send your running application to the background by pressing the home button.

This is very un-automatic and very un-CI, Apple. [This readme](https://github.com/leroymattingly/XCode5gcovPatch) provides a list of other options. Well, the first one is reacting to the event of app entering background, which is not good. The second option uses method swizzling and swizzles `tearDown` method of `XCTest` class. This way `GCOV` data will be flushed when _all_ the test cases are completed.

I am using swizzling as well, but swizzle `tearDown` method of `XCTestCase`. This way data is flushed every time a test case finishes.

{% highlight objective-c %}
#ifdef ENABLE_GCOV_FLUSH

@import XCTest;
@import ObjectiveC.runtime;

// If you have to build for versions below iOS 7.0, use this code instead
// #import <XCTest/XCTest.h>
// #import <objc/runtime.h>


extern void __gcov_flush();

@implementation XCTestCase (GCovFlush)

+ (void)load {
    Method original, swizzled;

    original = class_getClassMethod(self, @selector(tearDown));
    swizzled = class_getClassMethod(self, @selector(_swizzledTearDown));
    method_exchangeImplementations(original, swizzled);
}

+ (void)_swizzledTearDown {
    if (__gcov_flush) {
        __gcov_flush();
    }
    [self _swizzledTearDown];
}

@end

#endif
{% endhighlight %}

Note that I don't have a header file. There's no need for it since you are not going to include it anywhere. Another notable difference is the use of ifdef guard `ENABLE_GCOV_FLUSH` which needs to be defined when building from command line, this is just me being over paranoid about including any kind of non-production code in the app. Save this file and name it `XCTestCase+GCovFlush.m` Before you add it to your project, one very important note

> The file must be added to the main app target, also called "Test Host", _not_ to the unit tests target. [More details](http://stackoverflow.com/questions/19136767/generate-gcda-files-with-xcode5-ios7-simulator-and-xctest).

OK, so now you can add this file to your Xcode project. There are ways to automate this injection as well, e.g. using [xcodeproj Ruby gem](https://github.com/CocoaPods/Xcodeproj). I plan to have a write up about it some time later. Anyway, you can now run your tests and have `.gcno` and `.gcda` files at your disposal.

{% highlight bash %}
xcodebuild test -project MyProject.xcodeproj -scheme MyScheme \
  -configuration Debug \
  CONFIGURATION_BUILD_DIR=build \
  -sdk iphonesimulator8.1 \
  -destination "OS=8.1,name=iPad Retina" \
  GCC_GENERATE_DEBUGGING_SYMBOLS=YES \
  GCC_GENERATE_TEST_COVERAGE_FILES=YES \
  GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES \
  GCC_PREPROCESSOR_DEFINITIONS="\$(GCC_PREPROCESSOR_DEFINITIONS) ENABLE_GCOV_FLUSH=1" \
  | tee test.log
{% endhighlight %}

Note that I'm redefining preprocessor definitions to enable `ENABLE_GCOV_FLUSH` and also want to reuse those already defined in Xcode project, that's why I refer to them with help of escaping `$` sign. I'm also capturing logs in `test.log` for further processing.

This paragraph has nothing to do with coverage reports, but you need to capture test results in a report format that most CI servers would understand. You can use [ocunit2junit](https://github.com/ciryon/OCUnit2JUnit) to convert OCUnit (now XCTest) report to [JUnit](http://junit.org/) format.

{% highlight bash %}
# install
[sudo] gem install ocunit2junit

# run
cat test.log | ocunit2junit
{% endhighlight %}

Default output is in `test-reports` directory, point your CI report plugin to this location to pick up XML and generate test reports.

If you are OK with using something other than `xcodebuild`, check out [Facebook's `xctool`](https://github.com/facebook/xctool). It has few options to help you get test reports without the need of `ocunit2junit`.

## Report

It's time to report the coverage results. [gcovr](http://gcovr.com/) is the right tool for the job. Since it's a Python utility, here's how you install it

{% highlight bash %}
sudo -E easy_install pip
pip install gcovr
{% endhighlight %}

Use `-E` option to tell `easy_install` to pick up current user's environment variables such as `HTTP_PROXY` while running as super user. Don't bother with this option if you can run `easy_install` as a non-sudoer, e.g. when you have custom Python installation.

Use `-x` or `--xml` to generate XML report. `gcovr` has issues with generating HTML reports, we'll have to use another tool for the job later.

{% highlight bash %}
BUILD_DIR=build
GCOV_FILTER='.*/MyClasses.*'
GCOV_EXCLUDE='(.*./Developer/SDKs/.*)|(.*./Developer/Toolchains/.*)|(.*Tests\.m)|(.*Tests/.*)'
COVERAGE_REPORT=coverage.xml

gcovr \
    --filter=${GCOV_FILTER} \
    --exclude=${GCOV_EXCLUDE} \
    --object-directory=${BUILD_DIR} -x > ${COVERAGE_REPORT}
{% endhighlight %}

This example also demonstrates the use of filter and exclude options to filter unwanted files from reports. `BUILD_DIR` points to the directory you defined with help of `CONFIGURATION_BUILD_DIR` when running the tests.

The XML output is enough for CI tasks, but to have a sneak peek at readable HTML results on your computer you'll end up nowhere with `gcovr`. The tool to help at this time is [lcov](http://ltp.sourceforge.net/coverage/lcov.php).

{% highlight bash %}
# install
brew install lcov

# use
BUILD_DIR=build
LCOV_INFO=lcov.info
LCOV_EXCLUDE="${LCOV_INFO} '*/Xcode.app/Contents/Developer/*' '*Tests.m' '$(BUILD_DIR)/*'"
LCOV_REPORTS_DIR=lcov-reports

lcov --capture --directory ${BUILD_DIR} --output-file ${LCOV_INFO}
lcov --remove ${LCOV_EXCLUDE} --output-file ${LCOV_INFO}
genhtml ${LCOV_INFO} --output-directory ${LCOV_REPORTS_DIR}
{% endhighlight %}

Here you can see another use of exclude option to filter out unwanted results. `genhtml` is bundled with `lcov` installation. More documentation on `lcov` can be [found here](https://wiki.documentfoundation.org/Development/Lcov).

## Summary

The real point of calculating code coverage reports is to use them as part of CI process to keep track of overall project health and mark it as unstable or failed if coverage is less than required. Check out [Jenkins vs Bamboo article]({% post_url 2015-01-29-bamboo-vs-jenkins %}) for more details.
