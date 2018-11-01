---
layout: post
title: "Jenkins CI Server on Mac OS X"
description: "Setup and Configure Jenkins CI Server on Mac OS X"
category: Mobile CI
tags: [mobile, ci, jenkins, server, osx]
---
{% include JB/setup %}

A guide for setting up a Jenkins CI server on Mac OS X machine.

<!--more-->

So you want to have Continuous Integration for Mobile in your company and your final choice of CI server is Jenkins. If your company is big and you are lucky enough the Dev Support or Dev Ops team will do all the heavy-lifting and install it for you. But if it's not the case you might've just landed on a page that has something to help you out.

# Install

> A kind of warning first, avoid installing Jenkins as Launch Daemon. For detailed reasoning checkout out [this article]({% post_url 2015-02-01-mobile-ci-daemon-vs-agent %}).

[Jenkins Wiki](https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins) offers a list of options for Jenkins installation but doesn't mention Mac OS X. It mentions [Docker](https://www.docker.com/) though and I've heard nothing but good things about Docker. In this article I will stick with [Homebrew](http://brew.sh/).

You will need JDK to be [installed and configured on your Mac]({% post_url 2015-02-15-install-java-on-mac-os-x %}) before proceeding.

To install run a simple shell command.

{% gist d7fb72b9e326f20d65e3cefdfec73d3a %}

Jenkins will be installed to `usr/local` and Homebrew will actually tell you right away how to turn it into a Launch Agent.

{% gist 4639671209d603804d295f9752e35122 %}

This recommends you to symlink Jenkins launch agent plist file to `~/Library/LaunchAgents` but I would advise against it. As you will see next you will need to modify that file. That means if you ever upgrade Jenkins via Homebrew all your changes in plist will be lost. My recommendation is to copy it instead of making a symbolic link.

Even more, once installed via Homebrew I then delegate Jenkins upgrades to Jenkins itself. For this reason I pin Homebrew formula to prevent Homebrew from upgrading Jenkins files.

{% gist 3b7d2ae7641b6db07a7fe0aae64eeed4 %}

Now you also have manual control over Jenkins installation and can start/stop it from command line.

{% gist 170152434d3789ab06c993c63c43233a %}

# Configure

To understand why you need to change plist try to run Jenkins server. Give it a go, create a couple of build projects that do some basics like checking out git repository and running simple build command. Very soon you should get an error message saying that Jenkins has ran out of memory. This seems to be a common issue with JVM and Mac OS X, [Bamboo installations run into same problems]({% post_url 2015-02-01-bamboo-ci-server-on-osx%}). I'm not quite sure why default configuration doesn't account for this, probably this is Mac specific and other operating systems are OK. Anyway, you need to modify default plist file for Launch Agent. Here's what you need and might want to change.

## JVM Virtual Memory and Garbage Collection

- Tell JVM to use a 64-bit data model if available (`-d64`).
- Set minimum and maximum heap size with `-Xms` and `Xmx` flags. 512 Mb works for me most of the time.
- Configure garbage collector, class unloading and permanent space.

{% gist 6a4b18f3452e7ab17d4a05b960fd4fcc %}

## HTTP Proxy

By far the largest source of issues and frustration, company proxy. Specify it using `-D` option.

{% gist 24bdf3afb723b8950e8ca5f98a045231 %}

## Port and Prefix

Run Jenkins on a custom port with custom prefix in url. This example uses default `8080` port and `/jenkins` prefix, so you can access your Jenkins dashboard like `http://yourhostname:8080/jenkins` or ever `http://youthostname/jenkins`. These arguments need to be passed to `jenkins.war` which was installed by Homebrew to `/usr/local/opt/jenkins/libexec`.

{% gist d50d1e3b2ba6118bfcdf8d5cca7fcee6 %}

## Run at Load

Enable Run at Load option to start server automatically if machine reboots.

{% gist 9973d3a4f53397dbfd9f844cfdb7ec37 %}

## Environment Variables

If any of the commands in this plist need environment variables this is how you can define them.

{% gist a00c74ed35d5d4bc62b50f236ac6b354 %}

## Standard Output and Error

It is up to you to redirect stdout and stderr. While sounds like a good idea for logging I would advise against redirecting stderr into a file. I once had to deal with 90 Gb log file created by Bamboo remote agent over a few months period.

{% gist c49ccb8896f0d031f4dfd6177a6fc894 %}

Note that Jenkins put its files in `.jenkins` folder in your user's home path. You also have to specify full paths when dealing with launch agent plists. Create `log` folder if it's not there yet.

## Other

By default Jenkins enables security protocol for email. I have also faced an issue with [Bitbucket Plugin](https://wiki.jenkins-ci.org/display/JENKINS/BitBucket+Plugin) and had to set `preferIPv4Stack` flag as a workaround. These are all flags for `java` command.

{% gist a9a28e5a289c2ea39fa5be2ff63258cc %}

## Full Config

Now put it all together.

{% gist 56f774c72cf1d067eb3c7a0eb2ac1669 %}

Now you have a reliable Jenkins server that runs 24/7 and performs stable CI tasks.

# Tips

To find out how exactly Jenkins was launched, grep active processes list.

{% gist 6c84f352247b8bb079f1bd11f9ab3cc4 %}

The output will tell you everything you need to know.

{% gist b3c46fbebc176a3ef612fd199e493d91 %}

# Other Ways

## Jenkins Runner

There are other ways to install and start Jenkins server, one of them is using [jenkins.sh](https://wiki.jenkins-ci.org/display/JENKINS/Jenkins+Runner) runner script. It is not bundled with Homebrew installation by default, you should download it manually as mentioned on the Jenkins Wiki page.

In this case all the configuration options are in `data/wrapper.conf` file, you can check [default file](https://github.com/mnadeem/JenkinsRunner/blob/master/conf/wrapper.conf) and easily figure out where to add your custom options.

The runner shell script itself can be launched as Launch Agent or Launch Daemon. Overall this is just a higher level of configuration.

## Legacy Runner

Another approach I've seen is to use custom runner script. I am actually working with one right now but I suspect this is a legacy version of `jenkins.sh`.

The main difference is that all configuration is stored in Mac OS X defaults and then read by the script like this.

{% gist 73b0fd09e0a03f6da110ed5c86a66961 %}

Defaults are stored as plist and are read as a dictionary. An example output looks like this

{% gist d1e73d2bd021c05606a05795ef9c4788 %}

Using `[sudo] defaults write` you can change Jenkins configuration.

Obviously this is less preferred way than using `wrapper.conf`. Using OS X defaults leads to configuration which is non-reusable on other operating systems and can't be easily put in SCM if needed.

# Summary

A short summary - install with Homebrew, configure as Launch Agent. To configure Jenkins for Mobile CI tasks you can read other articles in this blog.

The configuration is far from being final. You will have to install plugins, configure SSH keys for git repositories and perform multitude of other administrative tasks to bring your Jenkins CI box up to speed.
