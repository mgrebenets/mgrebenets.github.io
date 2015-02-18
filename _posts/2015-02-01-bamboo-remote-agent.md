---
layout: post
title: "Bamboo Remote Agent on Mac OS X"
description: "Install and Configure Bamboo Remote Agent on Mac OS X"
category: Mobile CI
tags: [mobile, ci, bamboo, remote, agent]
---
{% include JB/setup %}

A short giude for installing and configuring Bamboo Remote Agent on Mac OS X.

<!--more-->

The starting point for an agent is a server, you should either have it configured for you or [install yourself]({% post_url 2015-02-01-bamboo-ci-server-on-osx%}).

[Atlassian documentation](TODO:link) is always a good place to start. Next important thing is to have [Java installed]({% post_url 2015-02-15-install-java-on-mac-os-x %}) on remote agent machine.

## Configure Server

You start by configuring server. Open Bamboo server dashboard in the browser and navigate to Bamboo Administration page (via Settings button in top right). Surely you have to be admin to get there.

![Bamboo Settings]({{ site.url }}/assets/images/bamboo-settings.png)

Now select Agents on the left and click "Enable remote agent support".

![Bamboo Enable Remote Agents]({{ site.url }}/assets/images/bamboo-enable-remote-agents.png)

You can click "Install remote agent" now.

![Bamboo Install Remote Agent]({{ site.url }}/assets/images/bamboo-install-remote-agent.png)

## Configure Agent

You are now looking at the page with further instructions. Just like [Jenkins build agent]({% post_url 2015-02-01-jenkins-remote-node %}) Bamboo Remote Agent is a Java JAR file that needs to be downloaded to a target agent machine and then ran there.

[Bamboo Install Remote Agssent]({{ site.url }}/assets/images/bamboo-install-remote-agent-page.png)

Before you proceed you need to configure remote agent machine. Just like Bamboo server works well with a special user, remote agent will benefit from running under a designated user account. Create a Standard account from System Preference, in this example is will name it `bamboo-agent` so this user's home will be `/Users/bamboo-agent`.

===========

use these links
https://confluence.atlassian.com/display/BAMBOO021/Running+Bamboo+behind+a+firewall+with+Remote+Agents+outside+the+firewall

why it can't sit in the cloud
https://answers.atlassian.com/questions/22655/bamboo-mac-agent

how to get the jar
how to configure it's launch
how to make it a launch agent (and why not launch daemon)
how to configure plist, what are other options around that
what's the purpose of .sh runner script and how it relates to jar

fails to get fingerprint and other stuff

put all the notes about failover url
it must have a host name or ip when both are running in local environment

it must have an ip (hostname won't work) when server is outside your network (e.g. aws cloud)

how to enable logging and use it for debugging problems


keychain: might be good as a separate note
how to unlock keychain for it (all the keys)
how to unlock keychain as part of build scripts (might be good as a separate note)

simulator: separate note
how to enable dev mode on the machine (and why)
how to work with simulator, reset it (via ios-sim old days, via xcrun since xcode 6)


derived data - separate and very short note

note on the Docker with the link I saw once
