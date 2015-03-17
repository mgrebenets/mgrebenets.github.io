---
layout: post
title: "HackerRank in Swift - Makefiles"
description: "HackerRank in Swift - Makefiles"
category: HackerRank
tags: [hackerrank, swift, makefile, xcode]
---
{% include JB/setup %}

A basic makefile to help you with testing your [HackerRank](https://hackerrank.com) solutions locally.

<!--more-->

So you are into HackerRank and want to be able to run the code locally before submitting it. This is useful when you have one of the test cases failing and you want to debug it and find the problem.

In this article I'll show how you can run Haskell and Swift code locally via command line in a convenient way.

## Manual Mode

Before you automate any process, you need to understand what's there to automate in the first place. The usual approach is to run all the commands manually, so you can notice common patterns and find out certain edge-cases.

Let's look at first challenge, which is already solved [in this article]({% post_url 2015-03-15-hackerrank-in-swift---io %}). Let's agree that all test cases will be put in `tc` folder, then create `tc/solve-me-first-tc0.txt` with the following contents.

{% highlight bash %}
2
3

{% endhighlight %}

The `tc<N>` part of the file name stands for "test case N", the default test case provided as part of assignment has index `0`. So to run your code against test cases 0 and 1, you would run commands like these.

{% highlight bash %}
# Haskell
cat tc/solve-me-first-tc0.txt | runghc solve-me-first.hs
cat tc/solve-me-first-tc1.txt | runghc solve-me-first.hs

# Swift (use `xcrun swift` for OS X 10.9)
cat tc/solve-me-first-tc0.txt | swift solve-me-first.hs
cat tc/solve-me-first-tc1.txt | swift solve-me-first.hs
{% endhighlight %}

Clearly there's a pattern there, let's express it using bash syntax.

{% highlight bash %}
# Test cases directory
TC_DIR=tc
# Test case number
TC=0
# Base name for assignment
ASSIGNMENT=solve-me-first

# Run Haskell, test case 0

# Interpreter command
CMD=runghc
# File name extension
EXT=hs

cat ${TC_DIR}/${ASSIGNMENT}-tc${TC}.txt | ${CMD} ${ASSIGNMENT}.${EXT}

# Run Swift, test case 1

# Interpreter command
CMD=swift
# File name extension
EXT=swift

TC=1 cat ${TC_DIR}/${ASSIGNMENT}-tc${TC}.txt | ${CMD} ${ASSIGNMENT}.${EXT}
{% endhighlight %}

The script above is a valid bash script. With little work you can turn it into a script that takes file name as a argument and does all the magic of figuring out the extension and interpreter command under the hood, but there is a better way (in my humble opinion).

## Makefile

Yes, makefiles. I already [wrote about them]({% post_url 2015-02-08-mobile-ci---makefiles %}) in regards to automating mobile CI tasks. Check that write up if you need to refresh some make and makefile basics. So let's turn bash script from previous paragraph into a makefile.

{% highlight makefile %}
# Makefile

# Test cases directory
TC_DIR = tc
# Test case number
TC = 0

# Enable phony targets
.PHONY:

# Haskell
%.hs: .PHONY
	@cat $(TC_DIR)/$(patsubst %.hs,%-tc$(TC).txt,$@) | runghc $@

# Swift
%.swift: .PHONY
	@cat $(TC_DIR)/$(patsubst %.swift,%-tc$(TC).txt,$@) | swift $@

help:
	@echo "Run test case $(TC) for given source file."
	@echo "Use TC variable to specify test case number."
	@echo "Targets:"
	@echo "\t- .hs files for Haskell."
	@echo "\t- .swift files for Swift."
{% endhighlight %}

Nice feature or makefiles is pattern matching for targets based on the input. If you run this makefile specifying Haskell source file as input (that means file has `.hs` extension), it will match agains `%.hs` target and run commands for Haskell. `patsubst` is short for "path substitution" and turns input file name into a test case file name, here `$@` is the way to refer to target name.

Save it as, say, `Makefile` and give it a try.

{% highlight bash %}
# Run Haskell for default test case (0)
make -f Makefile solve-me-first.hs

# Run Swift for test case 1 (you have to create one)
make -f Makefile solve-me-first.hs TC=1
{% endhighlight %}

Works as expected. All you have to do now for each new assignment is to create source file and test case files and then run `make`. Annoying part is that you have to specify makefile name explicitly each time. Say, you have `hackerrank` directory with `Makefile` in it, and you organize assignments in their own directories.

{% highlight bash %}
hackerrank
├── Makefile
├── alg
│   ├── arr-n-srt
│   │   └── tc
│   ├── geometry
│   │   └── tc
│   └── warmup
│       └── tc
└── shell
{% endhighlight %}

So if your working directory is `warmup` and you want to run assignment code from there, you have to do somethign like this

{% highlight bash %}
make -f ../../Makefile solve-me-first.hs
{% endhighlight %}

The solution is to use an alias like this

{% highlight bash %}
# in your shell profile (.bash_profile, .zshrc, etc.)
HACKER_RANK_HOME="${HOME}/Projects/hackerrank"
alias hrrun="make -f ${HACKER_RANK_HOME}/Makefile"
{% endhighlight %}

Put this alias in your shell profile and now running assignments code from any folder is as easy as

{% highlight bash %}
hrrun solve-me-first.hs
hrrun solve-me-first.swift TC=1
{% endhighlight %}

## Optimize Makefile

Just like with shell scripts, there a bits of reusable code noticeable in the makefile. With use of functions and bit of refactoring, it can be turned into this.

{% highlight makefile %}
# Test cases directory
TC_DIR = tc
# Test case number
TC = 0

# Get the path to test case file
# usage: $(call tc-path,TC,EXT,FILE)
# where:
# TC - test case number
# EXT - file extension (e.g. hs, swift, rb, py, etc.)
# FILE - name of the source file (use $@ to pass it from recipe)
tc-path = $(TC_DIR)/$(patsubst %.$(2),%-tc$(1).txt,$(3))

# Run test case using interpreter
# usage: $(call run-tc,TC,EXT,FILE,CMD)
# where:
# TC - test case number
# EXT - file extension (e.g. hs, swift, rb, py, etc.)
# FILE - name of the source file (use $@ to pass it from recipe)
# CMD - interpreter command to run the source file (e.g. runghc, xcrun swift, etc.)
run-tc = cat $(call tc-path,$(1),$(2),$(3)) | $(4) $@

# Enable phony targets
.PHONY:

# Haskell
%.hs: .PHONY
	@$(call run-tc,$(TC),hs,$@,runghc)

# Swift
%.swift: .PHONY
	@$(call run-tc,$(TC),swift,$@,swift)

help:
	@echo "Run test case $(TC) for given source file."
	@echo "Use TC variable to specify test case number."
	@echo "Targets:"
	@echo "\t- .hs files for Haskell."
	@echo "\t- .swift files for Swift."
{% endhighlight %}

This can be improved and improved until the moment your internal perfectionist is happy, but let's stop here for now. More important feature of this makefile is how easy it is to add another _interpretable_ language support, for example Ruby.

{% highlight makefile %}
# Makefile

# ***

# Ruby
%.rb: .PHONY
	@$(call run-tc,$(TC),rb,$@,ruby)
{% endhighlight %}

Use slightly modified Ruby solution for [Solve me first](https://www.hackerrank.com/challenges/solve-me-first) from HackerRank and try it out.

{% highlight ruby %}
# solve-me-first.rb
a = gets.to_i
b = gets.to_i
print(a + b)
{% endhighlight %}

{% highlight bash %}
hrrun solve-me-first.rb
{% endhighlight %}

Works like a charm. You can add Python, Go, JavaScript and any other _interpretable_ language in this way. I keep putting stress on _interpretable_ because languages like C or C++ would require to compile and link the code before you could run it, but that's a story for another post...
