---
layout: post
title: "Install Atlassian CLI with Homebrew"
description: "Brew Atlassian CLI"
category: Atlassian
tags: [atlassian, cli, osx, mac, apple]
---
{% include JB/setup %}

This is a follow up to [introduction to Atlassian CLI]({% post_url 2014-05-29-atlassian-cli %}).

In this post you will learn how to create custom [Homebrew](http://brew.sh/) formula, install Atlassian CLI via Homebrew tap and customize tools for you company environment.

<!--more-->

If you don't care about all the details and steps involved, you can jump right to [Summary](#tldr) section.

# Brew

[Homebrew](http://brew.sh/) (aka "brew") is a missing package manager for OS X.
After you install it, you need to update your `PATH`. By default `/usr/local/bin` is not in the system path, so modify your `~/.bash_profile` before you continue.

{% gist a17bef39eee3fe70cdbd626989144569 %}

## Why Brew?

A perfectly valid question. Why would you go into all the trouble of creating formula, when you could just unzip, copy and update `PATH`, or even write a simple shell script to do that.

Well, Homebrew does all that and then much more. After initial installation upgrading the tools is as easy as `brew update && brew upgrade`. It also makes installation and upgrade process easier to other people in your organization. And finally, it's just cool.

## OK, Let's Brew!

### Create Formula

You could use `brew create <link>` command, but that will create formula in `/usr/local/Library/Formula`. Instead let's create it manually.

Let's say our company is called i4nApps (I know, it's a weird name...), so create new Ruby file

{% gist 4cb315bccf887a3b825d4ee0cfce2b25 %}

With contents like this

{% gist 842f6d6d003886729e74ed787be353a1 %}

These are the basics of brewing.

- Your custom formula class needs to subclass `Formula` class.
- `version` in our case is "3.9.0", that's the latest Atlassian CLI Client version at the moment of writing this post.
- `homepage` points to [Atlassian Marketplace page](https://marketplace.atlassian.com/plugins/org.swift.atlassian.cli).
- `url` is used to download source code. Note a bit of tweaking at the end of the link `#{version.to_s.delete('.')}`, that's to remove dots.
- `sha1` obviously is SHA-1 calculated for file downloaded from `url`.

{% gist 9038a9b8379caa3877f7126e5e9fec2e %}

- `install` method is where you do all the installation magic once the source is downloaded and unzipped.
- `test` is used to test formula after installation. Normally you just execute main program installed by the formula, in our case it can be `jira`.

Now let's take advantage of the fact that Homebrew formula is just a Ruby class and add few more custom lines to use later.

{% gist 1e55d8777bfc4cd0a24532520f57f61e %}

- `release` will be used for managing multiple releases for same version
- `java_version` will come handy for setting `JAVA_HOME` environment variable. Default is "1.6" but you can user `JAVA_VERSION` environment variable to override default settings.

> Atlassian CLI Client [Compatibility page](https://bobswift.atlassian.net/wiki/display/ACLI/Compatibility+-+3.9) claims that "Client requires **Java 1.6** (recommended) or above." I have had problems using it with Java 1.7, so in this guide we'll stick with 1.6.

### `install`

Once execution enters `install` method, the source is already downloaded and unzipped. Things that you do in `install` method occur in temporary directory created by Homebrew.

This is the place to run things like `./configure` and `make`. However in our case we have no source code to compile. Atlassian CLI is basically a collection of JAR files with shell wrappers for them.

Our job is to cleanup first, then patch and rename some scripts and finally move the whole bunch to `/usr/local`. `/usr/local` is also called _prefix_, this is the location where Homebrew installs all packages, additionally there's a special `prefix` variable available in the formula.

#### Cleanup

So let's cleanup. Since we are installing on OS X, we don't need all the Windows stuff.

{% gist fcd401880dad67677bce81e1ff4dccd9 %}

As an improvement, this could be a good place to remove examples.

#### Patch and Move

Now it's the time to mention one of the things done _wrong_ in Atlassian CLI tools package. There's a reason for having all those folders like `lib`, `libexec`, `etc` and so on. In Homebrew world each of those folders serves a special purpose. Yet the most important folder of all is missing, that is `bin`!

Remember that part where you added `/usr/local/bin` to your `PATH`? When Homebrew installs a package it copies things from temp folder to prefix (`/usr/local`), `bin` is copied too. Every executable in the `bin` becomes available system-wide because of the way you updated `PATH`.

In case of Atlassian CLI, all the shell scripts are sitting in the root folder, `bin` is not there at all. This needs to be fixed. We will do it in 2 steps

- Create `bin` folder and move scripts to it
- Patch the scripts

The order doesn't really matter.
Patching is required because each shell script is a wrapper around JAR file and contains relative path to that JAR. So if you move the shell script, you have to update the relative path as well.

{% gist f38b4000518713a9465b46604436f046 %}

Here we replace relative path to `lib` with `../lib`.
We also set `JAVA_HOME` here using `java_home` OS X utility and `java_version` method. This is to be sure Java version is as we expect it.

{% gist 309c3c9dfad8f17eef6e4a7535c0e213 %}

We just moved all the `.sh` scripts to `bin` folder. I also prefer to drop the `.sh` part. Finally `all` feels too ambiguous, so rename it to `atlassian-all`.

#### Install to Prefix

We can finally install everything to prefix (`/usr/local`), that's where `prefix` variable is used

{% gist 0b2c65852c749636679e72beab6be1a0 %}

## Customize

This part is optional. Unless you customize the scripts you will have to use `--server`, `--user` and `--password` switches each time you call commands, this is to provide server, username and password.

Of course this can be solved with aliases, but then you'd have to configure aliases on each build box. Anyway, the developers of the CLI package offer you another solution. As I said, this part is optional, if you don't need customization you can skip to [next section](#tap-install).

The `atlassian.sh` (which we renamed to `atlassian` and moved to `bin`) is there for customization. Have a look inside that file

{% gist 5c62c231b016b1a6b3950f74c7ca9694 %}

This is where you can customize your Atlassian products username and password, as well as additional JVM settings. That's usual practice for organizations, you have a special user account (service account) than can access the whole range of products with single username and password.

And there's another block of code like this, which is used to customize Atlassian products server urls.

{% gist e7e008ef0b2fd8f5a7d93b690c41e763 %}

You will need to replace all the `https://***.example.com` with your company urls. If you have multiple instances of same product in your organization, you can add another `elif` block for that. For example you are in the middle of migration from Confluence server `https://confluence.example.com` to a new instance `https://confluence.ni.example.com`, for a while you want to be able to use both, so add another block like this

{% gist 075a92a78d677b2034bef6c4b2e74ae4 %}

In this example there won't be multiple instances for same product, but it would be possible to customize scripts to handle that case as well.

So let's write some Ruby again. For the company called i4nApps we will create a nested class `I4nAppsEnv` that will contain all the company specific environment settings.

{% gist 7b998ddd43cea92886540b134503416c %}

`username` and `password` methods pick up values from `ATLAS_USERNAME` and `ATLAS_PASSWORD` environment variables. Set those when running `brew install` or `brew upgrade`.

Next the `server` method returns server url for each product type.

Finally `patch` method patches the shell script the way we want it.

- Replace default username and password with values provided via environment variables
- Replace all the server urls with your company urls

You have to add one more line to `install` method in the formula

{% gist 29433d8bbf5565ba81ef3c3363db12ab %}

Make sure to put this line **before** `atlassian.sh` is moved and renamed.

> The nested class is used because Homebrew only expects one formula file. If you have other files used as an external dependencies, Homebrew will not fetch them from repository when running `tap` command.

### Push to SCM

We are done with the formula. It's time now to push it to a repository. Whatever is you favorite SCM - use it. In this example we will use Git repository hosted with Stash. For example

```text
ssh://git@stash.i4napps.com.au/mobile/i4napps-atlassian-cli.git
```

## <a name="tap-install"/>Tap, Install and Upgrade

### Tap

One of the ways to install Homebrew packages from custom repositories is to use [_Taps_](https://github.com/Homebrew/homebrew/wiki/brew-tap).

There's a number of rules to follow when creating your taps. That mostly matters if you plan to share this formula with the rest of the world. For internal use in your organization you can neglect some of these rules.

But there's a trade off as well. Since we didn't name the tap repository properly, we won't be able to use tap command like `brew tap username/repository`. Instead we will do same actions as `tap` does only with few lines of shell script.

`brew tap` clones the repository from GitHub and puts it into the taps directory. This is how you can do it directly

{% gist b3e342fabd3b135ebbc8054de89d036d %}

### Install

Now you can install, this part is simple

{% gist 0dcccc4be0031ea03636583fe6b298b8 %}

### Upgrade

To upgrade you need to update brew repositories, including the taps, then upgrade the specific package.

{% gist 85cef3758ee1469ecd739800516a1f09 %}

# <a name="tldr"/> Summary

- Create formula Ruby file and put it into a repository

[i4napps-atlassian-cli.rb](https://gist.github.com/mgrebenets/39fe319a2b05d182cbfa)

- Create a Homebrew tap, install and upgrade

{% gist 14070ba19be8b6af697c5226d6436538 %}
