---
layout: post
title: "Daemon vs Agent"
description: "Differences between Launch Agent and Daemon w/r/t Mobile CI"
category: Mobile CI
tags: [mobile, ci, ios, mac, osx, daemon, agent]
---
{% include JB/setup %}

Comparison of Mac OS X Launch Daemon and Launch Agent in regards to Mobile CI.

<!--more-->

[Launch Daemons and Launch Agents](https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html) are Mac OS X mechanisms used to launch and then control processes in the background. In regards to Mobile CI launch daemons and agents are often used to run CI server and agent instances.

## Compare

Here's the table with brief comparison.

<style>
table:nth-of-type(1) {
    display:table;
    width:100%;
}
table:nth-of-type(1) th:nth-of-type(2) {
    width:30%;
}
</style>

|  | Daemon | Agent |
|---|:---:|:---:|
| Launch Time | System start | User login |
| User Type | Non-login | Login |
| Home Folder | No | Yes |
| Login Keychain | No | Yes |
| iOS Simulator | No | Yes |
| Provisioning Profiles | No | Yes |

<br/>

Let's analyze each criteria in more detail.

_Launch Time_

Launch daemon starts at the time of system boot while agent starts at the time of user login. That usually means you would have to enable autologin option for the user account which is responsible to launching your CI server or agent.

_User Type_

To run at the time of system start launch daemon user has to be a non-login user. This means that the user can not login into OS X windows system, the only way to work with this user account is via SSH sessions. This will cause more problems when we look at next comparison criteria. Launch agent is a login user and that means she can login into windows system, install applications (if the user has enough rights) and do other things.

_Home Folder_

This is really a part of being login or non-login user. Login user as all the other standard users has a home folder in `/Users`. Non-login user has no home and if you need a place for it to store its files you will have to create one manually.

_Login Keychain_

Keychain is important for Mobile CI, especially for iOS. Whether you build for Enterprise, App Store or AdHoc distribution you have to sign the app bundle. To be able to sign you need a private-public key pair in your keychain and you **need to have access** to that keychain. Public key is part of the certificate so when I reference public key I also mean certificate that contains it.

With login user you can install development credentials (private-public key pair) into Login keychain in a very simple way. With non-login user you have no keychain to start with. Then you have to keep it up to date and make sure you put all new keys in that keychain.

_iOS Simulator_

Last but not least is the ability to use iOS Simulator. Unit tests are essential part of any CI and you have to run them in iOS Simulator which is a GUI app, and that means only login user can run it. Have a look [at this discussion](http://stackoverflow.com/questions/25380365/timeout-when-running-xcodebuild-tests-under-xcode-6-via-ssh) with some comments quoting Apple who recommends to use launch agent.

_Provisioning Profiles_

iOS Provisioning Profiles are normally managed by Xcode and located in `~/Library/MobileDevice/Provisioning Profiles` in the home folder of a _login_ user who installed Xcode on the system. When you pass provisioning profile UUID to `xcodebuild` command it looks for the profile in that folder. So if you run `xcodebuild` as non-login user the lookup will fail and you will be forced to specify full path to provisioning profile.

One of the solutions is to create a symlink like this.

{% highlight bash %}
<non-login-user-home>/MobileDevice/Provisioning Profiles --> /Users/login-user/MobileDevice/Provisioning Profiles
{% endhighlight %}

I have witnessed situations where by accident or on purpose the permissions of symlink were changed, thus changing permissions and/or ownership of `Provisioning Profile` folder in login user's home. Wrong permissions were causing problems to Xcode, it wasn't able to sync profiles because of that.

## Permissions Hell

Let's assume you have CI server running as a launch daemon. As discussed above default local agents are not capable of running iOS unit tests. Essentially your whole Mac box is incapable of running a lion share of your CI jobs. The solution is to create a remote agent running on the same host and configure that agent to run as a launch agent.

Let's further assume that you are dealing with some legacy setup and default non-login local agents actually run some jobs, they execute `xcodebuild` commands but never run unit tests. Now you add another build agent to run on the same box. Both these agents will share same Git cache, so don't be surprised when eventually Git fails to checkout repository. I haven't yet identified the core cause of this issue, but everything points to file permissions. Daemon and launch agent build nodes both run under different user accounts and create files with different permissions, so eventually they'll run into the trouble when working with shared cache.


## Summary

Let's summarize all the benefits and drawback of using Launch Daemon.

Benefits:

- Starts at system boot

Drawbacks:

- No Keychain
- Can't run unit tests (iOS Simulator)
- Can't launch any GUI apps (e.g. [Genymotion](https://www.genymotion.com/) for Android)
- Potential file permission issues when running alongside another build agents
- Can't easily access Provisioning Profiles

I would advise to avoid using Launch Daemons for Mobile CI servers or build agents at all costs.

If you really-really-really have to use Launch Daemon to fire up CI server, make sure it runs no Mobile CI jobs on it's default local build agents, setup a remote build node instead running on the same box as a launch agent.
