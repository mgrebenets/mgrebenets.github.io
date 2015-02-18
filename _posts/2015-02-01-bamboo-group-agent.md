---
layout: post
title: "Bamboo Group Agent"
description: ""
category:
tags: []
---
{% include JB/setup %}

TODO:

<!--more-->

what is it for? why do you need to use it?
example: a setup with server and agents in the cloud
and self-hosted mac agent

most plans will expect default capabilities because all the agents are same (cloned)
so there's no need to define those special capabilities most of the time
so you have a swarm of build plans with no capabilities
and any of those will be more than happy to jump on your mac agent

solution:
a - tell other devs to fix their plans - unreal, most plans were created ages ago and it's just difficult to carry such work trying to orchestrate so many other peeps
a.a - fix them yourself - hah!

b - use group agent
group agent marks the agent as part  of a group
only plans belonging to this group can run on this agent
you list groups separated by comma when configuring it
this part prevents all other build plans from using group agent

when creating plans you mark them as requiring build agent
this part locks your plan to a group agent

drawbacks:
lock the entire plan, no way to lock on job basis
with a typical ios plan, only build, unit test and some packaging/signing requires OS X (xcode)
all the rest (upload to hockey, testflight, etc., reporting, ) only needs build artifacts and network access
depending on your plan only 20% to 50% os actual jobs need OS X,
since mac agent is a scarce resource you'd benefit from running all the other jobs on cloud agents
but it's not possible

reason:
there isn't much to be done
the API (URL) that atlassian provides for plugin developers only allows filtering target agents for the plan
there's no granular control for jobs
so just accept the reality and look for ways to optimize the non-OS X parts of the build plan

another drawback: deployment projects
describe the problem, provide the solution
add link to a custom group agent plugin build
