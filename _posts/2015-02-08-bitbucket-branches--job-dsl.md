---
layout: post
title: "Bitbucket Branches and Jenkins Job DSL"
description: "Job DSL example for working with Bitbucket branches"
category: Mobile CI
tags: [dsl, jenkins, mobile, ci, git, bitbucket]
---
{% include JB/setup %}

A simple example of applying [Jenkins Job DSL Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Job+DSL+Plugin) in real life.

<!--more-->

For any real life application of any tool you have to start with real life problem or a goal you want to achieve. In this case, the goal is to generate Jenkins build projects for all Git branches of your project. Remote repository in this example is Bitbucket, which makes things a bit more different compared to dealing with GitHub.

You have probably ended up here by following the link from [this article]({% post_url 2015-01-29-bamboo-vs-jenkins %}). To reiterate, there are couple of Jenkins plugins that come close to solving the original problem, but they have number of serious drawbacks. So let's see how you can solve this problem with help of Jenkins Job DSL.

# Get Bitbucket Branches

First, let's start with [example for GitHub](https://github.com/jenkinsci/job-dsl-plugin/wiki/Real-World-Examples).

{% gist 6b2840df486613bf4b83e924e172bd71 %}

The first 3 lines are hitting GitHub API and grab the list of all branches. This code is not going to work for Bitbucket, so we need to come up with something different. Another complication is that (in my case) we are dealing with private Bitbucket repository, so need to take authorization into account. So lets figure out what's the URL to hit. The components of URL are

- API Base URL - by default it's [https://bitbucket.org/api](https://bitbucket.org/api)
- API Version - _1.0_ or _2.0_
- API Endpoint Path - includes the following
    - "repositories" - since we want to use one of the repositories API
    - Organization Name - aka team or account name
    - Repository Name - repository slug
    - Repositories API Endpoint - _branches_ since we want to get list of branches

Time to put it all together

{% gist 04941cb42fb0cde4531db87574596849 %}

Next we need to convert this string to `URL`, hit it and parse the output. But before we do that, we have to set Authorization header for HTTPS authentication with username and password. The username and password should be Base64 encoded.

{% gist 8b68a43fe282c2a5c609d9c19c524514 %}

This code, when put together, will return list of all branches in JSON format, or will not in case you are behind the...

# Proxy

This bit of code will help you to configure proxy for JVM

{% gist 8d5177201ccd5c676651b1e0573f82bf %}

Yep, `";"`s are a legacy thing and I put them there to demonstrate relation between Java and Groovy. In general, any Java code is a valid Groovy code, but not the other way around.

# Filter Branches

The JSON returned by Bitbucket API is a dictionary. Each entry has branch name as a key and branch description as value. Branch description is yet another dictionary with entries such as author, last commit hash and message, timestamp for last update, etc. Here's an example.

{% gist 39adfc61580453105354ca02ec648e95 %}

To experiment with Bitbucket API directly you can use this [REST Browser](http://restbrowser.bitbucket.org/).

Using this information you can filter out unwanted branches. The reason to do that is that not all developers do a proper cleanup after their branches are merged. You can end up with branches as old as 3 years or more, which you don't want to pick up and create CI build project for. So you can use _timestamp_ information to ignore branches, which haven't been updated for a long time. This is also an opportunity to enforce correct branch naming rules and filter all branches with incorrect names.

> An answer an absolutely valid question of "Why the branches are not deleted automatically on merge?" That's because some versions of git-flow do not use Bitbucket's native merge feature, but use a rebase instead. Thus the branches are left hanging around after they are merged and it becomes developer's responsibility to delete the branch.

{% gist d1d9621f77bd7e3fea426a0d3ebad0f1 %}

Let's go through the code in case comments are not descriptive enough. The main part is iterating over JSON dictionary `branchesJson` returned by Bitbucket API. On each iteration we have branch name `branchName` and its details packed as `details` JSON dictionary. We get the last modified date _timestamp_ and convert it into the `Date` object. Now we can check if the branch has valid name and is not too old.

_Valid_ name in this example means that branch is one of the major branches (_master_, _development_ and anything that starts with _release_), or that branch name has one of the 3 valid prefixes (_feature_, _bugfix_ and _hotfix_). `isValidBranch` method splits the branch name by `"/"`, gets the first element and checks if it's one of the valid prefixes.

Another filter is for branches that are too old, or in other words branches that haven't been updated for too long. This is what `isUpToDateBranch` method is for. Note that we consider all major branches to be always up to date. For example, _master_ branch can be updated only when major releases occur and we don't want its build project to be removed in the meantime. If Jenkins project is removed and then created again, its build number will be reset to 1, this is something we want to avoid, especially if build number is baked into the app version. Anyway, the logic is straightforward, if branch is one of the major branches, then consider it to be up to date. Otherwise, compare branch last modified date with current date and if the difference is more that expected (15 days in this example), then ignore this branch.

Then there's a note, that no `def` keyword or type are used to declare `majorBranches`, `validBranchPrefixes` and `allValidPrefixes` variables. This is intentional. Omission of `def` makes these variables a so called _binding_ variables. This is due to the fact that you are working with a Groovy script here and you have to declare variables like this to make them available for methods, e.g. to refer to them inside `isValidBranch` and `isUpToDateBranch`. I know it doesn't sound like a solid explanation, but you have to take into account the fact that I myself should be considered as Groovy beginner, so this is the best I can come up with at the moment.

Final bit that needs some explanation, is the use of `job` construction. `job` is a property of the Groovy script you are running. In fact, the scrip itself is an instance of [DslFactory](https://github.com/jenkinsci/job-dsl-plugin/blob/master/job-dsl-core/src/main/groovy/javaposse/jobdsl/dsl/DslFactory.groovy) class. Job is configured with a closure. The bare minimum it needs to create Jenkins Job (or as I refer to it in this article _Project_), is `name`, so I set it to current branch name replacing all `"/"`s with `"-"`s in the process.

# Summary

As a summary for this post, you can try to run Job DSL script on real Jenkins. First or all, you need to have an access to  Jenkins server. Next, you have to have [Jenkins Job DSL Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Job+DSL+Plugin) installed. Another required plugin is [Git Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin).

OK, so I assume you're looking at Jenkins dashboard right now. Go ahead and create _New Item_. Choose a name for your project and select _Freestyle project_ type and click "OK".

![Create DSL Project]({{ site.url }}/assets/images/jenkins-bitbucket-branches-create-dsl.png)

On new project configuration page you can leave everything "as is" for this example, the only thing you need to do is to add a new build step of "Process Job DSLs" type.

![Add Build Step]({{ site.url }}/assets/images/bitbucket-dsl-add-build-step.png)

Now you can [grab this DSL script gist](https://gist.github.com/mgrebenets/d3b5dcabb7606f3d7863) and copy-paste it in Jenkins. Don't forget to select "Use the provided DSL script" option first.

![Provide DSL Script]({{ site.url }}/assets/images/copy-paste-bitbucket-dsl-script.png)

You should have noticed that DSL script you just copied doesn't have the authentication and proxy bit enabled by default. I decided to make those steps optional so that you could run it in any environment. Since it points to a public repository, no authentication is required. Feel free to modify it to point to your private or public repo and to use your proxy.

OK, run it now and you should see something like this.

![Generated Jobs]({{ site.url }}/assets/images/bitbucket-dsl-result.png)

Here you have 2 Jenkins jobs generated for _master_ and _development_ branches.

This is just the beginning, from this moment on you can have numerous improvements. For example

- Refactor one big monolith script into packages and classes, such as
    - Class to work with Bitbucket API
    - Class to configure network proxy
    - etc.
- Put the script into repository and modify DSL job to clone repo and run the script from it
- And much more...
