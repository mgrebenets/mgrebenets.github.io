---
layout: post
title: "Bamboo Group Agent"
description: "Bamboo Group Agent"
category: Mobile CI
tags: [mobile, ci, bamboo, atlassian, ios]
---
{% include JB/setup %}

Bamboo Group Agent plugin for Mac agents.

<!--more-->

[Bamboo Group Agent](https://marketplace.atlassian.com/plugins/com.edwardawebb.bamboo-group-agent) is a free plugin for Atlassian's Bamboo CI server. Like most plugins Bamboo Group Agent plugin is designed to solve a particular problem.

# Problem

Consider a distributed CI setup, for example [Bamboo Cloud](https://confluence.atlassian.com/display/Cloud/Bamboo+Cloud). The server runs in EC2 Amazon together with a number of [Elastic Agents](https://confluence.atlassian.com/display/BAMBOO/About+Elastic+Bamboo). Your goal is to add [Mac remote build agents]({% post_url 2015-02-01-bamboo-remote-agent %}) to this CI setup.

First of all, there's no way to have a virtual Mac agent in the cloud, not with Amazon at least. You either have to choose one of the Mac colocation providers or have a self-hosted Mac box for an agent. This is only half of the problem though. The other half is the way CI is usually configured.

Due to the nature of CI server and elastic agents setup, all elastic agents are usually identical clones of each other. With a few clicks of a mouse you can go from 1 to 25 agents, all of them initializing from the same image and having same specs from the start. As part of agents initialization, tools and software packages are installed as well, e.g. Git, RVM, npm, and so on. Those are normally called _capabilities_ in Bamboo terms. The purpose of capabilities is to have more granular control over build jobs. The job specifies capability it needs to run, agents declare capabilities they have, and then Bamboo matches jobs to agents. The real issue is that such a powerful mechanism is usually **not** used. Since all the agents are identical, developers create their build plans with that in mind and thus they specify **no capabilities** in their build plans, because all the agents are capable of running their build jobs. This means the jobs can start on **any** agent.

This setup works until the moment you need to have a special agent with special capabilities, e.g. Mac agent with `xcodebuild` capability. You will usually have just one of those and it will be a very valuable resource used to build all the iOS projects in your team or even company. As you might have guessed, as soon as you add Mac agent to the agents pool *all* the other plans will start jumping on this agent and bear in mind that there are dozens if not hundreds of those plans. That's the drawback of ignoring capabilities.

The problem is identified, so what's with the solution? Going though the agents and declaring capabilities will not help, because all the plans need to specify capabilities as well.

# Fix The Plans

Fixing the plans by specifying capabilities is the right solution. Unfortunately it is often a hard solution. Depending on your company you may have dozens if not hundreds of build plans, created by different developers in different periods of time. It's a hell of a task just to track responsible people if you ever find anyone. Then you'd have to explain why it is important to specify capabilities and so on. It may take months before changes are applied and you don't have months, you need Mac agents up and running right now.

This leads you to using a workaround which is...

# Bamboo Group Agent

Allow me some copy-paste here.

> Marking an agent as a "Group Agent" will prevent any Build Plans from using it, regardless of capabilities. Plans must request agent specifically.

Let's see how this applies to our Mac agent. Start by installing Group Agent plugin from Marketplace. You will have to restart Bamboo server to apply changes.

## Configure Group Agent

Next you need to configure the agent. In this example I will use remote agent running on the same machine. Navigate to Bamboo Administration, then select Agents and select remote agent from the list.

![Select Remote Agent]({{ site.url }}/assets/images/bamboo-configure-group-agent-list-agents.png)

Then click "Add capability".

![Select Add Capability]({{ site.url }}/assets/images/bamboo-group-agent-add-capability.png)

Select "Group Agent" capability from drop-down list. Ignore "Allow Deployments" option for now, I will give more details on it later. Now you can click "Add".

![Select Group Agent Capability]({{ site.url }}/assets/images/bamboo-select-group-agent-capability.png)

To verify results, find Group Agent capability in the list and click "Edit" (this option will give you a bit more info than just "View").

![Group Agent Duty]({{ site.url }}/assets/images/bamboo-group-agent-duty.png)

![Edit Group Agent Capability]({{ site.url }}/assets/images/babmoo-edit-group-agent-capability.png)

Everything looks fine except for one thing, the agent name. Right now it's the IP address, which makes it a bit tedious to remember and use in settings. It's a good time to change this now. Click on the agent name link, then click "Edit details" button.

![Rename Agent]({{ site.url }}/assets/images/bamboo-rename-remote-agent.png)

## Use Group Agent

Now create or select a build plan you want to assign to the Group Agent. Then select `Actions > Configure plan`.

![Configure Plan]({{ site.url }}/assets/images/bamboo-actions-configure-plan.png)

Next select "Miscellaneous" tab and tick "This plan requires a Group Agent" checkbox.

![Specify Group Agent]({{ site.url }}/assets/images/bamboo-specify-group-agent.png)

Note, that you are using agent name here and you can specify more than one agent, by providing a comma separated list of agent names, for example "Mac Agent 1, Mac Agent 2, Mac Agent 3".

That's it, this plan will now run _only_ on _Mac Agent 1_ and **no other plans** will run on this agent or any group agents you configure in the future.

# Drawbacks

The benefit of using Bamboo Group Agent is that it solves original problem described in this article. However, this approach has a number of drawbacks you need to know about.

## Lock Entire Plan

First drawback is that by using Group Agent you lock the _entire_ plan to be executed on certain group of agents only. _Entire_ means the plan and all of its jobs will run on a single agent at a time, that means jobs can't run in parallel and you can't take advantage of this awesome feature. Another issue is that your typical iOS build plan will have only few jobs that actually need Mac OS X (`xcodebuild`), the rest will be tasks to upload builds for distribution, to generate reports, to update issue trackers and so on. Ideally all those tasks could be ran on other agents thus freeing up Mac agent for next `xcodebuild` job, but that's something that can't be done with Group Agent.

The reason for this is not plugin developer's fault. Actual reason is the lack of flexibility of APIs provided by Atlassian in their plugin development SDK. Group Agent uses [BuildAgentRequirementFilter](https://docs.atlassian.com/atlassian-bamboo/latest/com/atlassian/bamboo/v2/build/agent/BuildAgentRequirementFilter.html) class which allows to filter list of Bamboo agents capable of running the plan. There's no API to apply similar filter for Build Jobs at the moment.

## Deployment Projects

Another drawback is related to [Deployment Projects](https://confluence.atlassian.com/display/BAMBOO/Deployment+projects). By enabling Group Agent for remote or local agent you exclude it from the pool of agents that can run Deployment Projects. I bet you've just recalled that "Allow Deployments" checkbox I have recommended to leave unchecked. Well this option does exactly what it says, but it opens up the group agent for **all** deployment projects. Once again you will have dozens of unwanted deployment projects starting on a group agent, most of those will fail since Mac agent does not necessarily have all the required capabilities to deploy.

Why would you need a Mac deployment agent? - you'd ask. Well, there's quite a few deployment tasks that can be done on Mac OS X only. One example - uploading app binaries to iTunes Connect. For that you can use [iTMSTransporter](https://wmiphone.files.wordpress.com/2013/07/itunes_store_transporter_quick_start_guide_v2.pdf) or an amazing [deliver](https://github.com/KrauseFx/deliver) utility.

One of the solutions for this problem is to have a [dedicated deployment agent](https://confluence.atlassian.com/display/BAMBOO/Agents+for+deployment+environments). This is part of Bamboo's "out of the box" functionality. While configuring deployment projects you can assign agents to run those deployment projects. Deployment agents automatically become excluded from build agents pool though. You can use this solution if you have a spare Mac box to do just that. Given the iTunes Connect deployments are usually rare (unless you upload to new TestFlight very often), this may result in a valuable resource being idle most of the time.

Another solution would be to support group agent feature for deployment projects. Since deployment project is always linked to a build plan, it would be nice for deployment project to inherit group agent settings from it's "parent" plan. As a matter of fact, there's an already merged [pull request](https://bitbucket.org/eddiewebb/bamboo-group-agent/pull-request/1/advanced-support-for-deployment-projects/diff) addressing this issue, though the changes didn't make it into release yet.

# Summary

If you have a good opportunity then do your best to promote proper use of capabilities in your CI setup. Otherwise give Bamboo Group Agent a shot.
