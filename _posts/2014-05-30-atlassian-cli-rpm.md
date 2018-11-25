---
layout: post
title: "Install Atlassian CLI with RPM"
description: "Atlassian CLI RPM"
category: Atlassian
tags: [atlassian, cli, rpm, rhel, linux, aws]
---
{% include JB/setup %}

Another follow up to [introduction to Atlassian CLI]({% post_url 2014-05-29-atlassian-cli %}).

This post describes how to create an RPM package for Atlassian CLI to install it on [RMP-based Linux distributions](http://en.wikipedia.org/wiki/Category:RPM-based_Linux_distributions).

<!--more-->

Jump directly to [Summary](#tldr) if just want to grab the end result.

# Why Bother?

Same question as one would as for using [Homebrew on OS X]({% post_url 2014-05-30-atlassian-cli-homebrew%}). And same answer again - Automation.

Let's assume you already use Atlassian CLI Client for number of build tasks, like automatically updating JIRA tickets, Confluence pages, Stash pull requests, etc.

Let's further assume that your company has a proper CI environment, for example RPM-based Linux instances running in [AWS cloud](http://aws.amazon.com/). Each instance runs one build agent (slave, node or whatever you call it).

One of the reasons going into the cloud is scalability, you can go from one to few dozens of identically cloned agents with literally one click of a mouse.

Normal practice is to refresh those instances repeatedly, e.g. on a 2 weeks schedule, and _refresh_ in this context means recreating them from scratch. This is when an updated OS image is used for new instances, you can put new updates and packages into this new image to make it available to all build tasks by default without additional installation. For example, you could not just have [RVM](https://rvm.io/) installed, but also install few most used rubies for 2.0 and 2.1.

Preparing new image has a funny name, that is _Baking_ (remember _Brewing_?). What's amusing, the whole baking process is done by the very same CI setup it will be applied to. Keeping an eye on the whole infrastructure is actually quite a challenge and you would most likely have DevOps or DevSupport team to look after it.

In any case, to conclude this long passage, one of the reasons to have an RPM package for Atlassian CLI is to be able to bake it into your build agent.

# Create RPM Spec

Creating and RPM package is very similar to creating Homebrew tap, only in this case instead of Formula you need to create [RPM Spec](http://www.rpm.org/max-rpm/ch-rpm-inside.html).

{% gist 37158fe1783032cec7b1829a76dbc240 %}

Let's put first lines into the spec

{% gist 504997f5009f938327926df111f912e1 %}

First three lines are a result of googling as well ans trial and error process. I'm not an experienced RPM package builder, so there are things that I will have to leave unexplained.

Next lines are self descriptive. The `%{varname}` syntax is the way you can pass variables into RPM spec when using it with `rpmbuild`, for example

{% gist 8e5d06ec235d0ca5e1a60e693eef5767 %}

Some of the header attributes worth mentioning separately. For starters the _Source:_ attribute should point to your source tarball. But it doesn't have to be a local file, it can be a URL just like Homebrew's `url` attribute. You can then download and unzip it with one call to [`%setup` macro](http://www.rpm.org/max-rpm-snapshot/s1-rpm-inside-macros.html).

{% gist 873d31a55578c410a552e8fa3985c012 %}

I myself just found out about it recently and didn't try it yet. So in this article I'll do the job of setup macro with shell commands, but this is definitely where improvements should be made.

Then there's `_tmppath` variable. You will notice later that it's not passed to RPM script directly anywhere, instead, it's picked up from a special `.rpmmacros` file. You'll see how it's used later on.

## Install

Now it's time to define install command. It's again very similar to Homebrew's install. So I will give here brief description of the steps with the code and for more details you can always get back to [Homebrew post]({% post_url 2014-05-30-atlassian-cli-homebrew%}).

### Prepare and Setup

Since we don't use `%setup` macro, we have to some of the work here.
Remove old build directory, unzip the source tarball and cleanup Windows stuff right away.

{% gist 21692bd8238e74939aec81317c519a63 %}

### Patch and Move

Next is patching time and once patching is over move the files to a proper location (`bin` folder). I've explained why this is required in the post related to Homebrew formula, so have a peek there.

When patching we'll update all the `.sh` scripts and put new relative path to JAR files, we'll also insert proper `JAVA_HOME` export in each.

{% gist 13111f661d07725e30a433d894f548ef %}

Then it's time to customize all the Atlassian product URLs as well as put a proper service account username and password if you plan to save keystrokes in the future.

{% gist 8c80740d01d926132493ed9cef49ba1b %}

Finally rename ambiguous `all.sh` to `atlassian-all.sh` and move all `.sh` files to `bin` folder. I personally prefer to drop `.sh` part from the filename in the process.

{% gist 418da258254c406d9476b19cde49bdf0 %}

## Files and Symlinks

Now it's time to tell RPM spec which files are part of final installation.

{% gist c3701f13053b57eb77e7ce137c995186 %}

In post-install stage we want to symlink all the shell scripts and JAR files to a corresponding directory in `/usr/local`. The reason behind that is because `/usr/local/bin` is already on our `PATH` (if not, then add it as described in Homebrew post).

We also add info for post-uninstall process so it can remove all these symlinks for us.

{% gist 008732370134446dcaa6f8568644b8ff %}

### Clean

No comments on this one.

{% gist 14d974a7204f20f8318ce178563b0f62 %}

## Changelog

Add some change log and you are done with the spec.

{% gist ac34d4f9ff5308434465976383168d72 %}

# Build RPM

It's time to build an RPM based on the spec we have just came up with.
In this example I'll use Makefile which helps to present material in more simple and organized way than just shell scripts.

{% gist 445d211053a1c2aa49db4dda336cb3af %}

Define all the basic configuration, like version, release, Java version, etc.
Note the use of `noarch` here for architecture. We are working with collection of JARs and shell scripts, there are no sources files that need any compilation at all, so we specify that we are not building for any particular architecture.

{% gist c074982634b4c1b9e29b68dca39b2bc3 %}

Now define step by step what needs to be done using Makefile targets (aka recepies).

Download the package if it doesn't exist yet.

{% gist 4566e82deb6299e157b27202d2ca9dcb %}

Then unzip. This place partially explains why I avoided `%setup` macro. Setup macro assumes source is a tarball and uses `tar` utility to unpack it. But with Atlassian CLI the source is just a `.zip` file, so setup macro generates commands that don't work.

{% gist 50de3c1a8fff91b520ae037ec3d3a5b1 %}

Once unzipped, we also link symbolically versioned folder to `${PACKAGE}` file. This makes it easier to write next steps.

Now pack unzipped file into a tarball. This is all due to specifics of `rpmbuild`, it want's tarball and we have to comply. Put the tarball into distributive directory.

{% gist bf611dcc0a72d697ed3b32c3124542cb %}

Finally we can build RPM.

Still we end up doing some additional work here. `rpmbuild` expects a certain directory structure in it's root build folder. Once again, we're pretty much doing the `%setup` job here.

- We will build an RPM in `~/rpmbuild` directory, so we create one with number of required subdirectories (all those names in caps and tmp).
- Then move tarball to `SOURCES` directory
- Copy our RPM spec to `SPECS`
- Then add `%_topdir` and `%_tmppath` to a special `~/.rpmmacros` file. `rpmbuild` will scan `~/.rpmmacros` and pass all picked up values to RPM spec when building it.
- Finally call rpmbuild passing version, release and all the other vars.
    - The [`-bb` option](http://www.rpm.org/max-rpm-snapshot/ch-rpm-b-command.html) tells `rpmbuild` which steps to execute.
- Once `rpmbuild` is done, copy RPM package to distributive directory.

{% gist 1bb863edad11b9f4c3edd1c9c316f0e5 %}

So, are you ready to try it?

{% gist 3a5479c438e97fbf76c966643698349b %}

I ran it on Fedora 20 as well on a custom Linux distribution running in AWS cloud. Since the package does not depend on architecture, you could in theory build it on OS X machine, but it's not what I would recommend, getting proper `rpmbuild` port configured is not something you enjoy very much.

# Install RPM

To test your installation, use these commands

{% gist 487921b8066cb6cd5cad0feb1d4e07cb %}

Now you can hand RPM package over to your Dev Support guys, they'll put it into local repo and make RPM install a part of bake or post-bake process.

Yet nothing stops you from creating a CI plan (job) for the Atlassian CLI RPM package itself. You can run `make rpm` and test rpm install on the very same build agent this package is targeted for, thus creating yet another "CI Loop", which is good.

<a name="tldr"/>

# Summary

- Create [RPM spec](b40ad2077172db9cdb2d)
- Run `make rpm -f RPMMakefile` using this [RPMMakefile](b1b9d52e135561362666)
