---
layout: post
title: "Jenkins Job DSL - Configure Block"
description: "Jenkins Job DSL - Configure Block"
category: Mobile CI
tags: [jenkins, ci, mobile, dsl, groovy, xml]
---
{% include JB/setup %}

A hands-on experience with [Configure Blocks](https://github.com/jenkinsci/job-dsl-plugin/wiki/The-Configure-Block) in Jenkins Job DSL.

<!--more-->

[Jenkins Job SDL](https://github.com/jenkinsci/job-dsl-plugin) is a crown jewel of all the Jenkins plugins. I had a basic [write up]({% post_url 2015-02-08-bitbucket-branches--job-dsl %}) about it already, and another one in regards to [DSL script properties]({% post_url 2015-05-17-jenkins-job-dsl---properties %}).

This post is an example of using [Configure Blocks](https://github.com/jenkinsci/job-dsl-plugin/wiki/The-Configure-Block). I'll make an effort an try to explain what Configure Blocks are with my own words.

Basically, the whole DSL language output is a job configuration XML file. You are given a high level API to shape out that XML, that's it. In some cases, where there's no simple high level API available yet, you can use a bit lower level methods to mess around with resulting XML. That's exactly what configure blocks are - a fallback mechanism to squeeze more juice out of Job DSL plugin.

Here's an example, a default configuration of [Git plugin](https://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin) will not update submodules recursively and will use default 10 minutes timeout for submodules update operation.

![Default Submodule Update Configuration]({{ site.url }}/assets/images/job-dsl-configure-block/submodules-default.png)

Job DSL [provides an API](https://github.com/jenkinsci/job-dsl-plugin/wiki/Job-reference#git) to enable recursive submodules update. This is how you can use it in DSL

{% highlight groovy %}
job {
    scm {
        git {
            remote {
                url("git-remote-url")
            }
            branch("branch-name")

            // All submodules recursively
            recursiveSubmodules(true)
        }
    }
}
{% endhighlight %}

That was easy. Here's how the Jenkins job will look like now.

![Default Submodule Update Configuration]({{ site.url }}/assets/images/job-dsl-configure-block/submodules-recursive-only.png)

What if you want to change default timeout for submodules operations now? Unfortunately there's no DSL command for that yet. This is exactly the case where you'd want to use Configure Block. Scanning through Configure Block examples, I have found [this one](https://github.com/jenkinsci/job-dsl-plugin/wiki/The-Configure-Block#configure-git). Looks like it's quite easy to add new nodes to the job XML, but you have to figure out how to name those nodes first. The best way to find that out is to modify the job via Jenkins UI and then look at the job XML. So open the job configuration page in the browser, type in the 20 minutes custom timeout value and click save.

![Default Submodule Update Configuration]({{ site.url }}/assets/images/job-dsl-configure-block/submodules-recursive-and-timeout.png)

Now it's time to locate the XML on file system. All the jobs data is located in `JENKINS_HOME`, the easiest way to find Jenkins Home location is again via Jenkins UI. Go to `Jenkins > Manage Jenkins > Configure System` and have a look at the top of the page.

![Default Submodule Update Configuration]({{ site.url }}/assets/images/job-dsl-configure-block/jenkins-home-directory.png)

Navigate to Jenkins Home, then to `jobs` directory, then find the directory of your particular job, this is very straightforward task, finally you will see `config.xml` in that directory, open it and have a look. This is the node you are looking for

{% highlight xml %}
<scm class="hudson.plugins.git.GitSCM" plugin="git@2.3.5">
    <!--...-->
</scm>
{% endhighlight %}

Specifically you are interested in this block of code

{% highlight xml %}
<extensions>
      <hudson.plugins.git.extensions.impl.SubmoduleOption>
        <disableSubmodules>false</disableSubmodules>
        <recursiveSubmodules>true</recursiveSubmodules>
        <trackingSubmodules>false</trackingSubmodules>
        <timeout>20</timeout>
      </hudson.plugins.git.extensions.impl.SubmoduleOption>
</extensions>
{% endhighlight %}

See that `<timout>20</timeout>` node? This is exactly what you want to generate using Configure Block. This is how you can do that

{% highlight groovy %}
job {
    scm {
        git {
            remote {
                url("git-remote-url")
            }
            branch("branch-name")

            // All submodules recursively
            recursiveSubmodules(true)

            // Increase submodule clone timeout using config block (set 20m, default is 10m)
            configure { node ->
                // node represents <hudson.plugins.git.GitSCM>
                node / 'extensions' << 'hudson.plugins.git.extensions.impl.SubmoduleOption' {
                    timeout 20
                }
            }
        }
    }
}
{% endhighlight %}

That looks easy, doesn't it? But hold on a sec before you celebrate. Run a DSL script first then have a look at resulting XML _before_ looking at job configuration via Jenkins UI. Locate the SCM node again

{% highlight xml %}
<scm class="hudson.plugins.git.GitSCM">
    <!--Skipped nodes-->
    <disableSubmodules>false</disableSubmodules>
    <recursiveSubmodules>true</recursiveSubmodules>
    <!--Skipped nodes-->
    <extensions>
        <hudson.plugins.git.extensions.impl.SubmoduleOption>
            <timeout>20</timeout>
        </hudson.plugins.git.extensions.impl.SubmoduleOption>
    </extensions>
</scm>
{% endhighlight %}

Hm... Looks a bit strange doesn't it? The `disableSubmodules` and `recursiveSubmodules` nodes are outside of `hudson.plugins.git.extensions.impl.SubmoduleOption` for some reason. At least the values look right. So now go ahead and open the job configuration in Jenkins UI or hit refresh if you had it open all this time.

![Default Submodule Update Configuration]({{ site.url }}/assets/images/job-dsl-configure-block/submodules-timeout-only.png)

Wait... What did just happen there? The recursive update checkbox is cleared!

Let's have a look at job XML one more time.

{% highlight xml %}
<scm class="hudson.plugins.git.GitSCM" plugin="git@2.3.5">
    <!--Skipped nodes-->
    <extensions>
      <hudson.plugins.git.extensions.impl.SubmoduleOption>
        <disableSubmodules>false</disableSubmodules>
        <recursiveSubmodules>false</recursiveSubmodules>
        <trackingSubmodules>false</trackingSubmodules>
        <timeout>20</timeout>
      </hudson.plugins.git.extensions.impl.SubmoduleOption>
    </extensions>
</scm>
{% endhighlight %}

Well, the `scm` node is moved up in the XML and is changed a bit. Also, the `recursiveSubmodules` as well as `disableSubmodules` are moved inside the `hudson.plugins.git.extensions.impl.SubmoduleOption` node, but somehow `recursiveSubmodules` has lost its custom value in the process. Whatever Jenkins is doing under the hood is a mystery for me. This may be a bug in Jenkins Job DSL plugin or a known limitation. Brief search in project [JIRA](https://issues.jenkins-ci.org/browse/JENKINS-22138?jql=project%20%3D%20JENKINS%20AND%20component%20%3D%20job-dsl-plugin%20AND%20status%20%3D%20Open%20ORDER%20BY%20priority%20DESC) and discussion [group](https://groups.google.com/forum/#!searchin/job-dsl-plugin/configure$20block$20overwrites$20values) didn't come back with any results. That means if you are working with Configure Blocks, keep the following in mind

> When changing one particular node, either do all changes via Job DSL API or via Configure Block, but never mix the two.

If you want to have both recursive submodule update and custom timeout configured, set both of them via Configure Block.

{% highlight groovy %}
job {
    scm {
        git {
            remote {
                url("git-remote-url")
            }
            branch("branch-name")

            // Increase submodule clone timeout using config block (set 20m, default is 10m)
            configure { node ->
                // node represents <hudson.plugins.git.GitSCM>
                node / 'extensions' << 'hudson.plugins.git.extensions.impl.SubmoduleOption' {
                    recursiveSubmodules true	// Clone submodules recursively
                    timeout 20
                }
            }
        }
    }
}
{% endhighlight %}
