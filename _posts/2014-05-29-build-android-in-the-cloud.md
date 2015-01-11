---
layout: post
title: "Build Android in the Cloud"
description: "Build an Android app on AWS cloud instance"
category: Android
tags: [android, google, aws, amazon, linux, 32-bit, gradle]
---
{% include JB/setup %}

In this example, you are given a task to build Android app on a 64-bit AWS Linux build agent running in Amazon Cloud (AWS).

<!--more-->

# Install Android SDK

You have to start with installing Android SDK first.

## Download
Start with downloading latest Linux version, found on [this page](https://developer.android.com/sdk/index.html). You can find direct link to tarball in "DOWNLOAD FOR OTHER PLATFORMS" section.

{% highlight bash %}
wget http://dl.google.com/android/android-sdk_r22.6.2-linux.tgz
{% endhighlight %}

## Extract and Move
Extract it and put in preferred location, in this example it's `/usr/local/opt/android-sdk`

{% highlight bash %}
# extract
tar xzf android-sdk_r22.6.2-linux.tgz
# move
mv android-sdk-linux /usr/local/opt/android-sdk
{% endhighlight %}

## Configure PATH
Now configure `ANDROID_HOME` and update the path. That is done by modifying `~/.bash_profile`, create the file if you don't have it yet.

{% highlight bash %}
export ANDROID_HOME=/usr/local/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools
if [[ -d $ANDROID_HOME/build-tools ]]; then
    ANDROID_BUILD_TOOLS_HOME=$(dirname $(find $ANDROID_HOME/build-tools -name aapt | tail -1))
    echo "Android Built Tools located: $ANDROID_BUILD_TOOLS_HOME"
    export PATH=$ANDROID_BUILD_TOOLS_HOME:$PATH
fi
{% endhighlight %}

You noticed that adding Android Build Tools to the path is optional. That's because we didn't install Build Tools yet.

## Update Android SDK

This is where you update Android SDK, install all the tools and APIs, including Build Tools and Android Support Repository and Library. Remember, this Linux instance is running in the AWS Cloud meaning it's headless (no GUI) and you only can work with the shell.

If you happened to read older version of this article, you'd remember seeing a lot of shell scripts using `grep`.

This is a revised version, with much simpler and cleaner code.

The command that does the job is `android update sdk`. You need to use `--filter` option to specify list of packages you need to update or install. To get readable identifiers of all available packages, run the following command

{% highlight bash %}
android list sdk --all --extended
{% endhighlight %}

`--extended` flag is used to display extended information about each package, including a human readable identifier. `--all` is needed to include extra packages, like build tools, by default they won't be listed. Here's an example output.

{% highlight bash %}
----------
id: 3 or "build-tools-20.0.0"
     Type: BuildTool
     Desc: Android SDK Build-tools, revision 20
----------
id: 4 or "build-tools-19.1.0"
     Type: BuildTool
     Desc: Android SDK Build-tools, revision 19.1
----------
{% endhighlight %}

You can now compose filter as a comma-separated list of all package identifiers you want to install. Since it's a headless build box, you will have to use `--no-ui` option, and `--all` is needed to include extra packages.

{% highlight bash %}
FILTER=tool,platform,android-20,build-tools-20.0.0,android-19,android-19.0.1
android update sdk --no-ui --all --filter $FILTER
{% endhighlight %}

This example installs _Android SDK Tools_, _Platform tools_, _Build tools_ versions _20.0.0_ and _19.0.1_, as well as _SDK Platform 19_ and _20_. Customize the list to your needs using proper identifiers.

### Answering the Prompts
But it's not done yet. When installing or updating, you will have to accept license prompts. Each package can have it's own license requiring you to answer a prompt with "y".

You'd probably think of `yes` command line utility designed for this particular task. However it will not work. `yes` outputs "y" to stdout too often with no options to put delays in between. Android SDK update tool expects not just "y", but a "y" followed by return key, in other words, it expects "y\n" string as a whole. I don't know the exact mechanics of `yes` command, but if you try something like this
{% highlight bash %}
FILTER=tool,platform,android-20,build-tools-20.0.0,android-19,android-19.0.1
yes | android update sdk --no-ui --all --filter $FILTER
{% endhighlight %}
you will see that the license prompt will complain about incorrect input and fail after a number of attempts.

The solution is to put certain delay between "y" outputs to stdout. This code I found on the web, it's reliable and does the job.
{% highlight bash %}
FILTER=tool,platform,android-20,build-tools-20.0.0,android-19,android-19.0.1
( sleep 5 && while [ 1 ]; do sleep 1; echo y; done ) \
    | android update sdk --no-ui --all \
    --filter ${FILTER}
{% endhighlight %}

### Project Specific SDK Update
If you have various Android projects, each with it's own requirements for Android packages, it would be reasonable to add Android SDK update task to the project's build configuration. In this example I will use Gradle, so here's an example of Gradle task

{% highlight bash %}
task updateSDK(type: Exec) {
    ext.filter = "tool,platform-tool,android-20,build-tools-20.0.0,android-19,build-tools-19.1.0,build-tools-19.0.1,extra-android-support,extra-android-m2repository,extra-google-m2repository,extra-google-google_play_services,extra-google-google_play_services_froyo"
    commandLine "sh", "-c", "( sleep 5 && while [ 1 ]; do sleep 1; echo y; done ) \
    | android update sdk --no-ui --all \
    --filter ${filter}"
}
{% endhighlight %}

### Caveats
The last and very annoying bit, is that this script seems to update packages even if they are already installed. At the moment I have no clue what's causing this behavior and what's the best workaround. When it comes to running this script on one of the Bamboo agents in the cloud it doesn't really matter, but when the script runs on one and only Mac build agent you have - this really slows down each build.


# Install 32-bit Libraries
Before you try to build anything, you have to do one more thing.

Remember, the host OS is 64-bit Linux system. Android requires a bunch of 32-bit libraries and you have to install them. The Linux system in question is RPM-based so this example uses `yum` command, change it to `apt-get` or another package manager specific for your OS.

{% highlight bash %}
# install 32-bit libraries
sudo yum install glibc.i686, zlib.i686, libstdc++.so.6 libz.so.1
{% endhighlight %}

Now you're good to go!

# Summary

This is a TLDR or a summary section, that simply lists the solution "as is".

{% highlight bash %}
# install 32-bit libraries
sudo yum install glibc.i686, zlib.i686, libstdc++.so.6 libz.so.1
{% endhighlight %}

{% highlight bash %}
# update Android SDK on headless server
FILTER=tool,platform,android-20,build-tools-20.0.0,android-19,android-19.0.1
( sleep 5 && while [ 1 ]; do sleep 1; echo y; done ) \
    | android update sdk --no-ui --all \
    --filter ${FILTER}
{% endhighlight %}