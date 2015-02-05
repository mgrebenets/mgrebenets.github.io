---
layout: post
title: "Bamboo vs Jenkins"
description: "Bamboo vs Jenkins as Mobile CI"
category: Mobile CI
tags: [mobile, bamboo, jenkins, atlassian, ci]
---
{% include JB/setup %}

A [biased and subjective] comparison of Bamboo and Jenkins as CI servers for mobile, based on practical experience with both.

<!--more-->

Continuous Integration and Continuous Deployment (Delivery, Distribution) has been around for quite a while. But surprisingly enough on a global scale it pretty much just got into its teen years in regards to Mobile. Well, subjectively, of course.

You can see all levels of mobile CI these days. Some would still install builds from Xcode, others would have a quickly patched up build server under their desk. Xcode Bots meets the needs of yet another group of people. Travis CI is good and for open source projects it's probably the best option.

The advanced level of CI would include distributed build systems with multiple build nodes, support for automated unit and UI tests, running tests on physical devices, automatic deployment to TestFlight, Hockey App, Over the Air, and much more. It becomes not just mobile development, but spans into areas like DevOps and others. [Etsy's blog post](https://codeascraft.com/2014/02/28/etsys-journey-to-continuous-integration-for-mobile-apps/) is a good example of where this path can take you.

If you decide to take mobile CI seriously, you have to pick a build server to start with.

I personally have worked with Bamboo for 1.5 years and I'm dealing with Jenkins right now, so I have few insights and can give some comparison of the two.


## Setup & Configuration
[Bamboo installation]({% post_url 2015-02-01-bamboo-ci-server-on-osx %}) and [Jenkins installation]({% post_url 2015-02-01-jenkins-ci-server-on-osx %}) tasks are about the same in terms of time and knowledge required. While installing one of the two you'll climb a certain learning curve which will help you heaps if you ever have to deal with second option.

Both are built using Java, both will need a database setup. Jenkins and Bamboo will setup and configure [MySQL](http://en.wikipedia.org/wiki/MySQL) by default, however, Bamboo will recommend you to configure custom database like [PostgreSQL](http://en.wikipedia.org/wiki/PostgreSQL) for production environment.

Being Java applications both will require similar JVM configuration. Default configuration won't really serve you well. You'll experience out of memory issues as soon as you add a couple of basic build plans/jobs.

And lot's of other things are similar: configuration behind proxy, login vs non-login user ([Launch Agent vs Daemon]({% post_url 2015-02-01-mobile-ci-daemon-vs-agent %})), [OSX Keychain]({% post_url 2015-02-01-mobile-ci--osx-keychain %}), [iOS Simulator]({% post_url 2015-02-01-mobile-ci--ios-simulator %}), etc.

## GUI
Obviously, this is not a comparison criteria at all. This criteria is as subjective as it could possibly be!

Out of the box Bamboo UI looks much better than Jenkins version.

With Jenkins there are ways to improve your day to day user experience. You can customize theme and even make your custom UI improvements, like adding "Build Now" button where you like it.

You should start by installing [Simple Theme Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Simple+Theme+Plugin) and then configure it with one of the available themes. Not all the themes will look good, it all depends on the Jenkins version you have and browser you use, etc. I tried a buch of them and ironically enough the only theme that looks good on our production CI box is called ["Atlassian"](https://github.com/djonsson/jenkins-atlassian-theme). But I'm dealing with slightly outdated Jenkins version, you could get better results with up to date Jenkins.

## Plugins
This is where the large community plays it's role. Subjectively or not, Jenkins has a larger choice of plugins of all kinds, starting from management and organization of build jobs and ending up with reporting.

While Bamboo supports lots of job management features out of the box, reporting plugins is something that needs to be improved.

TODO: take the plugins I use (PMD, Cobertura, Unit Tests, HTML publisher, SLOC)
TODO: note that jenkins shows graphics with trends

And then there is the Mother and the Farther of all Jenkins plugins - [Jenkins Job DSL Plugin](). Short summary: it allows you to manage your configuration as a code.

Check out this good talk and resources (TODO: put more links as a reference) to find out more.

I plan to write a post about my personal experience with using Job DSL plugin.

## Build Job/Plan Structure

There is a bit of confusion caused by terminology used by Bamboo and Jenkins.

### Bamboo

With Bamboo you start by creating Build _Plan_.

Each plan consists of one ore more Build _Stages_. Stages run in **sequential** order. If one stage fails next stages are never executed. Stages can be configured as manual to be triggered by hand.

Stages contain Build _Jobs_. Build jobs in one stage can run in **parallel** if there's enough build agents for that. Each job can require different capabilities and can be dispatched to run on some designated build agent. Build jobs may produce Build _Artefacts_ and share them with other jobs in consequent stages. Since jobs are parallelized, if one of them fails other jobs will still keep running until they finish on their own. This feature can significantly reduce build time, instead of `Build && Test && Analyze && Lint` running 10 minutes, you get `Build || Test || Analyze || Lint` running for 3 minutes (example times).

Finally each job is made of Build _Tasks_. Tasks run in order from top to bottom. A task may be a basic shell script or one of the many tasks provided via plugins. Here's a generalized example of a job and it's tasks. One large and important group of taks is reporting tasks.

- Checkout git repository
- Build
- Test
- Deploy
- Generate test report

A summary of a Build Plan structure

- Build Stage
  - Build Job
    - Task
    - Task
    - [_more tasks_]
  - [_more jobs_]
- [_more stages_]

_Not so Parallel_

Bamboo deserves a special side-note in regards to parallel job execution and iOS build plans.

As I mentioned before, the way you assign build jobs to local or remote agents is via capabilities. An agent defines capabilities it has, a job declares capabilities it wants, and then Bamboo matches the two.

If you are in total control of your CI setup and mobile team is the only one using your particular Bamboo server and all agents, you have all the power to set all the agents capabilities and then enforce a requirement that all build jobs created by you or your teammates must explicitly specify which capabilities they need. This way you'll harness the full power of distributed configuration, all build jobs will run only on the agents they really should run on.

Another situation is when mobile CI is a new addition to company CI setup. There is already a CI server and few dozens of build agents and a lot of other teams using this CI configuration. Lots of teams with lots of plans created over the years.

Now imagine that you are adding your specialized Mac build agent to be used for Xcode builds only. You setup and configure remote Mac agent, connect it to the server and... all the other build plans start jumping on your Mac agent! That's because 99% of those plans declare no capabilities they require, they simply expect that all the agents are identical in terms of capabilities. And that works because all the agents are indeed identical clones. Well _were_ identical clones until a new Mac agent was added.

There's no easy fix to this problem and you can tackle it in one of 2 ways.

_Ideal Solution_

Ideally, CI must be done right. All the build plans must be maintained, updated and removed if no longer needed. As a requirement, all build plans must explicitly declare capabilities they require to be able run. This is something to be enforced at team management level. Company has to have guidelines for creating and managing build plans and there must be a person or even a team (Dev Support team) responsible for keeping guidelines up to date and enforcing them.

_Down to Earth Solution_

The reality is rough. The number of existing plans is overhelming, it will take months to chase people responsible for each build plan and communicate the importance of declaring capabilities to them. The whole change has to be made in a safe way so it doesn't break existing workflows and production deployments.

You don't have months of waiting allocated in your schedule, you need mobile CI running ASAP. One thing you could do is to setup your own CI server just for mobile and essentially move to "under the desk" setup. This way you get no support from Dev Support team (given that you have one) and all the trouble of setting up, configuring and supporting the server and agents is now yours.

However, you still can do mobile CI as part of company wide CI. There is a plugin that will help you - [Bamboo Group Agent plugin]({% post_url 2015-02-01-bamboo-group-agent %}). Have a read if you interested, Group Agent plugin offers a solution which is not fully flexible, but will help with original problem.


### Jenkins

With Jenkins you start by creating Build Project, which is on occasions called _Build Job_ causing certain confusion. In this post I'll stick with Project term.

By default all you get is a basic Freestyle project that includes

- Description
- Parameters
- Build Triggers
- Build Environment
- _Build Steps_
- _Post-build Actions_

If you draw an analogy to Bamboo, then all you get is a build _plan_ with single _stage_ containing single _job_ and list of _tasks_ (Build Steps and Post-build Actions are nothing but tasks). That's it. There are no stages and no way to run anything in parallel.

This is where plugins get into play. [Mutlijob Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Multijob+Plugin) does exactly the same thing as Bamboo. Stages are called _Phases_, phases include _Jobs_. Jobs run in **parallel** when possible, while phases execution order is sequential.

One very important distinction is that jobs in multi job project are actually references to existing build projects.

- Multi Job Build Project
  - Build Phase
    - Build Job 1 --> Build Project 1
    - Build Job 2 --> Build Project 2

In theory you can have a multi job project that includes a job which is a multi job project... You could even unintentionally create build job retain cycles and an infinite build loop.

Multijob Plugin support is added to [Job DSL Plugin](https://github.com/jenkinsci/job-dsl-plugin/wiki/Job-reference#multijob-phase).

Once again with a fair bit of work Jenkins can match Bamboo's default functionality and then with another fair bit of work can surpass it.

Jenkins is still prone to the same problem Bamboo is when it comes to adding iOS build nodes to existing infrastructure. Chances are high your Mac build node will be used by all the other build projects if capabilities are not configured properly. In Jenkins world there are no capabilities as such, instead labels are used. Each build node can be labeled with multiple labels and build jobs can use complex logic expression to specify target nodes they want to run on. But then, if labels were not used in your corporate CI from day one, the amount of work required for labelling existing build projects can be too big. At this moment I am not aware of a Jenkins analogue of Bamboo Group Agent.

## Branch Management

Branches are an essesntial part of any source code management workflow. By supporting branches in CI workflow you get a number of benefits.

_Timely Feedback_

By running CI for each branch you provide developer with earlier feedback on their changes. They will know right away if changes they made are breaking the build, unit or functional tests, introduce static analyzer or linter warnings, etc. Developers can then fix these problems before they create pull request and involve the rest of the team in review process.

_Earlier Tests_

If you have testable build for each branch, you can make it available to your test team automatically as part of continuous delivery process. This way important and critical changes can be tested before they are merged to upstream branch (doesn't mean you don't do integration testing after the merge though). Bugs can be caught earlier and you end up with faster develop-and-test iterations.

Finally, some branches are never destined to be merged upstream. They may contain some experimental feature code, something you still need to build and make available to testers or internal stakeholders. For example have a special build to demo crazy design idea to your UI/UX people.

### Bamboo & Branches

bamboo - does a great job with it's feature to automatically create plan branches
nice support for aging, for permanent branches, for branch name regex, etc.
very good support for upstream and downstream merges (branch updater and branch keeper)
will help to detect merge conflicts earlier
branches are nicely organized in UI
mention the fact about plan dependencies
a child plan branches can be matched up to parent plan branches
and child plan will pick up build artifacts from matching parent plan
etc.

### Jenkins & Branches

jenkins
by default - nothing like that at all
the most popular Git plugin is shaped up for development mode other than mobile
it allows to specify multiple branches but then those will be just merged before the build, that's not having a plan for a branch
alternatives (list 3) are somewhat closer but not quite there anyway
the best of them was multi-job plugin (imho)
but i could not get branch filtering working and had to create plans for all branches
doesn't have branch merging strategies configurable
not much on branch ageing (check)
can't tell much on handling child plans in regards to branches

however, the mentioned before job dsl plugin can take care of it all
with a bit of groovy scripting you can get the branch filtering, aging and the rest
you can nicely organized branch jobs into views and folders and have total control over it
you can generate and upate child plans the way you want it
same goes for branch merging strategies
in many ways, when used right (with a bit of effort though) job dsl plugin does all what bamboo does
and then more

## Pipelines

TODO: work on pipelines, how bamboo does that

https://wiki.jenkins-ci.org/display/JENKINS/Join+Plugin
https://wiki.jenkins-ci.org/display/JENKINS/Promoted+Builds+Plugin


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

_Cloud (aka OnDemand)_? Could be a really good option, but not with industry giants like AWS. AWS or alike is where you'd go if using Bamboo OnDemand feature. I can find posts as old as 2011 discussing this issue: [one](https://answers.atlassian.com/questions/22655/bamboo-mac-agent), [two]((https://jira.atlassian.com/browse/BAM-11870). Apple doesn't make it easy to run virtual OSX instances to the extent that none of the big cloud providers are brave enough to provide official support for this feature. These days you can go with one of the many Mac Mini colocation services. You either rent a Mac hardware or even provide your own.

_Self-hosted_? This is also an option. If your company has security concerns about those Mac hosting providers, or doesn't want to spend money for that, or for any other reason, you can always purchase Mac hardware and host it in your data center.

Whenever you are using self-hosting or remote hosting, you end up dealing with native hardware. I find that Mac Minis with maximized CPU, RAM, and SSD storage are perfect candidates for iOS CI box. The more you have the better.

Next step is to install remote agent/node and get it running. As I mentioned already, installing [remote agent for Bamboo]({% post_url 2015-02-01-bamboo-remote-agent%}) is around the same complexity as installing [remote node for Jenkins]({% post_url 2015-02-01-jenkins-remote-node%}). The problems start popping up when you begin using them.

### Bamboo Remote Agent
Thins you definitely need to know in regards to Bamboo remote agent.

[The rumor has it that] Atlassian are using Mac OSX to develop their products, including Bamboo, but OSX is never ever listed as _officially_ supported. Indeed, why would you choose to run your JIRA, Stash, Bamboo, whatever, on OSX server? Hopefully with increasing demand for iOS CI Atlassian will put a bit higher priority on fixing Bamboo issues for OSX, and there's plenty btw.

Before you even start using remote agent on OSX, you have to experience a bit of pain [when trying to set it up]({% post_url 2015-02-01-bamboo-remote-agent%}).

Major and the most important group of issues is related to **Artefacts Sharing**.

Whenever your remote agent finishes a build stage it is most often producing build artefacts. It _doesn't matter_ if those artefacts are shared or not, they must be copied to the server anyway. That is part of distributed build system. Your remote agent can go offline any time, your build plan jobs can run on different agents with different capabilities and artefacts must be passed from one agent to another. All in all, the reality is - the artefacts must be shared.

**Problem Proxy**

Is your remote agent behind proxy? May I introduce you to [HTTP 1.1 Chunked Transfer Encoding](http://en.wikipedia.org/wiki/Chunked_transfer_encoding) then? Well, not to the feature itself, but how it relates to Bamboo: [BAM-5182](https://jira.atlassian.com/browse/BAM-5182), [more](https://confluence.atlassian.com/pages/viewpage.action?pageId=420971598).

Bamboo server requires support of HTTP chunked transfer feature of 1.1 protocol version to pick up artefacts. If your proxy doesn't support this feature, you are in trouble. Strictly speaking, this is not Bamboo's problem, this is the problem of your company network team. HTTP 1.1 standard was released in [1999](http://www.w3.org/Protocols/rfc2616/rfc2616.html)! There is a lot of http proxy implementations that support it, [nginx](http://nginx.org/en/) for example. However, things move really slow in most of big companies when it comes to changing network infrastructure. If you are so unlucky and you company is still stuck around 1999 in terms of network infrastructure, you will most likely have to find a work-around rather than waiting months and months before you get any progress on proxy upgrade.

**Problem Atlassian**

But wait then! Too early to take all the blame off the Atlassian's shoulders!

First of all, Bamboo remote agent JAR [totally disrespects JVM flags for http proxy whitelist (nonProxyHosts)](https://answers.atlassian.com/questions/75941/remote-agent-not-honoring-the-dhttp-nonproxyhosts-parameter), [upvote!](https://jira.atlassian.com/browse/BAM-12041) You can find ways around this issue, for example re-routing network calls using tools like [SquidMan](http://squidman.net/squidman/), but then you will face *The Final Blocker*: [BAM!](https://jira.atlassian.com/browse/BAM-8111), [BAM!](https://jira.atlassian.com/browse/BAM-8226).

Yes, Bamboo remote agent [is 27 (_twenty seven!_) times slower than plain scp](https://jira.atlassian.com/browse/BAM-8111?focusedCommentId=622466&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-622466) ([secure copy over ssh](http://en.wikipedia.org/wiki/Secure_copy)) command when it comes to copying a single `.zip` file which is around few hundred Mb of size.

Imagine that after spending all the time trying to figure out issues around your proxy and enable the agent to share artefacts with the server you end up facing this beast? It renders all your distributed build setup useless, it takes way more time to copy build artefacts than to produce them. From reports it looks like this issue is specific for Mac OS build agents only.

When I faced this problem I ended up sharing artefacts via Amazon S3 bucket. This is extra work, extra shell scripts to upload and download artefacts, additional expenses for S3 bucket. You become responsible for managing outdated artefacts, you are the one who has to account for multiple build plan branches, and much more. This is really a bit too much of overhead and it is extra annoying when you know this is a core Bamboo functionality and it's **supposed to work right out of the box**.

### Jenkins Remote Node

TODO:
