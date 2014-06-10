---
layout: post
title: "Atlassian CLI Client"
description: "Introduction to Atlassian CLI Client"
category: Atlassian
tags: [atlassian, cli, homebrew, osx]
---
{% include JB/setup %}

If you happen to use Atlassian products like JIRA, Bamboo, Stash, Confluence, etc., you may be surprised to know that all these products are backed by a handy command line interface, namely [Atlassian Command Line Interface](https://bobswift.atlassian.net/wiki/display/ACLI/Atlassian+Command+Line+Interface).

<!--more-->

Imagine opening, modifying and closing JIRA issues from command line. What about starting Bamboo build plans, opening and closing Stash pull requests, updating Wiki pages?

"Why would I do that?" you would ask. Indeed, there's not much benefit to automate these things for you as a user, unless you are some bash addict. However, stop for a moment and think "Automation" and you'll see how many things a basic shell script can do. All you need is Java and shell interpreter, which are present on any decent build box.

Atlassian CLI Client is available on [Atlassian Marketplace](https://marketplace.atlassian.com/plugins/org.swift.atlassian.cli). It is not developed by Atlassian though, which is very important to know if you plan to use it.

This is where the confusion between Atlassian CLI _Plugin_ and Atlassian CLI _Client_ needs to be cleared up.

_Plugin_ is **not free** and should be purchased for Atlassian products, e.g. there's CLI plugin for JIRA, Bamboo, Stash.

_Client_ can be freely downloaded and installed. You can find a few outdated Homebrew formulas on GitHub that automate client installation. So you might easily assume that it's free, but it's not.

> You must purchase a license for any of the Atlassian CLI Plugins in order to use the Client.

The purpose of this post is introduce you to Atlassian CLI Plugin if you didn't know about it yet. The plugin is [very](https://bobswift.atlassian.net/wiki/display/ACLI/Atlassian+CLI+General+Documentation) [well](https://bobswift.atlassian.net/wiki/display/ACLI/Installation+and+Use) [documented](https://bobswift.atlassian.net/wiki/display/ACLI/How+to) and comes with tons of [examples](https://bobswift.atlassian.net/wiki/display/ACLI/Examples).

The thing that I didn't like about it is installation process. It's a straightforward "download, move, update `PATH`" process. There's nothing bad in the process itself, but when you need to roll out CLI tools on a dozen of build agents, you start looking for a better way.

So I follow up this post with 2 more

- [Install Atlassian CLI with Homebrew]({% post_url 2014-05-30-atlassian-cli-homebrew %}) (OS X)
- [Install Atlassian CLI from RPM]({% post_url 2014-05-30-atlassian-cli-rpm %}) (Linux)