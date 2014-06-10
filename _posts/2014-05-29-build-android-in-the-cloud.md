---
layout: post
title: "Build Android in the Cloud"
description: ""
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

You might say "So what? `android update sdk` command has `--no-ui` switch. What's the big deal?" You are right, this will work, but you still have to do it manually, one of the reasons is that you have to answer the command line prompt with _"y"_. It won't work if you run Android SDK Update as part of build task. Also, updating and installing the Build Tools needs a bit of extra work, same problem with Android Support. You need to install Build Tools if you use `aapt` or any other build tool, and most of the Android apps need stuff from Android Support Repository and Library.

### Update Basic Packages

So, the first part (answering the prompt) is easy, `echo "y"` is your friend. This is how you can install and update Tools, Platform Tools, Platform.

{% highlight bash %}
echo "y" | android update sdk --filter tool,platform,platform-tool --no-ui
{% endhighlight %}

Note that there's no `build-tool` or `android-support` in the filter. That's because those are not "default" filters. You have to create custom filter for them.

### Build-tools, Android Support Repository and Library, etc.

Next let's get the full list of SDK packages and use it to create a custom filter.

{% highlight bash %}
# Temp dir
TMP_DIR=$(mktemp -dt "XXXXXXXX")

SDK_LIST=${TMP_DIR}/sdk-list.txt
android list sdk > ${SDK_LIST}
{% endhighlight %}

Now grep all the lines that contain package names which you need.

{% highlight bash %}
FILTER=${TMP_DIR}/filter.txt
# grep the build tools
grep "Android SDK Build-tools" ${SDK_LIST} > ${FILTER}
# grep the support repository and library
grep "Android Support" ${SDK_LIST} >> ${FILTER}
{% endhighlight %}

Here comes a small update, if you plan to run an Android emulator on this machine, you will need to install ABI image. It might be either ARM or x86 image, the lines below will add both.

{% highlight bash %}
# grep ABI image to be able to create AVDs and run emulator
grep "ABI" ${SDK_LIST} >> ${FILTER}
# grep x86 images and APIs, need it to run x86 emulator
grep "x86" ${SDK_LIST} >> ${FILTER}
{% endhighlight %}

Other than `tool`, `platform` or `platform-tool` filters, `--filter` option for `android update sdk` also understands package identifiers. Package identifier is a number listed on the left of the package name.

{% highlight bash %}
Packages available for installation or update: 97
    1- Android SDK Tools, revision 22.6.2
    2- Android SDK Platform-tools, revision 19.0.1
    3- Android SDK Build-tools, revision 19.0.3
    4- Android SDK Build-tools, revision 19.0.2
    5- Android SDK Build-tools, revision 19.0.1
    # ***
    36- Android Support Repository, revision 5
    37- Android Support Library, revision 19
{% endhighlight %}

In this example _3_ is an ID for _Android SDK Build-tools, revision 19.0.3_, _36_ is an ID for _Android Support Repository, revision 5_.

You need to parse these identifiers and make a comma-separated list for a filter. And you already have reduced the list of packages and saved it in `filter.txt`.

{% highlight bash %}
# read filter.txt ($FILTER) line by line and parse the id to use later
while read p
do
    # cut by "-", take the first part and trim the spaces
    ID=$(echo $p | cut -d- -f1 | tr -d ' ')
    # add to comma-separated list
    ARR="${ARR}${ID},"
done < ${FILTER}

# cut off the trailing comma
echo $ARR | rev | cut -d, -f2- | rev
{% endhighlight %}

The `$ARR` now contains a comma-separated list of package IDs, time to use it as a filter.

{% highlight bash %}
echo "y" | android update sdk --filter $ARR --no-ui
{% endhighlight %}

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
#!/bin/bash

# Update Android SDK
# Tools, Platforms, Platform Tools and Build tools

# Temp dir
TMP_DIR=$(mktemp -dt "XXXXXXXX")

# --- Step 1 ---
# update all "default" tools and platorm
echo "y" | android update sdk --filter tool,platform,platform-tool --no-ui

# --- Step 2 ---
# capture all the tools in a text file to speed things up
SDK_LIST=${TMP_DIR}/sdk-list.txt
android list sdk > ${SDK_LIST}

FILTER=${TMP_DIR}/filter.txt
# grep the build tools
grep "Android SDK Build-tools" ${SDK_LIST} > ${FILTER}
# grep the support repository and library
grep "Android Support" ${SDK_LIST} >> ${FILTER}
# grep ABI image to be able to create AVDs and run emulator
grep "ABI" ${SDK_LIST} >> ${FILTER}
# grep x86 images and APIs, need it to run x86 emulator
grep "x86" ${SDK_LIST} >> ${FILTER}

# if there's nothing to install, stop the task
! [[ -s ${FILTER} ]] && echo "Blank filter - Nothing to install" && exit 0

# read line by line and parse the id to use later
while read p
do
    # cut by "-", take the first part and trim the spaces
    ID=$(echo $p | cut -d- -f1 | tr -d ' ')
    # add to comma-separated list
    ARR="${ARR}${ID},"
done < ${FILTER}

# cut off the trailing comma
echo $ARR | rev | cut -d, -f2- | rev

# now install
echo "y" | android update sdk --filter $ARR --no-ui

# EOF
{% endhighlight %}