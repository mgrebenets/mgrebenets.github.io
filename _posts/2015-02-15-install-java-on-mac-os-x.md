---
layout: post
title: "Install Java on Mac OS X"
description: "Install Java Development Kit on Mac OS X"
category: Mobile CI
tags: [java, mac, osx, jdk, ci]
---
{% include JB/setup %}

A short how-to for installing and configuring Java Development Kit on Mac OS X.

<!--more-->

Java is core technology used by CI servers like [Jenkins]({% post_url 2015-02-01-jenkins-ci-server-on-osx %}), [Bamboo]({% post_url 2015-02-01-bamboo-ci-server-on-osx %}) and others. It is also used by [Atlassian CLI Client]({% post_url 2014-05-29-atlassian-cli %}). In fact installing and configuring JDK is such a common task that it deserves its own post.

# Java Version

Select JDK version which you need: [1.6](http://support.apple.com/kb/DL1572), [1.7](http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html) or [1.8](http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html). Better install all of them, you never know what you might need one day.

I find that for most applications I'm using 1.7, rarely 1.6 for some outdated and unsupported application. These days more and more applications are updated to work with 1.8 without issues.

# Java Home

Lots of applications, if not all, expect `JAVA_HOME` environment variable to be set. This tells them where the Java Virtual Machine (JVM) is located. I would recommend to update your `~/.bash_profile` and add something like this:

```bash
# Default Java Home.
[[ -z "$JAVA_VERSION" ]] && JAVA_VERSION=1.7
[[ -s /usr/libexec/java_home ]] && export JAVA_HOME=$(/usr/libexec/java_home -v $JAVA_VERSION)
```

This is an over-devensive version. It can safely run on OS other than Mac, but will not set `JAVA_HOME` in that case. It uses OS X specific `java_home` executable found in `/usr/libexec`. A very convenient utility to get JVM path for Java installation. Try `-V` to get a list of all JVMs installed.

```bash
/usr/libexec/java_home -V

# Sample output.
Matching Java Virtual Machines (4):
    1.8.0_25, x86_64:	"Java SE 8"	/Library/Java/JavaVirtualMachines/jdk1.8.0_25.jdk/Contents/Home
    1.7.0_72, x86_64:	"Java SE 7"	/Library/Java/JavaVirtualMachines/jdk1.7.0_72.jdk/Contents/Home
    1.6.0_65-b14-466.1, x86_64:	"Java SE 6"	/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home
    1.6.0_65-b14-466.1, i386:	"Java SE 6"	/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home

/Library/Java/JavaVirtualMachines/jdk1.8.0_25.jdk/Contents/Home
```

If you are using shell other than bash, include the same in your shell's version of `.bash_profile` or source it directly with `source .bash_profile`.
