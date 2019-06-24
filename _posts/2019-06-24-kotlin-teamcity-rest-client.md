---
layout: post
title: "TeamCity Kotlin REST Client"
description: "Using TeamCity Kotlin REST Client"
category: Mobile CI
tags: [kotlin, ci, teamcity, rest, gradle]
---
{% include JB/setup %}

Whichever CI server you use for development, being able to access it programmatically via REST API is an essential capability for implementing all kinds of automation. In this article you will learn how to utilize [TeamCity](https://www.jetbrains.com/teamcity/) REST API using [TeamCity Kotlin REST Client](https://github.com/JetBrains/teamcity-rest-client).

<!--more-->

Let's start by setting up some goals.

> I want to be able to access my TeamCity server using Kotlin programming language.

The goal is set and to help me with the task JetBrains provides a [REST client](https://github.com/JetBrains/teamcity-rest-client) which I've mentioned earlier. So all I have to do is write a simple Kotlin script that uses REST client and implement whichever automation I want, right? Well, except that I'm not a Java or Android developer and building Kotlin source code is totally new to me, so this article will cover some basics.

## ⚙️ Setup

I'm working on a Mac OS X machine, so I'll start by getting [Gradle Build Tool](https://gradle.org/) installed.

{% gist afc3423f7ac576c0db4a4734910eab73 %}

Next, I'll create a new directory for my project as well as the main Kotlin file and a Gradle wrapper.

{% gist 3d886e057f6d44e42cc87f7b4005eaf9 %}

From now on I should be running all Gradle commands using the wrapper, e.g. `./gradlew build`. Wrapper will be saved in `gradle/wrapper` folder. This folder can be committed to source control which removes the dependency on global Gradle installation and makes the project self-contained.

I want to use Kotlin to write build scripts, so I create `build.gradle.kts` file in the project root with the following contents:

{% gist 4048ef3bf2748c9cd884d1a807444424 %}

This is to make sure I'm using exact version of Gradle and it doesn't autoupdate.

## 🔨 Implement

This may sound unusual, but in this case I choose to write the Kotlin code first and then make it compile and run. Based on the example on REST client project page, I came up with the following:

{% gist 974b030ecde04a1a78305d85c1f14bf3 %}

In a nutshell this code connects to TeamCity using username and password provided as input arguments, then fetches latest build information for a specified build configuration and prints it out to console. Check inline comments for more details.

## 👷‍♂️ Build

After a lot of trial an error I came up with the the following build file:

{% gist a0669ddc663c66a9263d0d88efebeb9f %}

Check the inline comments for detailed information.
This build script builds Kotlin application targeted for running on top of [JVM](https://en.wikipedia.org/wiki/Java_virtual_machine). The application depends on TeamCity REST client.

Note that you have to install Java version 1.8 to build and run the application.

It's time to build it:

{% gist 1eb88bf6694b5401b073e72ebfcf4ced %}

## 🏃‍♀️ Run

I can now run the Kotlin application:

{% gist c6c8d2495b1bfd2905e2c87d1657358f %}

After customizing input arguments I am able to see something like this in the logs:

{% gist a12160cf3d21bd9936e9fb5c066d1b52 %}

That's just the beginning!
I can now use nice modern programming language to automate various CI/CD tasks on TeamCity.

For a full example project see [this repository](https://github.com/mgrebenets/teamcity-rest-client-example).
