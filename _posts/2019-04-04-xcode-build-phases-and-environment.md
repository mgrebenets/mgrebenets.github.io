---
layout: post
title: "Xcode Build Phases and Environment"
description: "Xcode Build Phases and Environment"
category: Xcode
tags: [xcode, apple, ci, cli, scripts]
---
{% include JB/setup %}

How to teach Xcode to respect the Environment.

<!--more-->

If you've ever done iOS development you've surely used [Xcode Build Phases](https://help.apple.com/xcode/mac/10.2/#/dev50bab713d). One of the tasks that a build phase can perform is [running a shell script](https://help.apple.com/xcode/mac/10.2/#/devc8c930575), and that's where you can face one peculiar problem...

# The Problem

The problem is that shell scripts ran in Xcode build phases **do not** source the user shell profile.

Try to put the following in your shell profiles`~/.profile`:

```shell
# In ~/.profile
echo "Loading ~/.profile"

# In ~/.bash_profile
echo "Loading ~/.bash_profile"

# In ~/.bashrc
echo "Loading ~/.bashrc"
```

Then run the build phase by building Xcode project.

![Build Phase]({{ site.url }}/assets/images/build-phases-env/build-phase.png)

None of the messages from shell profiles will show up.

The reason is that a shell ran from Xcode build phase is [non-interactive shell](https://www.vanimpe.eu/2014/01/18/different-shell-types-interactive-non-interactive-login/).

It is not actually not a bug, but an expected behavior, which may confuse you a bit though.

## The Example

As an example, let's say you've got a Ruby script which you want to run as part of Xcode build phase.

The script happens to be using some 2.5.x Ruby language features, which are not available in 2.3.x.

You are also using [RVM](http://rvm.io/) to install and use version 2.5.x.

Now add `ruby --version` to the build phase, build the project and check the output.
On Mojave OS X the output will be `2.3.7`, which is the system Ruby version.

None of the RVM environment usually defined in shell profile got loaded into script.

## Login Shell

One solution to this problem is to use [login shell](https://www.vanimpe.eu/2014/01/18/different-shell-types-interactive-non-interactive-login/).

It's as simple as adding `-l` to the "Shell" parameter of the build phase, for example `/bin/sh -l`.
However, it will **not** work for [Bourne shell (sh)](https://en.wikipedia.org/wiki/Bourne_shell).

But the it **will** work for the [Bourne-again shell (bash)](https://en.wikipedia.org/wiki/Bash_(Unix_shell)), so you could change "Shell" parameter to say `/bin/bash -l`.

You will see this in the logs now:

> Loading ~/.bash_profile

That works, but is not ideal. If you have a lot of developers on the team, they may have all kinds of things happening in their `~/.bash_profile` which you don't necessarily want to run in Xcode build phase. All you want is only load RVM environment, nothing else.

Other developers may as well use [zsh](https://en.wikipedia.org/wiki/Z_shell) or some other kind of shell.

## Build Phase Scripts

Another way to tackle this problem is to source just the things that matter as part of each build phase script.

For example, to use RVM for loading Ruby version in non-interactive shell, you could use this code:

```shell
export PATH="$HOME/.rvm/bin:$PATH" # Add RVM to PATH for scripting.

# Read Ruby version for the project from .ruby-version.
RUBY_VERSION="$(cat .ruby-version)"

# Source the Ruby environment for selected Ruby version.
source "$(rvm "${RUBY_VERSION}" do rvm env --path | tail -n1)"
```

Here we first add `rvm` command to the `PATH`.
Then we read Ruby version used by the project from `.ruby-version` file, which is one of the common setups.
Finally we get a shell script containing all the environment variables using `rvm "${RUBY_VERSION}" do rvm env --path` and source (load) that script into current shell session.

Now you can put this code to a [dotenv](https://github.com/bkeepers/dotenv) file called `.env.ruby`, for example.
Each build phase shell script that requires Ruby can now add `source .env.ruby` line.

![Load Ruby Environment]({{ site.url }}/assets/images/build-phases-env/source-env.png)

While this approach may look like it requires more work, it is still a better one for a couple of reasons:

- You only load the things you need to run your script, not all the things from user's shell profile
- The Ruby version is selected based on the project's `.ruby-version` file, while with login shell approach the default Ruby version set for RVM globally is loaded and you'd have to run extra code to switch to correct version

# Tips

A few tips to using shell script build phases.

## Script Errors

Add `-e` flag for build phase to fail if shell script returns error code other that `0`, e.g. `/bin/sh -e`.

## Managing Build Phase Scripts

Use the following convention to manage you build phase scripts:

> There must be one shell script per build phase.

For example, put all your build phase scripts in a directory named `build-phases`, e.g. `build-phases/codecheck.sh`, `build-phases/codegen.sh`, etc.

In Xcode build phase UI instead of having an inline script, you have this now:

![Build Phase Script]({{ site.url }}/assets/images/build-phases-env/build-phase-script.png)

You can even move the Ruby environment loading line inside the build phase script to keep it down to a one-liner.

It's a much better approach for a number of reasons:

- If you modify the build phase script, it's much easier to review it in pull request as a change of `.sh` file, compared to when you have to review it as part of `pbxproj` UTF-8 ASCII plist file changes with all the newline and other escape sequences added into the mix.
- You can reuse build phase scripts outside of Xcode, e.g. if you try to use alternative build system like [Buck](https://buckbuild.com).
