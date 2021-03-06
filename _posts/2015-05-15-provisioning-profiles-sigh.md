---
layout: post
title: "Provisioning Profiles, Sigh..."
description: "Manage Provisioning Profiles Automatically - Basics"
category: Mobile CI
tags: [mobile, ci, ios, fastlane, sign, apple, xcode]
---
{% include JB/setup %}

In this article you will find out why iOS provisioning profiles are a nightmare and if there is a way to automate provisioning profiles management.

<!--more-->

## Provisioning Profiles

Anyone who calls themselves an iOS Developer, knows what this is all about. You have to generate profiles, make sure they use proper certificates and are configured for the right app identifier. Should you renew a certificate or change the app's entitlements, you now have to regenerate all related provisioning profiles, then make sure you install new profiles everywhere you need them. If it wasn't difficult enough already, there are 2 types of provisioning profiles: Development and Distribution; and if that wasn't enough, Distribution profiles come in two more flavors: App Store and AdHoc.

But that's not the end of the nightmare either! What if you are a member of more than one iOS developer program? For example, you are part of both App Store and Enterprise programs, or you are a freelancer and happen to be a member of a dozen teams. Did you use different Apple IDs for different teams? Doesn't make it any easier at all. I'm sure many of you know what it feels like.

Finally, things go wild if you have to manage that provisioning zoo for Continuous Integration setup. Just one build box is painful enough to keep up to date, I'm not even mentioning multiple build agents yet...

Of course I'm over pessimistic, but that's on purpose. One could say that Xcode can manage your accounts and profiles. That's true but Xcode is known to do a very sloppy job in that regards, and in no way Xcode's provisioning profile management can be _automated_.

Overall, managing provisioning profiles involves a lot of **manual** interactions with web browser. What if there was a tool that would let you manage profiles automatically, via command line and scripts? Well, it so happens that there is one now! Meet [Sigh](https://docs.fastlane.tools/actions/sigh/) a part of [Fastlane](https://docs.fastlane.tools/) tools. Fastlane is a collection of tools that cover all aspects of iOS development, Sigh in particular is designed to help you with managing provisioning profiles and certificates. You can manage profiles installed locally as well as create, renew, update, regenerate and delete profiles from developer portal.

There are so many uses for the tool, but in this article I'll describe the most basic one, that is downloading an existing provisioning profile. As a bonus, you will see how to parse provisioning profiles and get all the details from it, especially profile UUID and signing identity of the related certificate.

## Download Profile

Time to fix all the assumptions before going forward.

- You have an account with Enterprise development program and that account has **Admin** level of access.
- You have a Distribution provisioning profile created for Wildcard App ID (*).

That will do it. First thing to do is to install Fastlane Ruby gem.

> gem install fastlane

Time to get a profile now.

{% gist f19e6e75a2725d2e42c4931104f808e9 %}

So what's going on here?

* `--username` is the Apple ID you used to join the developer program.
* `--team_id` is the 10 character ID of the team. This is mandatory if the Apple ID is part of multiple teams (aka programs). In general, it's just a good rule of thumb to be as explicit as possible.
* `--provisioning_name` is the name of provisioning profile. That's the very same name you see when you login to developer portal, not UUID or any other kind of identifier.
* `--app_identifier` is the App identifier in the provisioning profile. The same thing you use as Bundle ID most of the time. In this example the profile is a wildcard profile, so app identifier is just "*" (wildcard). Be cautious! Those quotes around `*` _really matter_!
* `--filename` tell sigh where to save a copy of the provisioning profile file. By default it will be installed in `~/Library/MobileDevice/Provisioning Profiles/`. If you don't want the profile to be installed, add `--skip_install` option to the command.

The very first time you use a given combination of Apple ID and Team ID you will be asked for a password. Fastlane will safely store your password in keychain and you will not have to type it in anymore (well, until the moment you change it, of course). So for CI setup you will have to use Sigh (or any other tool from Fastlane) at least once for each developer account, to have the password stored, and from that moment on all CI scripts will be able to work without user intervention required.

The above is not the case with the introduction of 2FA. You would have to configure `FASTLANE_SESSION` as described [here](https://github.com/fastlane/fastlane/tree/master/spaceship#support-for-ci-machines).

> A side note in regards to Team ID. For some reason the real ID is very obscure and doesn't match the one you would see in Member Center. Luckily, you can run Sigh with wrong Team ID and it will output the list of all correct IDs.

## Parse Profile

Another step towards total automation is to include profile download as part of CI job. Usually all CI jobs expect latest provisioning profiles to be installed on the box. CI is either using UUID explicitly, expects profile to have a specific file name or delegates profile lookup task to Xcode. With Sigh you can simplify this bit immensely. Each CI job will make sure the latest profile is downloaded and installed, and named the way it should be named.

Additionally, you may want to extract information from the profile, such as the profile UUID and the name of the signing identity. Why would you do that? Well, you can build the very same project using various provisioning profiles and signing identities, this is the way you can get different builds for Enterprise, AdHoc and App Store distribution, with different bundle IDs, etc. Usually build scripts are configured to specify the provisioning profile specifier and signing identity explicitly via `xcodebuild`'s `PROVISIONING_PROFILE_SPECIFIER` and `CODE_SIGN_IDENTITY` build settings. This is how you can overwrite default build settings in Xcode project.

While specifying signing identity explicitly is important, specifying profile specifier is something that should be done with a lot of caution. The reason is Today Widget and WatchKit extensions. These extensions are separate targets in Xcode project and by default extension targets are dependencies for main app target. It means when you build a main target, all extensions are built as well. Nothing bad so far. The problem is that each of those extensions has its own bundle ID and, as you would expect, a separate provisioning profile. Now, if you explicitly specify profile specifier when building main app target, this build setting will overwrite build settings for all dependent targets as well. Naturally, the build will fail when trying to build Today Widget extension with bundle ID and entitlements from main app target provisioning profile.

So what do you do? Well, previously I'd say to trust Xcode, but these days I'd recommend to use custom build settings instead. E.g. define build settings in this way:

- For main app: `PROVISIONING_PROFILE_SPECIFIER = MAIN_APP_PROVISIONING_PROFILE_SPECIFIER`
- For extension: `PROVISIONING_PROFILE_SPECIFIER = EXTENSION_PROVISIONING_PROFILE_SPECIFIER`

Now you can control individual provisioning profile specifiers for each target, or even put them in a `xcconfig` file and use that file to override build settings.

In any case, it' still helpful to be able to parse the provisioning profile, e.g. if you want to have some post build verification to make sure the correct profile has been used for the build.

Start with dropping all the digital signature stuff and getting just the profile XML (plist) part.

{% gist cd82c1d6776432e0f72080d72bd1b06f %}

I can't tell you what _exactly_ all arguments of `security` command mean, you may find better answers in the [Inside Code Signing](http://www.objc.io/issue-17/inside-code-signing.html) article, where I learned about this command and other commands you will see in the rest of this post. The result is saved to `profile.plist`.

Now you have a plist with all the data. Let's get UUID first. The tool that can work with plists is `/usr/libexec/PlistBuddy`.

{% gist 281a61bc772983c8d5f404fb2cad8927 %}

This doesn't need much explanation. If you run this command you will get the UUID of the profile as an output.

Next is signing identity, which is a bit more difficult. Signing identity name is not stored as plain text in the profile, however, it is part of the certificate. The profile stores all associated certificates in `DeveloperCertificates` key-value pair. That's right, there can be more than one certificate associated with one provisioning profile. It's hard to figure out which of the certificates to pick automatically. The assumption is that all of those certificates are valid and any of them can be used to sign the app bundle. If that's not the case, you need to tidy up things in your developer portal. Sigh can actually help you to do that from command line as well. Anyway, let's assume the first certificate is the one you need, time to get it.

{% gist 7b3453c593c9845f971c08b1a7e864bf %}

Oops, looks rather ugly. Seems like PlistBuddy is doing some base 64 decoding under the hood. You can feed this output to `base64` utility to encode it back and see the same data as in plist, but do you really need to? Instead, just feed this unreadable data directly to `openssl` and ask for the subject field.

{% gist 1abcd3f21110e293b55d23ee74783267 %}

The output is something like

{% gist 6a692924876abf25a60bd4c869dd06f4 %}

You only need to get Common Name (CN) part. At the moment I didn't find anything better than using `sed` as you can see below. It extracts the string between "/CN=" and "/OU=". I don't know in which flavors certificates come, could be this regex needs adjustments in case the order of fields in subject is different.

{% gist 03305cac3b7af5d940a6e6a977e1234e %}

Alternatively, you can use this regex

{% gist fa522da226c3a236a7074fe05000f4b6 %}

It works with the assumption there are no `/`s in the common name. I think the message here is

> Be reasonable and don't use `=`s or `/`s when naming new certificate.

## Summary

So now you have a way to download and parse provisioning profile. Automatically, in one go. With little bit of work you can come up with a proper shell script for the task.

{% gist 8d722a2cf263fbff81b40527c61e88f0 %}

Wit a bit more work you can refactor it to take username, team id and other parameters as input arguments.
