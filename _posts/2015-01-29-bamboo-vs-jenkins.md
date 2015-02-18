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

If you decide to take mobile CI under your total control, you have to pick a build server to start with.

I personally have worked with Bamboo for 1.5 years and I'm dealing with Jenkins right now, so I have few insights and can give some comparison of the two.


## Setup & Configuration
[Bamboo installation]({% post_url 2015-02-01-bamboo-ci-server-on-osx %}) and [Jenkins installation]({% post_url 2015-02-01-jenkins-ci-server-on-osx %}) tasks are about the same in terms of time and knowledge required. While installing one of the two you'll climb a certain learning curve which will help you heaps if you ever have to deal with second option.

Both are built using Java, both will need a database setup. Jenkins and Bamboo will setup and configure [MySQL](http://en.wikipedia.org/wiki/MySQL) by default. Bamboo, however, will recommend you to configure custom database like [PostgreSQL](http://en.wikipedia.org/wiki/PostgreSQL) for production environment.

Being Java applications both will require similar JVM configuration. Default configuration won't really serve you well. You'll experience out of memory issues as soon as you add a couple of basic build plans/projects.

And lot's of other things are similar: configuration behind proxy, login vs non-login user ([Launch Agent vs Daemon]({% post_url 2015-02-01-mobile-ci-daemon-vs-agent %})), [OS X Keychain]({% post_url 2015-02-01-mobile-ci--osx-keychain %}), [iOS Simulator]({% post_url 2015-02-01-mobile-ci--ios-simulator %}), etc.

## GUI
Obviously, this is not a comparison criteria at all. This criteria is as subjective as it could possibly be!

Out of the box Bamboo UI looks much better than Jenkins version.

With Jenkins there are ways to improve your day to day user experience. You can customize theme and even make your custom UI improvements, like adding "Build Now" button where you like it.

You should start by installing [Simple Theme Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Simple+Theme+Plugin) and then configure it with one of the available themes. Not all the themes will look good, it all depends on the Jenkins version you have and browser you use, etc. I tried a bunch of them and ironically enough the only theme that looks good on our production CI box is called ["Atlassian"](https://github.com/djonsson/jenkins-atlassian-theme). But I'm dealing with slightly outdated Jenkins version, you could get better results with up to date Jenkins.

There's multitude of [UI, List View and Page Decorator plugins](https://wiki.jenkins-ci.org/display/JENKINS/Plugins) available for Jenikns. Some of them must be good and help you customize you Jenkins look & feel and functionality.

## Plugins
This is where the large community plays it's role. Subjectively or not, Jenkins has a larger choice of plugins of all kinds, starting from management and organization of build jobs and ending up with reporting.

Via a fancy pie chart diagram we are told that Bamboo has **151** plugins on [Atlassian Marketplace](https://marketplace.atlassian.com/home/jira).

![Plugins Pie Chart]({{ site.url }}/assets/images/atlassian-marketplace-plugins.png)

A quick check on [Jenkins Wiki](https://wiki.jenkins-ci.org/display/JENKINS/Plugins?showChildren=true#children) and we get a count of **1,071** plugins.

Reporting is one of the most important plugin categories in my opinion. For example, I prefer to have full control over Xcode build tasks and use [makefiles]({% post_url 2015-02-08-mobile-ci---makefiles %}) combined with shell commands wrapping `xcodebuild` rather than use Xcode plugin. Part of the reason is to be able to migrate to another build server with less effort and to be able to run CI tasks on my development laptop. Same goes for other things like uploading to / downloading from S3 bucket, transferring files with rsync or scp, and so on. But in no way I can come up with scripts that will produce good looking reports including HTML formatting, diagrams and images plus integration into Bamboo or Jenkins UI. For this task I prefer to use plugins.

Jenkins features **127** plugins just for reporting, that's almost as much as Bamboo can offer in total. Of course, quality of all those plugins deserves a detailed research. Just numbers don't tell much. But this post _is_ based on some hands on experience, so I'll compare some reporting plugins I have used over time.

_Publish HTML_

If you ever used [Clang Static Analyzer]({% post_url 2015-02-08-clang-static-analyzer %}) for your iOS projects, you know then that there's no proper reporting plugin for this task. You end up with HTML report that needs to be published and made available in build project/plan summary.

With Bamboo you create a new [Shared Artifact](https://confluence.atlassian.com/display/BAMBOO/Sharing+artifacts), with Jenkins you use [HTML Publisher plugin](https://wiki.jenkins-ci.org/display/JENKINS/HTML+Publisher+Plugin).

_Unit Tests_

Of course you run [unit tests]({% post_url 2015-02-08-mobile-ci---unit-tests %}) as part of your CI, don't you? In that case you are well covered by reporting plugin on both Bamboo and Jenkins. Jenkins plugin also includes trending graphs, which is nice.

_Cobertura Code Coverage_

Of course you don't just run unit tests, but also [gather code coverage data]({% post_url 2015-02-08-code-coverage-for-ios %}), don't you?

This is the first time Bamboo falls one plugin short. You can [check related discussion](https://jira.atlassian.com/browse/BAM-13180) for more details.

Jenkins has your back on this one with [Cobertura Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Cobertura+Plugin). You can configure custom threshold values to mark builds as failed if you tests don't provide enough coverage.

_Static Analyzers Reports_

[OCLint]({% post_url 2015-02-08-oclint %}) is amazing tool to run another round of static analysis on your code and detect vast number of issues as well as to enforce coding guidelines. OCLint can produce output compatible with [PMD](http://pmd.sourceforge.net/) output format. So it can then be processed by [Jenkins PMD Plugin](https://wiki.jenkins-ci.org/display/JENKINS/PMD+Plugin). You end up with browsable report with issues grouped by priority, category and other criteria. You can navigate all the way down to the line of code causing the warning. Once again, you can configure threshold values to mark builds with lots of warnings as failed.

In fact, the same reporting plugin should be able to pick up output of Clang Static Analyzer which I mentioned before. However I couldn't figure out the way to make Clang Static Analyzer to spit out correct XML file.

With Bamboo, unfortunately, all you have is publishing HTML report via shared artifact.

P.S. I'm a big fan of Swift programming language, but one thing makes me a bit sad. It will take some time before we get tools like OCLint available for Swift.

_Warnings_

If you run CI tasks such as build, test, analyze and lint, often you don't want you build project/plan to stop immediately if it encounters an error, for example test error. You still want your reporting tasks to run and pick up those errors and generate reports for them. This often leads to a problem where you have compilation error but the build is marked as passing. Preferred way to avoid this issue is to have a reporting task which will pick up all the errors and mark build as failed if needed.

Jenkins has [Warnings plugin](https://wiki.jenkins-ci.org/display/JENKINS/Warnings+Plugin) for that. It will scan build logs and detect warnings and errors generated by compiler, and it includes support for clang so xcodebuild is well covered. All you need is to configure thresholds and fail builds if there were compile errors. Supported by Job DSL as well.

I don't know about Bamboo plugin to do the same job. I remember myself few months ago grepping test logs for errors and then marking builds as failed by doing something like `exit 1`.

_Functional Tests_

If you happen to use frameworks like [Calabash](http://calaba.sh/) that produce [Cucumber](https://cukes.info/) test reports, then Both CI servers have plugins to provide nice reports.

_Higher-order Plugins_

Forgive me this injection of so popular these days functional slang, but this is how I want to introduce The Mother and The Father of all Jenkins plugins - [Jenkins Job DSL Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Job+DSL+Plugin). In short, it allows you to manage your configuration as a code and to generate and update build projects from code. What could be better for a developer?

Check out these resources to find out more.

- [Netflix Talk Video](https://www.youtube.com/watch?v=FeSKrBvT72c)
- [Netflix Talk Slides](http://www.slideshare.net/quidryan/configuration-as-code)
- [Jenkins Wiki](https://wiki.jenkins-ci.org/display/JENKINS/Job+DSL+Plugin)
- [Job DSL Job Reference](https://github.com/jenkinsci/job-dsl-plugin/wiki/Job-reference)
- [Job DSL Commands](https://github.com/jenkinsci/job-dsl-plugin/wiki/Job-DSL-Commands)
- [User Power Moves](https://github.com/jenkinsci/job-dsl-plugin/wiki/User-Power-Moves)
- [Real World Examples](https://github.com/jenkinsci/job-dsl-plugin/wiki/Real-World-Examples)

I plan to write a post about my personal experience with using Job DSL plugin.

Jenkins Job DSL plugin was a game changer for me personally. When I started working at new place a while ago, I had year and a half experience with Bamboo and acted as a strong Bamboo advocate initially. Until the moment I discovered unlimited power of Job DSL plugin. I personally can't imagine going back to Bamboo and dealing with UI to update dozens of similar plans by hand.

That said, I still like Bamboo very much, particurarly the way it integrates with the rest of Atlassian products. I hope Atlassian will implement Build Plan DSL plugin or provide API to make it happen. [Bamboo Trade Depot Plugin](https://marketplace.atlassian.com/plugins/com.carolynvs.trade_depot) is the only thing that _could_ match Job DSL plugin, but unfortunatelly it's not even close.

## Build Plan/Project Structure

There is a bit of confusion caused by terminology used by Bamboo and Jenkins.

### Bamboo

With Bamboo you start by creating Build _Plan_.

Each plan consists of one ore more Build _Stages_. Stages run in **sequential** order. If one stage fails next stages are never executed. Stages can be configured as manual to be triggered by hand.

Stages contain Build _Jobs_. Build jobs in one stage can run in **parallel** if there's enough build agents for that. Each job can require different capabilities and can be dispatched to run on some designated build agent. Build jobs may produce Build _Artifacts_ and share them with other jobs in consequent stages. Since jobs are parallelized, if one of them fails other jobs will still keep running until they finish on their own. This feature can significantly reduce build time, instead of sequential `Build ⟼ Test ⟼ Analyze ⟼ Lint` running 10 minutes, you get parallel `Build || Test || Analyze || Lint` running for about 3 minutes (given that longest job takes around 3 minutes).

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

_Not So Parallel_

Bamboo deserves a special side-note in regards to parallel job execution and iOS build plans.

As I mentioned before, the way you assign build jobs to local or remote agents is via capabilities. An agent defines capabilities it has, a job declares capabilities it wants, and then Bamboo matches the two.

If you are in total control of your CI setup and mobile team is the only one using your particular Bamboo server and all agents, you have all the power to set all the agents capabilities and then enforce a requirement that all build jobs created by you or your teammates must explicitly specify which capabilities they need. This way you'll harness the full power of distributed configuration, all build jobs will run only on the agents they really should run on.

Another situation is when mobile CI is a new addition to company CI setup. There is already a CI server and few dozens of build agents and a lot of other teams using this CI configuration. Lots of teams with lots of plans created over the years.

Now imagine that you are adding your specialized Mac build agent to be used for Xcode builds only. You setup and configure remote Mac agent, connect it to the server and... all the other build plans start jumping on your Mac agent! That's because 99% of those plans declare no capabilities they require, they simply expect that all the agents are identical in terms of capabilities. And that works because all the agents are indeed identical clones. Well _were_ identical clones until a new Mac agent was added.

There's no easy fix to this problem and you can tackle it in one of 2 ways.

_Ideal Solution_

Ideally, CI must be done right. All the build plans must be maintained, updated and removed if no longer needed. As a requirement, all build plans must explicitly declare capabilities they require to be able to run. This is something to be enforced at team management level. Company has to have guidelines for creating and managing build plans and there must be a person or even a team (Dev Support team) responsible for keeping guidelines up to date and enforcing them.

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
    - Build Job 1 ⇢ Build Project 1
    - Build Job 2 ⇢ Build Project 2

In theory you can have a multi job project that includes a job which is a multi job project... You could even unintentionally create build job retain cycles and an infinite build loop.

To satisfy your craving for code Multijob Plugin support is added to [Job DSL Plugin](https://github.com/jenkinsci/job-dsl-plugin/wiki/Job-reference#multijob-phase).

Once again with a fair bit of work Jenkins can match Bamboo's default functionality and then with another fair bit of work can surpass it.

I mentioned artifact sharing briefly for Bamboo. For Mutlijob plugin there is no proper artifact sharing support yet. There's a number of open tickets ([JENKINS-20241](https://issues.jenkins-ci.org/browse/JENKINS-20241), [JENKINS-25111](https://issues.jenkins-ci.org/browse/JENKINS-25111), [JENKINS-16847](https://issues.jenkins-ci.org/browse/JENKINS-16847), [JENKINS-16847](https://issues.jenkins-ci.org/browse/JENKINS-16847)) with workarounds available. So the problem can be solved by it's not part of official Jenkins release yet.

_Not So Parallel Either_

Jenkins is still prone to the same problem Bamboo is when it comes to adding iOS build nodes to existing infrastructure. Chances are high your Mac build node will be used by all the other build projects if capabilities are not configured properly.

Actually, in Jenkins world there are no capabilities as such, instead labels are used. Semantics are a bit different, but they serve the same purpose after all. Each build node can be labeled with multiple labels and build jobs can use flexible logical expressions to specify target nodes they want to run on. But then, if labels were not used in your corporate CI from day one, the amount of work required for labelling existing build projects can be too big.

At this moment I am not aware of a Jenkins analogue of Bamboo Group Agent.

## Branch Management

Branches are an essesntial part of any source code management workflow. By supporting branches in CI workflow you get a number of benefits.

_Timely Feedback_

By running CI for each branch you provide developer with earlier feedback on their changes. They will know right away if changes they made are breaking the build, unit or functional tests, introduce static analyzer or linter warnings, etc. Developers can then fix these problems before they create pull request and involve the rest of the team in review process.

_Earlier Tests_

If you have testable build for each branch, you can make it available to your test team automatically as part of continuous delivery process. This way important and critical changes can be tested before they are merged to upstream branch (doesn't mean you don't do integration testing after the merge though). Bugs can be caught earlier and you end up with faster develop-and-test iterations.

Finally, some branches are never destined to be merged upstream. They may contain some experimental feature code, something you still need to build and make available to testers or internal stakeholders. For example have a special build to demo crazy design idea to your UI/UX people.

_Branch Naming_

I had to mention branch naming in a separate paragraph. For some reason yet unknown to me, when it comes to naming a branch developers get completely wild. What I mean is that within the same team you can see branch names with and without prefix, using dashes or camel case, dashes _and_ camel case combined, underscores... just anything. Sometimes the same developer would be very inconsistent when naming their branches. The very same developers are very disciplined when it comes to coding, i.e. class, variable and method names, and following coding styleguide in general.

The upshot is that you have to have branch naming guidelines in your team, e.g. as a part of Git (other SCM) workflow. If the whole "issue" doesn't look like an issue to you, wait until you have to manage this branchy havoc in regards to CI.

### Bamboo & Branches

Bamboo does a great job with branches. With a single tick of a checkbox you can create branches of a build plan. By the way, you did understand it correctly, you _create a **branch of a** build plan_. Essentially, Bamboo clones the original build plan and changes its source repository configuration to point to a different branch. These plans still share same build phases, jobs and tasks, but you can configure some of the branch plan settings differently, that includes notifications, branch merging strategies, etc.

With a standard [Java regular expression](http://docs.oracle.com/javase/tutorial/essential/regex/) you can filter branches by their name and instruct Bamboo to ignore branch names that don't follow guidelines.  For example, the regex below will accept only `master` and `development` branches, and branches that are prefixed with `bugfix/`, `hotfix/` or `feature/` followed by JIRA issue ID and lowercase-with-dashes description.

{% highlight java %}
master|development|((bugfix/|hotfix/|feature/)\w{2,}-\d+(-[\da-z]*)*)
{% endhighlight %}

A good Java regex test website is [RegexPlanet](http://www.regexplanet.com/advanced/java/index.html).

This is a perfect way to indirectly enforce correct branch naming. After missing couple of builds developers will figure out what's wrong and change their habits. In certain situations you can awlays add a branch manually via Bamboo UI or [CLI tools]({% post_url 2014-05-29-atlassian-cli %}).

With another simple configuration field you can control ageing of the branches. If branch hasn't been updated for a long time, Bamboo will remove its build plan. Of course you'd want to preserve certain branches forever and there's yet another checkbox to do that.

I've mentioned branch merging strategies and that's one more feature that Bamboo provides out of the box. Usgin [Branch Updater](https://confluence.atlassian.com/display/BAMBOO/Using+plan+branches#Usingplanbranches-Branchupdater) or [Gatekeeper](https://confluence.atlassian.com/display/BAMBOO/Using+plan+branches#Usingplanbranches-Gatekeeper) you can configure build plan to do upstream merge before or downstream merge after running the build. This is a very good way to detect merge conflicts earlier and to keep your git workflow in order.

Bamboo's branches support also shines when it comes to CI pipelines, more on that later in the post.


### Jenkins & Branches

Surprisingly, plugins initially do more harm than good in this case.

On fresh setup Jenkins has no Git support (SCM I get to work with and thus choosing it as an example). You need to install plugin to work with Git and you will most likely install [the most popular Git plugin](https://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin).
This plugin is very powerful but of all the things it does not create branches for build projects. Well to be honest it shouldn't.

When you look for a solution you will think of trying some other plugins first. Thre are a few: [Multi-Branch Project](https://wiki.jenkins-ci.org/display/JENKINS/Multi-Branch+Project+Plugin), [Feature Branch Notifier](https://wiki.jenkins-ci.org/display/JENKINS/Feature+Branch+Notifier+Plugin) and others. The common problem with all of them is that they have their own support for SCMs including Git, that means you don't get to use the Git Plugin and all of its powerful features, instead you end up with a very limited version of it.

I tried Multi-Branch Project plugin, it was OK, but not good enough. I couldn't get branch filtering to work, it kept picking up all the branches ignoring filters. There's no option to configure branch ageing, no branch merging strategies and so on. Finally, no simple and easy support for branched CI pipelines.

This is what I meant by _harm_ in this case. You spend time trying different plugins and none of them would match Bamboo default functionality.

But all is not lost. Once again you will be saved by Job DSL plugin. Paired with Git Plugin it can work miracles. While Git Plugin can't branch build projects it can work with branches as such. With one line of Groovy code you can fetch all the branches for your repository including information on their last update. Then with simple string regex match and date comparison you can filter branches just like Bamboo does, and then you can generate build project, organize them into folders and views to match Bamboo's UI. Code a bit to generate branch pipelines, same for merging strategies and much more.

[Follow this link](https://github.com/jenkinsci/job-dsl-plugin/wiki/Real-World-Examples) to find an example of getting branches for GitHub repository.

If you are using Stash there is no direct support for it via Jenkins plugins afaik. But as long as you have API access you can follow [Bitbucket example]({% post_url 2015-02-08-bitbucket-branches--job-dsl %}) to have basic support for working with branches. If you don't feel like coding too much, you can wrap [some shell scripts]({% post_url 2014-05-29-atlassian-cli %}) in thin layer of Groovy code to get same results.

Yes it takes time and learning to get used to Job DSL plugin, but the benefits are unmeasurable.

## Pipelines

Pipelines is another name for CI/CD workflows. In certain cases single build plan/project is not enough, and that's when you can create pipelines. Creating a pipeline means you chain build plans together, if first plan (aka _parent_) is successful it triggers its _child_ plans. Child plans can have children of their own, and so on.

{% highlight bash %}
.
└── Parent Plan
    ├── Child Plan 1
    │   ├── Grandchild Plan 1.1
    │   └── Grandchild Plan 1.2
    ├── Child Plan 2
    └── [more children]
{% endhighlight %}

A real world example of pipelines for Mobile space is UI automation tests, often called Functional or Acceptance testing. UI automation is usually a heavyweight task compared to unit tests. If you run UI automation tests as part of a single build plan it can take too long to complete.

You can create a separate plan for UI automation only, but then you don't want to trigger it every time there is a commit to SCM. There's no point running UI automation tests if the build fails. So you add UI automation tests plan as a child plan to the main build plan thus creating pipeline.

This is just one example.

### Bamboo Pipelines

Bamboo has support for pipelines out of the box. In parent plan configuration you simply add child plans and configure the way those are triggered, e.g. only when parent is successful.

Child plans don't have to be configured in any special way, they are completely unaware of being some other plan's children by default. The very same plan can be included in multiple pipelines acting in a different role.

The real power of Bamboo pipelines is in its support for branches. Child plan will only be triggered if it has the same branch as the parent plan. This means you have to configure branching for both plans to make it work. Normally this also means that both plans are using same repository, but it is not a mandatory requirement. If 2 different repositories have the same branch the feature will work all the same.

When child plan starts it can get artifacts from the parent via Artifact Downloader task. Yet again, the branch of the child plan gets artifacts from the matching branch of the parent plan, all is handled by Bamboo.


### Jenkins Pipelines

Jenkins has no pipelines support by default. As usual plugins should be used.

This is something I'm only starting to work with, so this paragraph doesn't have lots of details.

In general, Jenkins plugins let you match Bamboo functionality with a certain amount of work.

Most popular plugins used for pipelines are

- [Join Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Join+Plugin)
- [Promoted Build Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Promoted+Builds+Plugin)

Both are supported by Job DSL allowing you to script complex pipelines in code and change them easily.


## Distributed Builds
Both Bamboo and Jenkins have support for distributed builds. Bamboo is using [Remote Agents](https://confluence.atlassian.com/display/BAMBOO/Bamboo+remote+agent+installation+guide) while Jenkins calls them [Remote Nodes](https://wiki.jenkins-ci.org/display/JENKINS/Distributed+builds ), sometimes referred as slave nodes or agents.

A side note - both servers support local build agents/nodes as well. Those are running locally (as the name suggests) on the same hardware as the build server.

Back to remote agents/nodes. Complexity of setting them up and configuring doesn't vary much between the two CI servers.

Both will suffer from issues caused by sitting behind the company proxy, specifically if the server is located somewhere outside your company network (e.g. in AWS cloud).

Why the server is in the cloud and the agent/node is not? - you'd ask. Well, that takes us to next topic.

## Mac Support
Right, this whole comparison is focusing on Mobile CI after all, meaning you have to deal with one of the most popular mobile platforms these days - that is iOS.

To build an iOS app you must have Xcode, which can run only on OS X (unless you want to follow the path of certain insanity and make it work on other OS).

_Hackintosh_

Not a very good idea I'd say. The company does iOS development and wants to go with Hackintosh to setup OS X build server. Really?

_Cloud (aka OnDemand)_

Could be a really good option, but not with industry giants like AWS. AWS or alike is where you'd go if using Bamboo OnDemand feature. I can find posts as old as 2011 discussing this issue: [one](https://answers.atlassian.com/questions/22655/bamboo-mac-agent), [two](https://jira.atlassian.com/browse/BAM-11870). Apple doesn't make it easy to run virtual OS X instances to the extent that none of the big cloud providers are brave enough to provide official support for this feature. These days you can go with one of the many Mac Mini colocation services. You either rent a Mac hardware or even provide your own.

_Self-hosted_

This is also an option. If your company has security concerns about those Mac hosting providers, or doesn't want to spend money for that, or for any other reason, you can always purchase Mac hardware and host it in your data center.

Whenever you are using self-hosting or remote hosting, you end up dealing with native hardware. I find that Mac Minis with maximized CPU, RAM, and SSD storage are perfect candidates for iOS CI box. The more you have the better.

Next step is to install remote agent/node and get it running. As I mentioned already, installing [remote agent for Bamboo]({% post_url 2015-02-01-bamboo-remote-agent%}) is around the same complexity as installing [remote node for Jenkins]({% post_url 2015-02-01-jenkins-remote-node%}). The problems start popping up when you begin using them.

### Bamboo Remote Agent
Things you definitely need to know in regards to Bamboo remote agent.

[The rumor has it that] Atlassian are using Mac OS X to develop their products, including Bamboo, but OS X is never ever listed as _officially_ supported. Indeed, why would you choose to run your JIRA, Stash, Bamboo, whatever, on OS X server? Hopefully with increasing demand for iOS CI Atlassian will put a bit higher priority on fixing Bamboo issues for OS X, and there's plenty btw.

Before you even start using remote agent on OS X, you have to experience a bit of pain [when trying to set it up]({% post_url 2015-02-01-bamboo-remote-agent%}).

Major and the most important group of issues is related to **Artifacts Sharing**.

Whenever your remote agent finishes a build stage it is most often producing build artifacts. It _doesn't matter_ if those artifacts are shared or not, they must be copied to the server anyway. That is part of distributed build system. Your remote agent can go offline any time, your build plan jobs can run on different agents with different capabilities and artifacts must be passed from one agent to another. All in all, the reality is - the artifacts must be shared.

**Problem Proxy**

Is your remote agent behind proxy? May I introduce you to [HTTP 1.1 Chunked Transfer Encoding](http://en.wikipedia.org/wiki/Chunked_transfer_encoding) then? Well, not to the feature itself, but how it relates to Bamboo: [BAM-5182](https://jira.atlassian.com/browse/BAM-5182), [more](https://confluence.atlassian.com/pages/viewpage.action?pageId=420971598).

Bamboo server requires support of HTTP chunked transfer feature of 1.1 protocol version to pick up artifacts. If your proxy doesn't support this feature, you are in trouble. Strictly speaking, this is not Bamboo's problem, this is the problem of your company network team. HTTP 1.1 standard was released in [1999](http://www.w3.org/Protocols/rfc2616/rfc2616.html)! There is a lot of HTTP proxy implementations that support it, [nginx](http://nginx.org/en/) for example. However, things move really slow in most of big companies when it comes to changing network infrastructure. If you are so unlucky and you company is still stuck around 1999 in terms of network infrastructure, you will most likely have to find a work-around rather than waiting months and months before you get any progress on proxy upgrade.

**Problem Atlassian**

But wait then! Too early to take all the blame off the Atlassian's shoulders!

First of all, Bamboo remote agent JAR [totally disrespects JVM flags for HTTP proxy whitelist (nonProxyHosts)](https://answers.atlassian.com/questions/75941/remote-agent-not-honoring-the-dhttp-nonproxyhosts-parameter), [upvote!](https://jira.atlassian.com/browse/BAM-12041) You can find ways around this issue, for example re-routing network calls using tools like [SquidMan](http://squidman.net/squidman/), but then you will face *The Final Blocker*: [BAM!](https://jira.atlassian.com/browse/BAM-8111), [BAM!](https://jira.atlassian.com/browse/BAM-8226).

Yes, Bamboo remote agent [is 27 (_twenty seven!_) times slower than plain scp](https://jira.atlassian.com/browse/BAM-8111?focusedCommentId=622466&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-622466) ([secure copy over ssh](http://en.wikipedia.org/wiki/Secure_copy)) command when it comes to copying a single `.zip` file which is around few hundred Mb of size.

Imagine that after spending all the time trying to figure out issues around your proxy and enable the agent to share artifacts with the server you end up facing this beast? It renders all your distributed build setup useless, it takes way more time to copy build artifacts than to produce them. From reports it looks like this issue is specific for Mac OS build agents only.

When I faced this problem I ended up sharing artifacts via Amazon S3 bucket. This is extra work, extra shell scripts to upload and download artifacts, additional expenses for S3 bucket. You become responsible for managing outdated artifacts, you are the one who has to account for multiple build plan branches, and much more. This is really a bit too much of overhead and it is extra annoying when you know this is a core Bamboo functionality and it's **supposed to work right out of the box**.

### Jenkins Remote Node

Read the [Jenkins Remote Node installation post]({% post_url 2015-02-01-jenkins-remote-node %}) to get initial overview.

As you can see, there are common problems related to running SSH sessions as non-login user and others. I personally ended up running remote node as OS X Launch Daemon. This works, but is not ideal.

I have nothing yet to say about artifact copy speed from slave to master in regards to Jenkins setup, but stay tuned and/or post a comment if you have any knowledge on the matter.

## Android

I wanted to mention Android in this last section, after all it's Mobile too.

I wrote one post about building Android - [Build Android in The Cloud]({% post_url 2014-05-29-build-android-in-the-cloud %}) which already provides some details.

In regards to Bamboo vs Jenkins comparison, almost everything I mentioned for iOS applies to Android, except the very big and troublesome Mac OS X part. You can, and you should build Android on Linux systems, and that's exactly what AWS instances are running on! It means that if you have 25 build agents/nodes in the cloud, all 25 of them can be used to build Android projects.

I had experience with building Android projects and running Calabash UI Automation tests using Bamboo OnDemand setup hosted in AWS cloud. It worked (and what I was last told it still works) flawless and scalability of AWS really pays back. Despite the fact that building Android project was way more slower than building similar iOS project, that wasn't really a concern given the number of resources available to do the job.

## Summary

Despite my excitement with Jenkins Job DSL plugin there's no clear winner for me.

Both solutions can be used for enterprise level mobile CI. Both can be used in pure UI-driven way while Jenkins also offers a code-driven approach with certain trade-offs.

I'd say, whichever server you use, whatever your CI requirements are, just make sure you take it seriously. In some ways it's a call to help Mobile CI to get out of its teen years.
