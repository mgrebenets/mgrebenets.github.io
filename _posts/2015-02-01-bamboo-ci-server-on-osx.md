---
layout: post
title: "Bamboo CI Server on Mac OS X"
description: "Setup and Configure Bamboo CI Server on Mac OS X"
category: Mobile CI
tags: [bamboo, mobile, ci, atlassian]
---
{% include JB/setup %}

This article covers the details of installing a [Bamboo](https://www.atlassian.com/software/bamboo) CI Server on Mac OS X.

<!--more-->

# Install

The preferred way to install Bamboo is using official [Mac OS X installer](https://www.atlassian.com/software/bamboo/download?os=mac). Starting point for documentation is [official install guide](https://confluence.atlassian.com/display/BAMBOO/Installing+Bamboo+on+Mac+OS+X). Follow installer steps using default values.

> This article assumes you are dealing with Bamboo version 5.2 and above. All examples are for version 5.7.2.

To download tar-ball using command line run this command

{% gist f04d73c9aebd8411dec2d54a087857b4 %}

Bamboo needs Java to be [installed]({% post_url 2015-02-15-install-java-on-mac-os-x %}), recommended versions are 1.6 or 1.7, I would advise to go with 1.7.

Make a new home for Bamboo. It could be `/Applications/Bamboo` or `~/bamboo/bamboo-home` or whatever you want. For this post I'll stick with second option. It is often recommended to create a special `bamboo` user and put all things in their home directory. To create a new user use System Preferences and create Standard user.

{% gist fdf193c3b67abf0fd2670b78ecc255f9 %}

Note that I switch user (`su`) to work with Bamboo user's files and folders. This way I stay away from possible permissions conflicts. You could login as bamboo user instead. In any case, the rest of the article **assumes you are operating as bamboo user**.

Once downloaded unzip the tar-ball and copy `atlassian-bamboo-5.7.2` to bamboo user's home folder. Rename it to just `bamboo` to make it version agnostic.

Then go inside that folder. This is referred as _installation directory_ and this is where you will install and run Bamboo from. Edit the file in `atlassian-bamboo/WEB-INF/classes/bamboo-init.properties`. Uncomment the line with `bamboo.home` and put the following.

{% gist 16fb6751fe5d1cd0e41ec72cb223facb %}

This is where Bamboo will put all the customizations and build plan details.

Now you should run `bin/start-bamboo.sh`.

{% gist 1081eda39ae7739873ae42625c5c739d %}

Bamboo is now running on [http://localhost:8085/](http://localhost:8085/).

# Configure

Next step is to configure Bamboo, heres [official documentation](https://confluence.atlassian.com/display/BAMBOO/Running+the+Setup+Wizard). Recommended way is to use Setup Wizard which presents itself when you open [http://localhost:8085/](http://localhost:8085/) in the browser.

Start by getting a license. You can always get a 30 days free evaluation license from Atlassian.

Next select Custom Installation option. Have a look at Base URL, make sure the IP address is correct. Also this is a good moment to pause and double check that your future Bamboo server has a static IP address allocated. This will become really important when dealing with remote agents. Leave the rest unchanged and click Continue.

Select Embedded database option. It is recommended to use other DB setup for production system. I might refine the article later to include setup details for PostgreSQL database.

Next, choose to create a new Bamboo home, configure your username. Give it some time and you will be able to create your first build plan.

# Launch Agent

Now it's time to make sure Bamboo start automatically when build box restarts. As mentioned in [this article]({% post_url  2015-02-01-mobile-ci-daemon-vs-agent %}) recommended way is to use Launch Agent. Start by enabling automatic login for bamboo user in System Preferences.

Next create `com.atlassian.bamboo.plist` in `/Users/bamboo/Library/LaunchAgents`.

{% gist 8747a688835383c750cc80401aacd6fc %}

Make sure you create few aliases to start and stop Bamboo server from command line.

{% gist 00bcbc2a74b52ed1f7ead7a8b1ec3a97 %}

# Troubleshooting

This section provides an example of issues you may run into while trying to fire up Bamboo.

For example, you start Bamboo and see this instead of dashboard.

![Bamboo Bootstrap Failed]({{ site.url }}/assets/images/bamboo-bootstrap-failed.png)

To find out the reason look into Bamboo logs, specifically in `/Users/bamboo/bamboo/logs/catalina.out`.

{% gist 76ccf24592410f3915eca77337e87c5c %}

OK, so database is presumably locked by another process. In my case it meant there was another Bamboo running already. Double check it then by running `ps`.

{% gist fdab9eae1f635ad3d997fc5ca61f6635 %}

Indeed it is. I have another terminal tab open running bamboo user session and Bamboo server.

After I stop or kill all the instances I run it again and this time it works.

This is just one example of troubles, all of them will pretty much present themselves via the same starting error page. Another common case is database upgrade, you can run into this issue if using PostgreSQL and upgrade it via Homebrew, so it's recommended to pin PostgreSQL instead.

# Summary

This will get you going with basic Bamboo CI server. There's a number of additional administrative tasks yet to be done. Like configuring user access, integration with other Atlassian products, network configuration, plugins, capabilities and much more. I wouldn't envy anyone who would have to deal with all those tasks. Companies that take CI seriously normally have Dev Support team keeping whole infrastructure running, not just Bamboo.
