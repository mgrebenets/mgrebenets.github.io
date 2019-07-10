---
layout: post
title: "Xcode Build Settings in Depth"
description: "Xcode Build Settings in Depth"
category: Xcode
tags: [xcode, apple, ci, cli, scripts]
---
{% include JB/setup %}

Getting to the rock bottom of Xcode build settings.

<!--more-->

If you have ever done any Mac OS or iOS development, you eventually had to deal with Xcode build settings.

![Build Settings]({{ site.url }}/assets/images/build-settings/i-used-build-settings.png)

So what are those are what do we know about them?

For a standard iOS project there's roughly 500 build settings grouped into around 50 categories. These build settings control virtually every single aspect of how you app is built and packaged. At the very least, build settings is what makes Debug build so different from Release build.

In this article I'll mostly focus on build settings that control the behavior of Apple Clang and Swift compilers and the linker.

## 🗄 Background Check

Build settings are not as simple as they may seem.

For starters, there are project and target level build settings as well as default OS settings.
The default OS build settings are inherited on a project level and project level build settings are inherited on a target level.

Then there are `.xcconfig` files, which can be used to represent build settings in plain text format.
The xcconfigs can be set on target and project level and add two more levels to inheritance flow.

![Inheritance]({{ site.url }}/assets/images/build-settings/xcconfigs-inheritance.png)

To make things even more complicated, you can include other xcconfigs using C-like `#include` statements.

{% gist b56aa994dd67699f040003674d3a4b24 %}

And then there's much more to build settings and xcconfigs.

To get familiar with all of the above, I'd highly recommend to start with [The Unofficial Guide to xcconfig files](https://pewpewthespells.com/blog/xcconfig_guide.html). Check out the rest of [this amazing blog](https://pewpewthespells.com/ramble.html) for even more hands-on information about understanding and managing build settings.

## ⬇️ Level Down

Now let's get one more level down. When it comes to compiling and linking the source code, Xcode build system manages 3 main tools under the hood:

- Clang Cxx compiler for compiling C/C++ and Objective-C/C++ code
- Swift compiler
- Linker to link all object files together

![Xcode Tools]({{ site.url }}/assets/images/build-settings/xcode-tools.png)

Each of those tools has its own set of command line flags.
Clang compiler and linker flags are documented [here](https://clang.llvm.org/docs/ClangCommandLineReference.html).
`swiftc --help` command provides list of Swift command line flags. Surprisingly, I failed to find online documentation similar to Clang.

When a build setting is set in Xcode UI, Xcode then translates it to appropriate flags for underlying tools.
For example, setting `GCC_TREAT_WARNINGS_AS_ERRORS` to `YES` will add `-Werror` flag for Clang Cxx compiler.

![Cxx Treat Warnings as Errors]({{ site.url }}/assets/images/build-settings/gcc-treat-warnings-as-errors.png)

Similarly, setting `SWIFT_TREAT_WARNINGS_AS_ERRORS` to `YES` will add `-warnings-as-errors` flag to all invocations of Swift compiler.

![Swift Treat Warnings as Errors]({{ site.url }}/assets/images/build-settings/swift-treat-warnings-as-errors.png)

Finally, some build settings are translated into flags for all three tools, for example, enabling code coverage using `CLANG_ENABLE_CODE_COVERAGE = YES` build setting, will translate into the following<sup>*</sup>:

- `-fprofile-instr-generate` and `-fcoverage-mapping` for Clang compiler
- `-profile-coverage-mapping` and `-profile-generate` for Swift compiler
- `-fprofile-instr-generate` for linker

![Code Coverage Flags]({{ site.url }}/assets/images/build-settings/xcode-coverage-flags.png)

---

<sup>*</sup> Technically, it takes more than just setting `CLANG_ENABLE_CODE_COVERAGE` to enable code coverage, more details to come.

---

So, how does Xcode know which flags to map build settings to?
Where is this mapping information stored and can it be extracted?

## ⚙️ Xcode Specs

The answer to the question in previous section is Xcode Specs or _xcspecs_.

Xcspecs are ASCII plist files with `.xcspec` file extension stored deep inside Xcode.app bundle.
Xcode uses these specs to render build settings UI and to translate build settings to command line flags.

There are xcspecs for Clang compiler (`Clang LLVM 1.0.xcspec`), Swift compiler (`Swift.xcspec`) and linker (`Ld.xcspec`) as well as a number of xcspecs for core build system and other tools.
These xcspecs reference each other and work together as a system.

Each xcspec contains specification for one or more _tools_, for example, Swift xcspec contains specification for Swift compiler tool, while Clang LLVM xcspec contais specifications for Clang compiler, analyzer, couple of migrators and an [AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree) builder tool.

A tool specification includes such details as name, description, identifier, executable path, supported file types and more.

{% gist a5eebad8258096401743edce9f594488 %}

### 🔘 Options

In context of this article we are most interested in `Options` array entry of the tool's specification, which is where information about build settings is stored.
For example, the value of `SWIFT_EXEC` is stored as an option and is used by Xcode to resolve `ExecPath = "$(SWIFT_EXEC)";` statement:

{% gist 03a91b4093bc4fb35e49b7e0c5eb32b7 %}

All build settings (options) have `Name` and `Type` properties.
`Name` defines the build setting name, e.g. `SWIFT_OPTIMIZATION_LEVEL`.

Build settings may also have a `Category`, `Description` and `DisplayName` properties. For example, display name for `SWIFT_OPTIMIZATION_LEVEL` is `Optimization Level`.

A few build settings are hidden and never appear in Xcode UI. Some of them have corresponding comment in the code like `// Hidden.`, but not all.

#### Types

There are 6 different types of build settings:

- `String`
- `StringList`
- `Path`
- `PathList`
- `Enumeration`
- `Boolean`

##### ℹ️ String and Path

A build setting of `String` type has, well, a string value.

Note that string value doesn't have to be quoted using double quotes.
As a matter of fact, some build setting that have integer values are represented using `String` type with default value set to `0`, but not to `"0"`.

`Path` type is identical to `String` when used in xcspecs.

My guess is that `Path` type build settings are handled differently with regards to escaping whitespaces and other special characters.
They also get special treatment when resolving wildcard characters like `*`

##### ℹ️ StringList and PathList

`StringList` and `PathList` are used to represent list of string and path values correspondingly.

If not provided, default value is an empty list.

You can tell a list type in Xcode UI because it allows multiple values input:

![List]({{ site.url }}/assets/images/build-settings/list-type.png)

##### ℹ️ Enumeration

Values of `Enumeration` type have a fixed list of values (cases), defined using `Values` key, for example:

{% gist 5c4b859776ed778201a8f6fafc8e8acf %}

Another good example is build settings that have `YES_AGGRESSIVE` or `YES_ERROR` value on top of `YES` and `NO`. These build settings are declared as enumerations too:

{% gist 56700040c6ceb970de8278d5ed79c655 %}

![Enumeration]({{ site.url }}/assets/images/build-settings/yes-no-yes-error.png)

##### ℹ️ Boolean

Finally, values of `Boolean` type have either `YES` or `NO` value.

Note that only `YES` and `NO` are correct values for `Boolean` type, but not `"YES"` or `"NO"`.

![Boolean]({{ site.url }}/assets/images/build-settings/boolean.png)

#### 🗺 Command Line Flags Mapping

As we already know, a lot of build setting values map to different command line flags.
The mapping information is defined in xcspecs using one of the following keys:

- `CommandLineArgs`
- `CommandLineFlag`
- `CommandLinePrefixFlag`
- `AdditionalLinkerArgs`

##### ℹ️ Command Line Arguments

`CommandLineArgs` key-value entry is used to map build setting value to a _list_ of command line arguments.

###### Scalar Types

A good example is `SWIFT_MODULE_NAME` build setting of `String` type:

{% gist 56b78db453027d4c11f53f3f01a8d616 %}

The `$(value)` is resolved to current build setting value, e.g. `MyModule` value is mapped to `-module-name "MyModule"` Swift compiler flag.

###### List Types

For list types each build setting value in the list is mapped to one or more command line flags, for example:

{% gist da35fa8bd00e6a5f0febb7814492855d %}

If the value of `CLANG_ANALYZER_OTHER_CHECKERS` is `"checker1" "checker2"`, it will be mapped to the following:

{% gist c0f40ed7c7d8e00bc41f5473f83dcbdc %}

###### Enumeration Type

For enumerations types, mapping is defined for each enumeration case, for example:

{% gist d2225ee9a4f99ef9d81b8a914df2af23 %}

- `ansi` value is mapped to `-ansi` compiler flag.
- `compiler-default` maps to no flags.
- All other enumeration values map to `-std=$(value)` compiler flag. Note the use of `"<<otherwise>>"`, this is similar to `default:` enum switch in C-like languages.

###### Boolean Type

Boolean types are mapped just like enumerations with 2 `YES` and `NO` cases.

##### ℹ️ Command Line Flag

`CommandLineFlag` is used to prepend command line flag to the value of build setting.

For example, `SDKROOT` is defined like so:

{% gist efcc09c99a3eb4aa6b7a11e4c9120c63 %}

So if the value of `SDKROOT` is `iphoneos`, the corresponding Clang compiler flag will be `-isysroot iphoneos`.

In a way `CommandLineFlag` is a shorthand for using `CommandLineArgs`. I.e. in `SDKROOT` example, `CommandLineFlag = "-isysroot";` could be replaced with `CommandLineArgs = ("-isysroot", "$(value)");`.

Handling of list, enumeration and Boolean types is similar to handling `CommandLineArgs` too.
For example, given the definition:

{% gist 96617fd879004489cf5309c5a635cca8 %}

The value like `SYSTEM_FRAMEWORK_SEARCH_PATHS = "A" "B" "C"` will be mapped to:

{% gist d9e1118c1489ec8106e3316326336e50 %}

Enumerations deserve a special mention, because build flag mapping can be defined next to the value. A good example is `MACH_O_TYPE`:

{% gist 8e1ed48ff817831fe42e36cd251a582e %}

##### ℹ️ Command Line Prefix Flag

`CommandLinePrefixFlag` maps build setting value to itself _prefixed_ with a build flag.

It works just like `CommandLineFlag`, the only difference is that there's no space between the build flag and the build settings value.

A good examples are `LIBRARY_SEARCH_PATHS` and `FRAMEWORK_SEARCH_PATHS` build settings of list type, where each list entry is mapped to `-L"$(value)"` or `-F"$(value)"` correspondingly.

{% gist 4af7bc52338e4d894c14c304eb50c9e4 %}

Another similar build setting often used by developers is `OTHER_LDFLAGS`.

Finally, whenever you see a flag like `-fmessage-length=0` it's most likely mapped using prefix flag rule.

{% gist 828f232353ebd21e7a74df84e8d5df30 %}

##### ℹ️ Additional Linker Flags

Certain Swift or Clang compiler build settings map not only to compiler flags, but to linker flags as well.
Those build settings have an additional `AdditionalLinkerArgs` key-value pair, for example:

{% gist 82d846f5c45a591ceaef38d80b59cf76 %}

In this example, the `-fobjc-arc` flag will be added both to Clang compiler and linker invocations.

The way mapping works for different build setting types is identical to handling of `CommandLineArgs`.

#### References

As I've mentioned earlier, build settings from different xcspecs can reference each other.

Some build settings have a `DefaultValue` property.
It can reference other build settings, e.g. `DefaultValue = "$(BITCODE_GENERATION_MODE)";`.
Default value of some build settings is defined by referencing other build setting:

{% gist 67911f2e9771db903f22264aad0588a7 %}

![Default Value Reference]({{ site.url }}/assets/images/build-settings/swift-module-name.png)

The references can be nested as well, for example:

{% gist c0cc9d693b7c08cd61ae0ab2616ab3c2 %}

Here `$(DEPLOYMENT_TARGET_SETTING_NAME)` will be first resolved into a value like `SOME_SETTING` and then `$(SOME_SETTING)` is resolved once again to a final value. Similar to how build settings are resolved in xcconfigs.

Build settings reference can be used inside `CommandLineArgs` and all other mapping key-value entries.

#### Conditions

Conditions are defined using `Condition` key-value pair and are used to control when certain build setting is enabled or not.

For example, `SWIFT_BITCODE_GENERATION_MODE` build setting only makes sense when `ENABLE_BITCODE` is set to `YES`:

{% gist 90f7e1d17d4802557ae9cf0b0d229eb8 %}

Conditions have a C-like syntax, although string values do not have to be quoted. Such boolean operators as `!`, `&&`, `||`, `==` and `!=` can be used:

{% gist 60a9ad0440a2eb705e90590b13dbc235 %}

#### Other Properties

There are other properties, such as

- `Architectures` - defines which target architectures the build setting is applicable for.
- `AppearsAfter` - controls the order in which 2 specific build settings appear in Xcode UI.
- `FileTypes` - list of applicable file types.
- `ConditionFlavors` - must have something to do with the way conditions are checked.
- Some other flags I didn't have time to fully investigate yet.

## 👩‍🏫 Example

Let's have a look at one build setting example and see how we can apply all the knowledge from this article to figure out which flags it will map to.

The build setting is `CLANG_ENABLE_CODE_COVERAGE` and it enables one very important feature - code coverage.

`CLANG_ENABLE_CODE_COVERAGE` is defined in `Clang LLVM 1.0.xcspec` but strangely maps to no flags at all...

{% gist a49b86699e6e27d31e2a77331adfd1e1 %}

However, `CLANG_ENABLE_CODE_COVERAGE` is referenced by `CLANG_COVERAGE_MAPPING`.

{% gist 46abc931ad16ccbdcdb9956edcb29a9f %}

So now we know the Clang compiler flags added to compiler invocation when code coverage is enabled.

Additionally, there's another build setting that controls the linker flag:

{% gist 0cd24fccb0bdb8a2208d7672759f2c35 %}

It also comes with a very detailed comment.

Finally, `CLANG_COVERAGE_MAPPING` is also defined in `Swift.xcspec`:

{% gist 522294a2e07fbcda045deaa07da8c9a4 %}

Now all the pieces of the puzzle come together and it's clear how Xcode does the mapping.

![Code Coverage Flags]({{ site.url }}/assets/images/build-settings/xcode-coverage-flags.png)

The only problem is that both `CLANG_COVERAGE_MAPPING` and `CLANG_COVERAGE_MAPPING_LINKER_ARGS` are hidden and don't show up in Xcode UI. So how do those get set if they don't reference `CLANG_ENABLE_CODE_COVERAGE` in their default value?

The code coverage can be enabled by editing the scheme in Xcode UI or by passing `-enableCodeCoverage YES` to `xcodebuild` invocation

![Default Value Reference]({{ site.url }}/assets/images/build-settings/enable-coverage.png)

{% gist 753c5ea0ca550b857f3376bcef67ed96 %}

Xcode will then set both `CLANG_COVERAGE_MAPPING` and `CLANG_COVERAGE_MAPPING_LINKER_ARGS` to `YES` under the hood.

## 👷‍ Application

OK then, so it's more or less clear how build settings are resolved, but what's the practical application?

Well, there's the purely academic application where you get to know how things work, which occasionally will come handy when you have hard time figuring out some build settings mess.

While the official [Xcode Build Settings](https://help.apple.com/xcode/mac/10.2/#/itcaec37c2a6) reference page is a good resource to use, the [Extended Xcode Build Settings reference like this one](https://github.com/mgrebenets/fastlane-plugin-xcconfig_actions/blob/master/lib/fastlane/plugin/xcconfig_actions/helper/xcspecs/10.2/README.md) includes information about compiler and linker flags, build settings cross-reference and more.

There are other ways to use this knowledge.

Let's say you want to try out alternative build system like [Buck](https://buckbuild.com) or [Bazel](https://bazel.build/). Those build systems are gaining popularity these days. Buck was created by Facebook while Bazel came from Google. Other companies such as Uber, Airbnb and Dropbox use Buck; while Lyft is using Bazel to build their mobile apps.

Let's further assume that over the years you have created and maintained a number of amazing xcconfig files. Those xcconfigs have all the compiler and linker build settings fine-tuned for your use. While moving to tools like Buck, you can't just bring xcconfigs over, instead you'd want to translate xcconfigs to compiler and linker flags and then use those with Buck.

Well, now you have all the knowledge to do so.
You'd need to start with reading and resolving xcconfigs and then map resolved build settings to build flags.
It's not a straightforward task and may take a while to implement.
Luckily for you, there's a [Fastlane plugin](https://github.com/mgrebenets/fastlane-plugin-xcconfig_actions) that does just that.

Like many unofficial tools, this plugin is reverse engineering the ways Xcode works, so use it at your own risk.
