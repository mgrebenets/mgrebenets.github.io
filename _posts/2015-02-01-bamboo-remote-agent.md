---
layout: post
title: "Bamboo Remote Agent"
description: ""
category:
tags: []
---
{% include JB/setup %}


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
