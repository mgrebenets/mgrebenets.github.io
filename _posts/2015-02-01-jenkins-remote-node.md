---
layout: post
title: "Jenkins Remote Node"
description: "Setup and Configure Jenkins Remote Node"
category: Mobile CI
tags: [mobile, ci, jenkins, remote, agent, slave, node]
---
{% include JB/setup %}

A guide for setting up a remote build node for Jenkins CI server.

<!--more-->

If you are up to a task to setup remote build node, that means that you already have a server or need to [install it first]({% post_url 2015-02-01-jenkins-ci-server-on-osx %}).

A good place to start is [Jenkins Wiki page](https://wiki.jenkins-ci.org/display/JENKINS/Distributed+builds) with detailed description of all available options. Don't forget to have a proper [JVM installation]({% post_url 2015-02-15-install-java-on-mac-os-x %}) first.

I would recommend to do first time agent installation via Jenkins UI `Jenkins -> Manage Jenkins -> Manage Nodes`. Select an option to create node, configure node's properties (make sure root directory exists) and you are almost good to go. The preferred way to launch and agent is via SSH.

If Jenkins Wiki is such a good reference, then why bother with the post? - I bet that's exactly what you are asking.

Well, again, the main focus is Mobile CI and part of any decent CI is tests, unit tests in particular. With iOS those must run in iOS Simulator which is a GUI application, which means you are facing [Daemon vs Agent]({% post_url 2015-02-01-mobile-ci-daemon-vs-agent%}) issue. Here's a very good [discussion on StackOverflow](http://stackoverflow.com/questions/25380365/timeout-when-running-xcodebuild-tests-under-xcode-6-via-ssh).

So remote node launched via SSH is running as Launch Daemon and has no context to run GUI applications. If SSH session is running under non-login user, `xcodebuild test` will fail with error code `139` or alike. Running SSH session under login user will not help either, at best the simulator will but tests will never start. That rules out an option of running remote node via SSH. Trying all the tricks like enabling development mode, updating user's group and security settings, didn't work for me, probably because that answer was actual for Xcode 5, but not 6.

Next option would be launching slave agent via Java Web Start. Option with clicking button in the browser should be ignored right away, it hardly qualifies as automated approach. Using `javaws` it a bit better though requires you to login to slave agent via GUI and then run the command and answer one prompt by clicking Run button. Finally, you can run it in a headless mode

{% highlight bash %}
java -jar slave.jar \
  -jnlpUrl http://yourserver:8080/jenkins/computer/parasite/slave-agent.jnlp
{% endhighlight %}

Now that's better, this will start a slave agent that is capable of running GUI applications and thus running iOS unit tests in simulator. If you are puzzled where does `slave.jar` come from, the answer is that it is put there by Jenkins server when you have created slave agent via UI. The `jnlpUrl` tells an agent where the server is. The order in which agent and server are fired up seems to be important. Server first, agent second, otherwise agent may fail to start. I had this issue while using GUI mode launch via `javaws` and yet to confirm if it's true for headless mode. Still you have to start an agent manually if remote node machine reboots.

I have one solution to offer. It is not the best I can think of, but it's the easiest and reasonably reliable to start with. You need to turn the headless slave launch command into a Launch Daemon. The Launch Agent will start at the time of user's login, so make sure the machine is configured for automatic login.

Setting up Launch Agent should become a usual drill for you after you deal with Mac-based CI for a while. Create a plist file in `~/Library/LaunchAgents`, name it what you like, for example `org.jenkins-agent-a.plist` and put the following content in it.

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>StandardOutPath</key>
    <string>/Shared/Users/Jenkins-Agent-A/log/jenkins-agent-a-out.log</string>
    <key>StandardErrorPath</key>
    <string>/Shared/Users/Jenkins-Agent-A/log/jenkins-agent-a-err.log</string>
  <key>KeepAlive</key>
  <true/>
  <key>Label</key>
  <string>org.jenkins-agent-a</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/java</string>
    <!--<string>-Djava.util.logging.config.file=/opt/hudson/slave/logging.properties</string>-->
    <string>-Duser.home=/Users/Shared/Jenkins-Agent-A</string>
    <string>-jar</string>
    <string>/Users/Shared/Jenkins-Agent-A/slave.jar</string>
    <string>-jnlpUrl</string>
    <string>http://yourserver:8080/jenkins/computer/parasite/slave-agent.jnlp</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
{% endhighlight %}

The `/Shared/Users/Jenkins-Agent-A` is your agent's home. You should have create one when setting up agent via server UI and `slave.jar` should be already located in this folder. Now if agent machine reboots and autologin is configured, the agent will go back online automatically. If the server reboots though, I'm not quite sure what happens, my assumption is that agent will stay alive and will keep trying to reconnect to server and finally they both happily reunite. I'm yet to test how exactly it works in reality.

To manually start and stop an agent use following commands (typealias if you need to use them often)

{% highlight bash %}
# start
launchctl load ~/Library/LaunchAgents/org.jenkins-agent-a.plist

# stop
launchctl unload ~/Library/LaunchAgents/org.jenkins-agent-a.plist

# list (by label)
launchctl list org.jenkins-agent-a
{% endhighlight %}


One additional note. You can run a remote agent on localhost, which technically makes it not remote any more. This may be useful when for some reason Jenkins server is launched under non-login user session (Launch Daemon again) and you can't use default master node to run unit tests.

That sums it up. To compare how things are in Bamboo universe [check out this post]({% post_url 2015-02-01-bamboo-remote-agent %}).
