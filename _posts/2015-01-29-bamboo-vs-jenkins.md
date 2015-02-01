---
layout: post
title: "Bamboo vs Jenkins"
description: "Bamboo vs Jenkins as Mobile CI"
category: Mobile CI
tags: [mobile, bamboo, jenkins, atlassian, hudson, ci]
---
{% include JB/setup %}

A [biased and subjective] comparison of Bamboo and Jenkins as CI servers for mobile, based on practical experience with both.

<!--more-->

//TODO: what's it about in short

## Setup & Configuration

## GUI

## Branch Management

## Build Job/Plan Structure

## Plugins
This is where the large community plays it's role. Subjectively or not, Jenkins has a larger choice of plugins of all kinds, starting from management and organization of build jobs and ending up with reporting.

While Bamboo supports lots of job management features out of the box, reporting plugins is something that needs to be improved.

TODO: take the plugins I use (PMD, Cobertura, Unit Tests, HTML publisher, SLOC)
TODO: note that jenkins shows graphics with trends

And then there is the Mother and the Farther of all Jenkins plugins - [Jenkins Job DSL Plugin](). In short, it allows you to keep your configuration as a code.

Check out this good talk and resources (TODO: put more links as a reference) to find out more.

I plan to write a post about my personal experience with using Job DSL plugin.

## Distributed Builds
Both Bamboo and Jenkins have support for distributed builds. Bamboo is using [Remote Agents](https://confluence.atlassian.com/display/BAMBOO/Bamboo+remote+agent+installation+guide) while Jenkins calls them [Remote Nodes](https://wiki.jenkins-ci.org/display/JENKINS/Distributed+builds ), sometimes referred as slave nodes.

A side note - both servers support local build agents/nodes as well. Those are running locally (as the name suggests) on the same hardware as the build server.

Back to remote agents/nodes. Complexity of setting them up and configuring doesn't vary much between the two CI servers.

Both will suffer from issues caused by sitting behind the company proxy, specifically if the server is located somewhere outside your company network (e.g. in AWS cloud).

Why the server is in the cloud and the agent/node is not? - you'd ask. Well, that takes us to next topic.

## Mac Support
Right, this whole comparison is focusing on Mobile CI after all, meaning you have to deal with one of the most popular mobile platforms these days - that is iOS.

To build an iOS app you must have Xcode, which can run only on OSX (unless you want to follow the path of certain insanity and make it work on other OS).

_Hackintosh_? Not a very good idea I'd say. The company does iOS development and wants to go with Hackintosh to setup OSX build server, really?

_Cloud (aka OnDemand)_? Could be a really good option, but not with industry giants like AWS. AWS or alike is where you'd go if using Bamboo OnDemand feature. I can find posts as old as 2011 discussing this issue: [one](https://answers.atlassian.com/questions/22655/bamboo-mac-agent), [two]((https://jira.atlassian.com/browse/BAM-11870). Apple doesn't make it easy to run virtual OSX instances to the extend that none of the cloud providers are brave enough to provide official support for this feature. These days you can go with one of the many Mac Mini colocation services. You either rent a Mac hardware or even provide your own.

_Self-hosted_? This is also an option. If your company has security concerns about those Mac hosting providers, or doesn't want to spend money for that, or for any other reason, you can always purchase Mac hardware and host it in your data center.

Whenever you are using self-hosting or remote hosting, you end up dealing with native hardware. I find that Mac Minis with maximized CPU, RAM, and SSD storage are perfect candidates for iOS CI box. The more you have the better.

Next step is to install remote agent/node and get it running. As I mentioned already, installing [remote agent for Bamboo](TODO: my post) is as difficult/easy as installing [remote node for Jenkins](TODO: my post). The problems start popping up when you begin using them.

### Bamboo Remote Agent
Thins you definitely need to know in regards to Bamboo remote agent.

[The rumor has it that] Atlassian are using Mac OSX to develop their products, including Bamboo, but OSX is never ever listed as _officially_ supported. Indeed, why would you choose to run your JIRA, Stash, Bamboo, whatever, on OSX server? Hopefully with increasing demand for iOS CI Atlassian will put a bit higher priority on fixing Bamboo issues for OSX, and there's plenty btw.

Before you even start using remote agent on OSX, you have to experience a bit of pain [when trying to set it up](TODO: my post).

Major and the most important group of issues is related to *Artefacts Sharing*.

Whenever your remote agent finishes a build stage it is most often producing build artefacts. It _doesn't matter_ if those artefacts are shared or not, they must be copied to the server anyway. That is part of distributed build system. Your remote agent can go offline any time, your build plan jobs can run on different agents with different capabilities and artefacts must be passed from one agent to another. All in all, the reality is - the artefacts must be shared.

_Problem "Proxy"_

Is your remote agent behind proxy? May I introduce you to [HTTP 1.1 Chunked Transfer Encoding](http://en.wikipedia.org/wiki/Chunked_transfer_encoding) then? Well, not to the feature itself, but how it relates to Bamboo: [BAM-5182](https://jira.atlassian.com/browse/BAM-5182), [more](https://confluence.atlassian.com/pages/viewpage.action?pageId=420971598).

Bamboo server requires support of HTTP chunked transfer feature of 1.1 protocol version to pick up artefacts. If your proxy doesn't support this feature, you are in trouble. Strictly speaking, this is not Bamboo's problem, this is the problem of your company network team. HTTP 1.1 standard was released in [1999](http://www.w3.org/Protocols/rfc2616/rfc2616.html)! There is a lot of http proxy implementations that support it, [nginx](http://nginx.org/en/) for example. However, things move really slow in most of big companies when it comes to changing network infrastructure. If you are so unlucky and you company is still stuck around 1999 in terms of network infrastructure, you will most likely have to find a work-around rather than waiting months and months before you get any progress on proxy upgrade.

_Problem "Atlassian"_

But wait then! Too early to take all the blame off the Atlassian's shoulders!

First of all, Bamboo remote agent JAR [totally disrespects JVM flags for http proxy whitelist (nonProxyHosts)](https://answers.atlassian.com/questions/75941/remote-agent-not-honoring-the-dhttp-nonproxyhosts-parameter), [upvote!](https://jira.atlassian.com/browse/BAM-12041) You can find ways around this issue, for example re-routing network calls using tools like [SquidMan](http://squidman.net/squidman/), but then you will face *The Final Blocker*: [BAM!](https://jira.atlassian.com/browse/BAM-8111), [BAM!](https://jira.atlassian.com/browse/BAM-8226).

Yes, Bamboo remote agent [is 27 (_twenty seven!_) times slower than plain `scp`](https://jira.atlassian.com/browse/BAM-8111?focusedCommentId=622466&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-622466) ([secure copy over ssh](http://en.wikipedia.org/wiki/Secure_copy)) command when it comes to copying a single `.zip` file which is around few hundred Mb of size.

Imagine that after spending all the time trying to figure out issues around your proxy and enable the agent to share artefacts with the server you end up facing this beast? It renders all your distributed build setup useless, it takes way more time to copy build artefacts than to produce them. From reports it looks like this issue is specific for Mac OS build agents only.

When I faced this problem I ended up sharing artefacts via Amazon S3 bucket. This is extra work, extra shell scripts to upload and download artefacts, additional expenses for S3 bucket. You become responsible for managing outdated artefacts, you are the one who has to account for multiple build plan branches, and much more. This is really a bit too much of overhead and it is extra annoying when you know this is a core Bamboo functionality and it's supposed to work right out of the box.

### Jenkins Remote Node
