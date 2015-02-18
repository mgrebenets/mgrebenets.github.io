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

## Install

> A kind of warning first, avoid installing Jenkins as Launch Daemon. For detailed reasoning checkout out [this article]({% post_url 2015-02-01-mobile-ci-daemon-vs-agent %}).

[Jenkins Wiki](https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins) offers a list of options for Jenkins installation but doesn't mention Mac OS X. It mentions [Docker](https://www.docker.com/) though and I've heard nothing but good things about Docker. In this article I will stick with [Homebrew](http://brew.sh/).

You will need JDK to be [installed and configured on your Mac]({% post_url 2015-02-15-install-java-on-mac-os-x %}) before proceeding.

To install run a simple shell command.

{% highlight bash %}
brew install jenkins
{% endhighlight %}

Jenkins will be installed to `usr/local` and Homebrew will actually tell you right away how to turn it into a Launch Agent.

{% highlight bash %}
To have launchd start jenkins at login:
    ln -sfv /usr/local/opt/jenkins/*.plist ~/Library/LaunchAgents
Then to load jenkins now:
    launchctl load ~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist
{% endhighlight %}


This recommends you to symlink Jenkins launch agent plist file to `~/Library/LaunchAgents` but I would advise against it. As you will see next you will need to modify that file. That means if you ever upgrade Jenkins via Homebrew all your changes in plist will be lost. My recommendation is to copy it instead of making a symbolic link.

Even more, once installed via Homebrew I then delegate Jenkins upgrades to Jenkins itself. For this reason I pin Homebrew formula to prevent Homebrew from upgrading Jenkins files.

{% highlight bash %}
brew pin jenkins
{% endhighlight %}

Now you also have manual control over Jenkins installation and can start/stop it from command line.

{% highlight bash %}
# start
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist

# stop
launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist
{% endhighlight %}


## Configure

To understand why you need to change plist try to run Jenkins server. Give it a go, create a couple of build projects that do some basics like checking out git repository and running simple build command. Very soon you should get an error message saying that Jenkins has ran out of memory. This seems to be a common issue with JVM and Mac OS X, [Bamboo installations run into same problems]({% post_url 2015-02-01-bamboo-ci-server-on-osx%}). I'm not quite sure why default configuration doesn't account for this, probably this is Mac specific and other operating systems are OK. Anyway, you need to modify default plist file for Launch Agent. Here's what you need and might want to change.

**JVM Virtual Memory and Garbage Collection**

- Tell JVM to use a 64-bit data model if available (`-d64`).
- Set minimum and maximum heap size with `-Xms` and `Xmx` flags. 512 Mb works for me most of the time.
- Configure garbage collector, class unloading and permanent space.

{% highlight xml %}
  <string>-d64</string>
  <string>-Xms512m</string>
  <string>-Xmx512m</string>
  <!-- Use Concurrent GC-->
  <string>-XX:+UseConcMarkSweepGC</string>
  <string>-XX:+CMSClassUnloadingEnabled</string>
  <string>-XX:MaxPermSize=256m</string>
{% endhighlight %}

**HTTP Proxy**

By far the largest source of issues and frustration, company proxy. Specify it using `-D` option.

{% highlight xml %}
  <string>-Dhttp.proxyHost=my-compnay-proxy-host.com.au</string>
  <string>-Dhttp.proxyPort=8080</string>
{% endhighlight %}

**Port and Prefix**

Run Jenkins on a custom port with custom prefix in url. This example uses default `8080` port and `/jenkins` prefix, so you can access your Jenkins dashboard like `http://yourhostname:8080/jenkins` or ever `http://youthostname/jenkins`. These arguments need to be passed to `jenkins.war` which was installed by Homebrew to `/usr/local/opt/jenkins/libexec`.

{% highlight xml %}
  <string>-jar</string>
  <string>/usr/local/opt/jenkins/libexec/jenkins.war</string>
  <string>--httpListenAddress=127.0.0.1</string>
  <string>--httpPort=8080</string>
  <string>--prefix=/jenkins</string>
{% endhighlight %}

**Run at Load**

Enable Run at Load option to start server automatically if machine reboots.

{% highlight xml %}
  <key>RunAtLoad</key>
  <true/>
{% endhighlight %}

**Environment Variables**

If any of the commands in this plist need environment variables this is how you can define them.

{% highlight xml %}
<key>EnvironmentVariables</key>
   <dict>
    <key>HTTP_PROXY</key>
    <string>http://my-compnay-proxy-host.com.au:8080</string>
  </dict>
{% endhighlight %}

**Standard Output and Error**

It is up to you to redirect stdout and stderr. While sounds like a good idea for logging I would advise agains redirecting stderr into a file. I once had to deal with 90 Gb log file created by Bamboo remote agent over a few months period.

{% highlight xml %}
  <!--
  <key>StandardOutPath</key>
  <string>/Users/i4niac/.jenkins/log/output.log</string>
  -->
  <key>StandardErrorPath</key>
  <string>/Users/i4niac/.jenkins/log/error.log</string>
{% endhighlight %}

Note that Jenkins put its files in `.jenkins` folder in your user's home path. You also have to specify full paths when dealing with launch agent plists. Create `log` folder if it's not there yet.

**Other**

By default Jenkins enables security protocol for email. I have also faced an issue with [Bitbucket Plugin](https://wiki.jenkins-ci.org/display/JENKINS/BitBucket+Plugin) and had to set `preferIPv4Stack` flag as a workaround. These are all flags for `java` command.

{% highlight xml %}
  <string>-Dmail.smtp.starttls.enable=true</string>
  <string>-Djava.net.preferIPv4Stack=true</string>
{% endhighlight %}


Not put it all together

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>homebrew.mxcl.jenkins</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/java</string>
    <string>-server</string>
    <string>-d64</string>
    <string>-Xms512m</string>
    <string>-Xmx512m</string>
    <string>-Dmail.smtp.starttls.enable=true</string>
    <!-- Use Concurrent GC-->
    <string>-XX:+UseConcMarkSweepGC</string>
    <string>-XX:+CMSClassUnloadingEnabled</string>
    <string>-XX:MaxPermSize=256m</string>
    <string>-Djava.net.preferIPv4Stack=true</string>
    <string>-Dhttp.proxyHost=my-compnay-proxy-host.com.au</string>
    <string>-Dhttp.proxyPort=8080</string>
    <string>-jar</string>
    <string>/usr/local/opt/jenkins/libexec/jenkins.war</string>
    <string>--httpListenAddress=127.0.0.1</string>
    <string>--httpPort=8080</string>
    <string>--prefix=/jenkins</string>
  </array>
  <key>RunAtLoad</key>
  <true/>

  <key>EnvironmentVariables</key>
   <dict>
    <key>HTTP_PROXY</key>
    <string>http://my-compnay-proxy-host.com.au:8080</string>
  </dict>
</dict>
</plist>
{% endhighlight %}

Now you have a reliable Jenkins server that runs 24/7 and performs stable CI tasks.

## Tips

To find out how exactly Jenkins was launched, grep active processes list.

{% highlight bash %}
ps aux | grep java
{% endhighlight %}

The output will tell you everything you need to know.

{% highlight bash %}
jenkins   85   0.0  3.8  4633552 636852   ??  Ss   Tue02pm  20:11.30
  /usr/bin/java
    -Dfile.encoding=UTF-8
    -XX:PermSize=256m -XX:MaxPermSize=512m
    -Xms512m -Xmx512m
    -Djava.io.tmpdir=/Users/Shared/Jenkins/tmp
    -Dhttps.proxyHost=my-compnay-proxy-host.com.au -Dhttps.proxyPort=8080
    -Dhttp.proxyHost=my-compnay-proxy-host.com.au -Dhttp.proxyPort=8080
    -jar /usr/local/opt/jenkins/libexec/jenkins.war
      --prefix=/jenkins
      --httpPort=8080
{% endhighlight %}

## Other Ways

### Jenkins Runner

There are other ways to install and start Jenkins server, one of them is using [jenkins.sh](https://wiki.jenkins-ci.org/display/JENKINS/Jenkins+Runner) runner script. It is not bundled with Homebrew installation by default, you should download it manually as mentioned on the Jenkins Wiki page.

In this case all the configuration options are in `data/wrapper.conf` file, you can check [default file](https://github.com/mnadeem/JenkinsRunner/blob/master/conf/wrapper.conf) and easily figure out where to add your custom options.

The runner shell script itself can be launched as Launch Agent or Launch Daemon. Overall this is just a higher level of configuration.

### Legacy Runner

Another approach I've seen is to use custom runner script. I am actually working with one right now but I suspect this is a legacy version of `jenkins.sh`.

The main difference is that all configuration is stored in Mac OS X defaults and then read by the script like this.

{% highlight bash %}
defaults read /Library/Preferences/org.jenkins-ci
{% endhighlight %}

Defaults are stored as plist and are read as a dictionary. An example output looks like this

{% highlight bash %}
{
    heapSize = 512m;
    "http.proxyHost" = "my-company-proxy-host.com.au";
    "http.proxyPort" = 8080;
    httpPort = 8080;
    "https.proxyHost" = "my-company-proxy-host.com.au";
    "https.proxyPort" = 8080;
    minHeapSize = 256m;
    minPermGen = 256m;
    permGen = 512m;
    prefix = "/jenkins";
    tmpdir = "/Users/Shared/Jenkins/tmp";
}
{% endhighlight %}

Using `[sudo] defaults write` you can change Jenkins configuration.

Obviously this is less preferred way than using `wrapper.conf`. Using OS X defaults leads to configuration which is non-reusable on other operating systems and can't be easily put in SCM if needed.

## Summary

A short summary - install with Homebrew, configure as Launch Agent. To configure Jenkins for Mobile CI tasks you can read other articles in this blog.

The configuration is far from being final. You will have to install plugins, configure SSH keys for git repositories and perform multitude of other administrative tasks to bring your Jenkins CI box up to speed.
