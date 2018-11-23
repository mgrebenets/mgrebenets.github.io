---
layout: post
title: "Jenkins Job DSL - Properties"
description: "Jenkins Job DSL - Properties"
category: Mobile CI
tags: [jenkins, ci, mobile, dsl, groovy]
---
{% include JB/setup %}

Learn how to work with global properties in DSL Groovy script, and how to handle missing properties.

<!--more-->

If you are not familiar with Jenkins Job DSL, [this post may be a good starting point]({% post_url 2015-02-08-bitbucket-branches--job-dsl %});

# Properties

When you are working with main Groovy script, all Jenkins environment variables are available as so called properties. Properties, because you main script is more than just a similar shell script, in fact you are working with an instance of a Groovy class, that's why there are properties. For example, you can read the value of Jenkins' `BUILD_NUMBER` environment variable in DSL script like this

{% gist 87ed464b14f1a1e86ad297207ebbbd9e %}

Very convenient way to read any environment variable. Additionally you can use [EnvInject](https://wiki.jenkins-ci.org/display/JENKINS/EnvInject+Plugin) plugin and inject more environment variables to the build job.

# Missing Properties

But what happens if environment variable is not defined? In that case corresponding property will not be defined as well, so if you try to read that property, you will get a runtime error.

{% gist 9ce75d70138ffe908ddf9b3a4cc03329 %}

So what do you do if you really want to read the variable first and if it's not there just use sensible default? For example

{% groovy 14bebdb1a29f9cd87e305e839771bafd %}

First thing you may try is to use `hasProperty` method which is a member of any Groovy class.

{% gist 135333a5b31b566dda62e0b5885dc958 %}

This code will not throw a runtime error. The problem is that `hasProperty` will always return `false`.

# Bindings

All is not lost though. Each Jenkins DSL script has a reference to so called "bindings". Apparently, bindings are used to bind all the environment variables and make them available for the script. Additionally bindings include references to things like standard output, which will come handy later on.

{% gist 54c9692b9caf4d3dfbff6a972f71a772 %}

That's all you have to do to get the script bindings. Now you can access environment variables in a safe way.

{% gist c650e41f14249f1048ea3d580622083a %}

If the property is not defined, the return value is `null` and your code will fallback to a default value.

# Standard Output

As I mentioned before, bindings also bind such things as standard output. By default `println` statements will work only when called from the body of the main script. If you use packages and other classes in your DSL, logging from other modules via `println` statement will not work, will not yield any output to console to be more specific.

{% gist 69291c413caa8ea7757fba7ee3ab7561 %}

Of course it makes no sense to declare Logger class in the body of the main script. Proper way is to factor it out into a separate file and import the package instead. I plan to have a write up on advanced DSL with classes and packages.
