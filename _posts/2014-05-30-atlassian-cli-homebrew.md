---
layout: post
title: "Install Atlassian CLI with Homebrew"
description: "Brew Atlassian CLI"
category: atlassian
tags: [atlassian, cli, osx, mac, apple]
---
{% include JB/setup %}

This is a follow to [introduction of Atlassian CLI]({% post_url 2014-05-29-atlassian-cli %}).

In this post you will learn how to create custom [Homebrew](http://brew.sh/) formula, install Atlassian CLI via Homebrew tap and customize tools for you company environment.

If you don't care about all the details and steps involved, you can jump right to [Summary](#tldr) section.

# Brew

TODO: need to install brew and few words about brew

## Why Brew?
A perfectly valid question. Why would you go into all the trouble of creating formula, when you could just unzip, copy and update `PATH`, or even write a simple shell script to do that.

Well, Homebrew does all that and then much more. After initial installation upgrading the tools is as easy as `brew update && brew upgrade`. It also makes installation and upgrade process easier to other people in your organization. And finally, it's just cool.

## OK, Let's Brew!

- create formula with brew command
- set version, release and java_version
- homepage, url, sha1
- install
    + remove windows stuff
    + patch shell scripts
    + move and rename shell scripts
    + install to prefix (what's metafiles?)
- test - few words

## Customize

- why and how you customize
- nested class, why not using another file...
- patching

## Tap, Install and Upgrade

- how do you use custom tap
- how you install
- and then upgrade

# <a name="tldr"/> Summary
- full file listing
- bash snapshot for install and upgrade