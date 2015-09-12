---
layout: post
title: "Makefiles for Mobile CI"
description: "Use of Makefiles for Mobile CI"
category: Mobile CI
tags: [mobile, ci, ios, makefile, make]
---
{% include JB/setup %}

A look at Xcode projects from another angle, trying to build things on another level.

<!--more-->

When I started with iOS development, not much really existed in my noob view outside the Xcode IDE. For quite a while Xcode used to be my whole universe. I could go through the whole app life cycle from first line of code all the way to uploading it to App Store, all of that in Xcode (except minor detour to iTunes Connect web interface). At some point my universe had to expand and I learned about basics of internal Xcode project structure, Xcode workspaces, `xcconfig` files, custom build phases and so on. Eventually I got out of the metaphorical Solar system (Xcode IDE) and dived into the black void of terminal window and command line interface.

## Xcode Limits

In this article I will try to show you other ways to build Xcode projects. There's nothing bad with Xcode projects as such. As I mentioned before, you can have quite an elaborate configuration with multiple targets, schemes, cross-target dependencies. You can include and build sub-projects, define custom build phases such as running shell scripts. Then finally you can use _xcconfig_ files to take out project settings out of ASCII plist format and control them in plain text.

With all that goodness you will eventually get to the limits of what Xcode project can do. Here are some examples.

[CocoaPods](http://cocoapods.org/). You have to get out of your "comfort zone" and run `pod install` and `pod setup` from command line to get Xcode project all set up. Though you could create a custom target with a shell script pre-build phase to do just that.

If you have a lot of post-build phases with shell scripts, you probably want some of those to be executed only when you really need it. Have you ever seen hundreds of dSYMs uploaded to [Crashlytics](https://try.crashlytics.com/) because that small shell script phase was executed each time a developer would hit `Cmd + B`? That's just one example.

No matter how sophisticated is your use of _xcconfigs_, you'll eventually want to build an app overriding some of build settings from command line. That's often the case in CI setup, where you want to build with another provisioning profile, sign with another signing identity, etc. Going into the code and changing _xcconfig_ manually doesn't work for CI and it's too manual. Having dozens of targets with _xcconfigs_ that differ in one or two lines is another not so pleasant experience.

Back to shell scripts as custom build phases. Given that you have half a dozen of those, you will want to reuse them for other projects as well. Does copy-paste feel right? It should not and that's yet another reason to see how building iOS projects can be taken to the next level.

## Make Utility

The answer, well, one of the answers, is [make](http://en.wikipedia.org/wiki/Make_%28software%29) utility and [makefiles](http://en.wikipedia.org/wiki/Makefile).

`make` is a build automation tool. It automatically builds programs and libraries from source code by reading files called **makefiles** which specify how to derive the target program. Phew, that's enough of Wiki copy-paste. `make` was initially released in 1977! That's years before I myself was "released" so to say. By ways of evolution and inheritance `make` is a part Mac OS X by default, so why not trying to use it for something good?

## Makefile

`make` is using makefiles, which contain so called _recipes_ often referred to as _targets_, a set of instructions for building the app, library, or whatever you are up to. Does `make clean` sound familiar now?

Makefile syntax is similar to shell syntax, but not exactly the same. The fact that you can use shell commands in makefile makes it a bit more confusing.

### Basic Recipes

Let's start with a set of simple targets. To define a target you normally tell _what_ you want to build and after a colon (`:`) you tell _how_. Let's create a file named `Makefile`.

{% highlight makefile %}
PROJECT = MyProject.xcodeproj
SCHEME = MyScheme
BUILD_DIR = build

# phony targets
.PHONY: all clean help

# default target
all: help

# clean target
clean:
  @echo Cleaning up...
  xcodebuild clean -project $(PROJECT) \
    -scheme $(MYSCHEME)
  @rm -rf $(BUILD_DIR)

help:
  @echo Targets:
  @echo "clean - clean the project"
  @echo "help - display this message"
{% endhighlight %}

Let's see what's going on here. `all` is the default target which is executed when you just run `make`. Here you can see how target _dependencies_ can be used. `all` is dependent on `help` and `help` is just printing information about all available targets. Other than causing `help` to run, `all` doesn't do anything else.

Another trick - phony targets, those are all listed as dependencies for a special `.PHONY` target. Using phony targets is the way you can tell `make` utility to build those targets each time. By default `make` is smart and checks for any changes since last build and does nothing if it detects no changes. In this case I don't want that behavior, that's why I use phony targets.

The `clean` target cleans Xcode project using `xcodebuild` under the hood. It also removes the `build` folder. The actual recipe for `clean` is a number of shell commands. By default `make` will print out all the executed commands to stdout. The use of `@` as in `@echo` will remove the "echo Cleaning up..." line form stdout and you will see only the "Cleaning up..." message. Another nice thing is that just like with shell you can use `\` to split single command into multiple lines.

This example also features the use of variables in a makefile. You might have noticed that it's less strict than the shell syntax, e.g. it allows use of spaces around assignment operation. Using `$()` you can reference variables, shell-like `${}` is also a valid syntax. You could as well just use `$` without `()` or `{}`, but I'd recommend sticking with `$()` all the time. Having `$PROJECT` resolved as `$P` `ROJECT` is not the easiest thing to figure out. Finally `make` lets you override variables from command line.

Try running `make clean` to see how it works.

{% highlight bash %}
make clean SCHEME=MyOtherScheme
{% endhighlight %}

`make` will look for a file named `Makefile` by default, though you can always feed it any makefile you want.

{% highlight bash %}
make -f MyOtherMakefile clean
{% endhighlight %}

### Functions

At this moment it should be obvious that makefiles are using [Domain Specific Language](http://en.wikipedia.org/wiki/Domain-specific_language) or DSL. It so happens that this language has functions among other things.

Let's look at two targets, `build` and `test`.

{% highlight makefile %}
PROJECT = MyProject.xcodeproj
SCHEME = MySceme

build:
  xcodebuild build \
    -project $(PROJECT) \
    -scheme $(SCHEME)

test:
  xcodebuild test \
    -project $(PROJECT) \
    -scheme $(SCHEME)
{% endhighlight %}

Looks a bit [DRY](http://en.wikipedia.org/wiki/Don%27t_repeat_yourself) doesn't it? Here's how you can define a function called `xcodebuild` to be able to reuse some code.

{% highlight makefile %}
PROJECT = MyProject.xcodeproj
SCHEME = MySceme

# Build with xcodebuild
# usage: $(call xcodebuild,ACTION,PROJECT,SCHEME)
xcodebuild = \
  xcodebuild $(1) \
    -project $(2) \
    -scheme $(3)

build:
    $(call xcodebuild,build,$(PROJECT),$(SCHEME))

test:
    @$(call xcodebuild,test,$(PROJECT),$(SCHEME))
{% endhighlight %}

Well, to be honest, this doesn't look like the best example in the world, but still it demonstrates the use of functions. You can pack some reusable code into the function, then call functions from functions and eventually gain benefit from this approach. Interestingly enough, when it comes to calling functions makefiles do not tolerate spaces, as you can see I put no spaces after `,` when passing arguments. Arguments are positional and not named, you have to refer to them with `$(1)`, `$(2)` and so on. You can still use `@` to filter out extra output from stdout.

To call a function you use `$(call function-name,arg1,arg2,...)` syntax.

### Shell Commands

When writing code outside of target recipe, you can call shell commands using `shell` keyword.

{% highlight makefile %}
PROJECT = $(shell ls -1 . | grep .xcodeproj)
{% endhighlight %}

This example will find first file with `.xcodeproj` extension and save it to `PROJECT` variable. If using CocoaPods you can modify shell script to filter out `Pods.xcodeproj`.

Here's more advanced example, that demonstrates nesting of shell commands.

{% highlight makefile %}
CLANG_ANALYZER = $(shell dirname $$(which scan-build))/bin/clang-check
{% endhighlight %}

Note how I have to escape `$` with another `$` when capturing results of `which` command, that's because single `$` is part of makefile syntax and will try to resolve `$(which scan-biuild)` as makefile variable but not as shell expression.

An example for shell for-loop.

{% highlight makefile %}
SCOPE = -iregex ".*\.(h|m|mm)$$"
MAKEFILE_VAR = Value

for-loop:
  @(for file in $(shell find -E . $(SCOPE)); do \
    echo "Do something for $${file} using $(MAKEFILE_VAR)";	\
  done)
{% endhighlight %}

This code will loop through all files with `.h`, `.m` or `.mm` extensions. Again notice the use of double `$$` for referring to shell variables vs single `$` for makefile variables. The `@(...)` is used to wrap the whole expression and prevent it from showing up in stdout. It also demoes the use of multiline scripts. Here's an example of a one-liner for-loop.

{% highlight makefile %}
BUILD_DIR = build

one-liner-for-loop:
  for f in $(shell find . -name $(BUILD_DIR)); do echo Removing $${f} ...; rm -rf $${f}; done
{% endhighlight %}

In general, any shell script will work, just don't forget to escape `$`s properly and keep an eye for makefile/shell syntax differences.

### Flow Control

You have already seen that it's possible to use all shell flow control operators in the recipe. If you want that level of control outside the recipe, you can use makefile's own flow control operators.

For example, a basic if-block.

{% highlight makefile %}
ANALYZER = xcode
CLANG_ANALYZER = Xcode
ifeq ($(CLANG_ANALYZER), scan-build)
CLANG_ANALYZER = $(shell dirname $$(which scan-build))/bin/clang-check
endif
{% endhighlight %}

Now by calling `make` with different parameter you can influence the value of `CLANG_ANALYZER` variable.

{% highlight bash %}
make analyze ANALYZER=scan-build
# value of CLANG_ANALYZER will be /usr/local/bin/clang-check/
{% endhighlight %}

These flow control operators can be used outside as well as inside recipes. Have a look at `foreach` example.

{% highlight makefile %}
PLATFORMS = linux mac windows
RUBY_FILES = $(shell find . -type f -name '*.rb')
RUBY_LOG = check-ruby-syntax.log

check-ruby-syntax:
  @$(foreach platform, $(PLATFORMS), \
      echo Platform: $(platform); \
      $(foreach file, $(RUBY_FILES), \
        export PLATFORM=$(platform); \
        ruby -wc $(file) 1>>$(RUBY_LOG) 2>>$(RUBY_LOG); \
      ) \
    )
{% endhighlight %}

This example is from a bit different world of Ruby. It iterates through a list of platforms (linux, mac and windows), then for each platform it iterates through all `.rb` files it can find. For each file it sets the shell environment variable `PLATFORM` and runs Ruby syntax check command (`ruby -wc`) writing errors and warnings to the log file.


One more makefile command worth mentioning is `eval`. It can be used inside the recipe to assign new value to makefile variable, for example

{% highlight makefile %}
MAKEFILE_VAR = 0

eval:
  $(eval MAKEFILE_VAR := 1)
{% endhighlight %}

Of course you can use more complex expressions, e.g. assign a result of some function to `MAKEFILE_VAR`.

### Includes and Reuse

If rich DSL syntax wasn't enough, you can get another level of reuse from makefiles. You can include them to each other just like good old C header files.

Consider this example

{% highlight makefile %}
# Actual directory of this Makefile, not where it is called form
SELF_DIR = $(dir $(lastword $(MAKEFILE_LIST)))

# Include common Batman Makefile
include $(SELF_DIR)/CommonMakefile
{% endhighlight %}

This is how you can include `CommonMakefile` into another makefile. The magical `SELF_DIR` construction is the way to get absolute path of the makefile itself. This is useful when you call `make` and give it a path to makefile which is located in some other folder and then `CommonMakefile` is located in the same directory with original makefile. Kind of `require_relative` if you ever dealt with Ruby.

Including makefiles suggests the ability to reuse recipes, and that's possible indeed. To make recipe reusable use double colon `::` when defining it.

{% highlight makefile %}
# in CommonMakefile
clean::
  echo "Common clean..."
  @rm -rf CommonBuildDir

# in SpecificMakefile
clean::
  echo "Specific clean..."
  @rm -rf SpecificBuildDir
{% endhighlight %}

As you'd expect, the `clean` recipe in `SpecificMakefile` will first run `clean` recipe from `CommonMakefile`.

## Configuration as a Code

Imagine that you've created a bunch of recipes in your makefile, for example

- clean
- build
- test
- analyze (e.g. [Clang Static Analyzer]({% post_url 2015-02-08-clang-static-analyzer %}))
- lint (e.g. [OCLint]({% post_url 2015-02-08-oclint %}))
- deploy (e.g. to [HockeyApp](http://hockeyapp.net/))

You have practically created all the build tasks for your CI job. Depending on the size of your project, you can execute those separately, e.g. `make test` or combine into one recipe and run as one `make ci` command.

{% highlight makefile %}
ci: clean build test analyze lint deploy
  echo "Running CI target ..."
{% endhighlight %}

All what is left to do is to collect reports. The beauty of this approach is that you don't have to open Jenkins/Bamboo/Team City/Whatever UI to modify the build job each time. Your whole build configuration is a code now and you make changes inside the project repository, that means all changes are tracked in version control system and can be reviewed.

Even more, if multiple projects share the same structure, you can move build configuration into a common makefile and make it available on CI box as part of Ruby gem, for example. There are certain tradeoffs if you do it this way. The latest version of common makefile has to be backwards compatible with all the projects. I have successfully applied this approach building 21 libraries with one common makefile, so it's something that can be done.

## Summary

I'll admit that this not the best use of makefiles. If you ever had to build complex C or C++ projects, you should be familiar with much more complex recipes and use of extensive pattern matching and other techniques. However, makefile is a DSL after all and the beauty of any DSL is that you can apply it to your needs in a way which is convenient for you.

Makefiles sometimes feel like something from last century, and they technically are! Nothing stops you from exploring other alternatives if you want to get away from this non-obvious makefile-shell syntax mixup and functions that look more like macros.

Have a look at [Rake](http://en.wikipedia.org/wiki/Rake_%28software%29) then. Basically it's `make` for Ruby, but you can use it for any kind of projects. You get all the benefits of using Ruby as your DSL, which is way more flexible than makefiles. A minor tradeoff is that you need to have Ruby and Bundler installed, but Ruby is part of Mac OS X release, so that's not a big deal.

Yet another option is [Gradle](http://en.wikipedia.org/wiki/Gradle). The DSL for Gradle is [Groovy](http://en.wikipedia.org/wiki/Groovy_(programming_language)) a powerful and flexible language as well. With Gradle you'll need some basic Java setup.

If you want to take your iOS or Mac OS X build automation to the next level, just pick one of the many DSLs available and move all your configuration to the code. It does require certain efforts in the beginning, but pays off in the end.
