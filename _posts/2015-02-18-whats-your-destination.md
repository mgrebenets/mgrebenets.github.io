---
layout: post
title: "What's your destination?"
description: "xcodebuild destination tips"
category: Xcode
tags: [xcode, mobile, ci, ios, apple]
---
{% include JB/setup %}

Few hands on tricks about `-destination` option of `xcodebuild`.

<!--more-->

Destination option (`-destination`) was a new addition to Xcode 5 release. It is documented on [xcodebuild man page](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/xcodebuild.1.html) and you get the same by running `man xcodebuild`. This option lets you be more verbose with your `xcodebuild` commands. For example, if you have a physical device plugged in, running `xcodebuild` with no destination specifier will build the project for this physical device. Using destination specifier you can explicitly tell `xcodebuild` to build for simulator.

Allow me just to quote the man page here

{% highlight bash %}
The -destination option takes as its argument a destination specifier describing the device (or devices) to use as a destination.  A destination specifier is a single argument consisting of a set of comma-separated key=value pairs.  The -destination option may be specified multiple times to cause xcodebuild to perform the specified action on multiple destinations.
{% endhighlight %}

By the way, pay a closer attention to the last sentence. It's a really nice feature, for example with single command you can run tests on multiple simulators.

One of the keys supported is "platform" and there are 3 options: "OS X", "iOS" and "iOS Simulator". Let's get more details on the last two. iOS and iOS Simulator platforms both require a "name" and "OS" keys to specify device name and iOS version. The question is "How to get list of all names and OS versions?". There are many ways to do that.

## Instruments

The Xcode Instruments command line utility has an undocumented `-s` option, which lists all devices and templates. By adding `devices` to the invocation only devices are be listed.

{% highlight bash %}
instruments -s devices
# or
xcrun instruments -s devices
{% endhighlight %}

Example output, note that it also includes your Mac as a device.

{% highlight bash %}
Known Devices:
R5003398 [5C25B8A6-EDF5-5856-B8B9-CB28DFBFADC4]
Maksym's iPhone (8.1.3) [5dc0e5a8a9f7c0af1feea4bfa13860c9e61350d6]
MyIPhone6 (8.1 Simulator) [9151073B-3B7D-441A-8069-E797FA5059CE]
Resizable iPad (8.1 Simulator) [15FC1628-B369-44DE-8CE0-756439D9AEBC]
Resizable iPhone (8.1 Simulator) [5E7A9E8C-D3A8-4E58-935F-8754B100E867]
iPad 2 (7.1 Simulator) [43DD0C31-685F-4FC8-941F-0BB9B305CD2D]
iPad 2 (8.1 Simulator) [8D722A9F-2DA9-45A2-BAFB-44075AA519D6]
iPad Air (7.1 Simulator) [2FB923E2-F0F4-49DE-8FC3-81960386B8CE]
iPad Air (8.1 Simulator) [6032BE94-1A62-4ADB-9013-50FAB2B088F6]
iPad Retina (7.1 Simulator) [F1967F38-BE03-430F-BFB1-AFF4E2E4511C]
iPad Retina (8.1 Simulator) [E8652514-3042-4958-9027-48A9A95392CE]
iPhone 4s (7.1 Simulator) [57DBC56E-1E04-4384-9A07-7B47C119BEAB]
iPhone 4s (8.1 Simulator) [DDF255C3-8BEF-4A97-8B3F-AD651BABF6CB]
iPhone 5 (7.1 Simulator) [BAF484D4-803C-478D-BAC1-916376C22C48]
iPhone 5 (8.1 Simulator) [45E5CE55-093D-48C0-AA26-AA4E5C569FDB]
iPhone 5s (7.1 Simulator) [6856CCCF-842E-48E8-897B-87BB1865CD10]
iPhone 5s (8.1 Simulator) [0AC6BB28-E860-4320-A532-272BE43C067C]
iPhone 6 (8.1 Simulator) [7953EE9F-19E8-4D0C-9219-268FB0BA6626]
iPhone 6 Plus (8.1 Simulator) [E574C367-1BAA-4F9F-BB92-BD5F6BAB1226]
{% endhighlight %}

## SimCtl

Another option is to use `xcrun simctl`, which is a new addition to Xcode 6. In fact, `simctl` looks like a very promising tool that allows you to create, boot, launch and then shutdown and destroy iOS simulators on the fly, and provides commands to install and launch specific apps. If you ever used [Genymotion](https://www.genymotion.com/#!/) you might have created Android simulators using [VirtualBox](https://www.virtualbox.org/) command line utility, Apple works towards the same flexibility with `simctl`.

In context of this article, to see a list of available devices, run this command

{% highlight bash %}
xcrun simctl list
{% endhighlight %}

You will get the list of device types, runtimes and devices. Device types and runtimes will be handy if you need to create new simulators. You can tell `simctl` to filter output, for example, list devices only


{% highlight bash %}
xcrun simctl list devices
{% endhighlight %}

Sample output

{% highlight bash %}
== Devices ==
-- iOS 7.0 --
    iPhone 4s (6CF0F409-F4F8-4BCD-AC4E-30E58947A3EB) (Shutdown) (unavailable)
    iPhone 5 (1C08AA1B-9C0C-499B-9570-972EF52941D9) (Shutdown) (unavailable)
    iPhone 5s (3DD4CAA5-6CD7-4DFB-AF95-6494EAE6E90F) (Shutdown) (unavailable)
    iPad 2 (C4E52F2A-C1C0-408F-8177-5AAF7895D3B5) (Shutdown) (unavailable)
    iPad Retina (D145A9C9-DFD0-4564-8A45-BF68A80426AC) (Shutdown) (unavailable)
    iPad Air (091FC037-5C7F-45FC-9089-E424A9806D60) (Shutdown) (unavailable)
-- iOS 7.1 --
    iPhone 4s (57DBC56E-1E04-4384-9A07-7B47C119BEAB) (Shutdown)
    iPhone 5 (BAF484D4-803C-478D-BAC1-916376C22C48) (Shutdown)
    iPhone 5s (6856CCCF-842E-48E8-897B-87BB1865CD10) (Shutdown)
    iPad 2 (43DD0C31-685F-4FC8-941F-0BB9B305CD2D) (Shutdown)
    iPad Retina (F1967F38-BE03-430F-BFB1-AFF4E2E4511C) (Shutdown)
    iPad Air (2FB923E2-F0F4-49DE-8FC3-81960386B8CE) (Shutdown)
-- iOS 8.1 --
    iPhone 4s (DDF255C3-8BEF-4A97-8B3F-AD651BABF6CB) (Shutdown)
    iPhone 5 (45E5CE55-093D-48C0-AA26-AA4E5C569FDB) (Shutdown)
    iPhone 5s (0AC6BB28-E860-4320-A532-272BE43C067C) (Shutdown)
    iPhone 6 Plus (E574C367-1BAA-4F9F-BB92-BD5F6BAB1226) (Shutdown)
    iPhone 6 (7953EE9F-19E8-4D0C-9219-268FB0BA6626) (Shutdown)
    MyIPhone6 (9151073B-3B7D-441A-8069-E797FA5059CE) (Shutdown)
    iPad 2 (8D722A9F-2DA9-45A2-BAFB-44075AA519D6) (Booted)
    iPad Retina (E8652514-3042-4958-9027-48A9A95392CE) (Shutdown)
    iPad Air (6032BE94-1A62-4ADB-9013-50FAB2B088F6) (Shutdown)
    Resizable iPhone (5E7A9E8C-D3A8-4E58-935F-8754B100E867) (Shutdown)
    Resizable iPad (15FC1628-B369-44DE-8CE0-756439D9AEBC) (Shutdown)
{% endhighlight %}

To get more details just run `xcrun simctl list -h` to get help on `list` command.

## xcodebuild

Finally, to get the most detailed output, ask `xcodebuild` itself. It is not really documented and doesn't look like a proper approach, but it works. The idea is to give `xcodebuild` invalid key-value pair in destination specifier and wait until it complains about it offering a list of valid options in return.

{% highlight bash %}
xcodebuild test -project MyProject.xcodeproj -scheme MyScheme -destination "name=NoSuchName"
{% endhighlight %}

The output is

{% highlight bash %}
xcodebuild: error: Unable to find a destination matching the provided destination specifier:
    { name:NoSuchName }

  Unsupported device specifier option.
  The device “My Mac” does not support the following options: name
  Please supply only supported device specifier options.

  Available destinations for the "MyScheme" scheme:
    { platform:iOS Simulator, id:C4E52F2A-C1C0-408F-8177-5AAF7895D3B5, OS:7.0, name:iPad 2 }
    { platform:iOS Simulator, id:43DD0C31-685F-4FC8-941F-0BB9B305CD2D, OS:7.1, name:iPad 2 }
    { platform:iOS Simulator, id:8D722A9F-2DA9-45A2-BAFB-44075AA519D6, OS:8.1, name:iPad 2 }
    { platform:iOS Simulator, id:091FC037-5C7F-45FC-9089-E424A9806D60, OS:7.0, name:iPad Air }
    { platform:iOS Simulator, id:2FB923E2-F0F4-49DE-8FC3-81960386B8CE, OS:7.1, name:iPad Air }
    { platform:iOS Simulator, id:6032BE94-1A62-4ADB-9013-50FAB2B088F6, OS:8.1, name:iPad Air }
    { platform:iOS Simulator, id:D145A9C9-DFD0-4564-8A45-BF68A80426AC, OS:7.0, name:iPad Retina }
    { platform:iOS Simulator, id:F1967F38-BE03-430F-BFB1-AFF4E2E4511C, OS:7.1, name:iPad Retina }
    { platform:iOS Simulator, id:E8652514-3042-4958-9027-48A9A95392CE, OS:8.1, name:iPad Retina }
    { platform:iOS Simulator, id:6CF0F409-F4F8-4BCD-AC4E-30E58947A3EB, OS:7.0, name:iPhone 4s }
    { platform:iOS Simulator, id:57DBC56E-1E04-4384-9A07-7B47C119BEAB, OS:7.1, name:iPhone 4s }
    { platform:iOS Simulator, id:DDF255C3-8BEF-4A97-8B3F-AD651BABF6CB, OS:8.1, name:iPhone 4s }
    { platform:iOS Simulator, id:1C08AA1B-9C0C-499B-9570-972EF52941D9, OS:7.0, name:iPhone 5 }
    { platform:iOS Simulator, id:BAF484D4-803C-478D-BAC1-916376C22C48, OS:7.1, name:iPhone 5 }
    { platform:iOS Simulator, id:45E5CE55-093D-48C0-AA26-AA4E5C569FDB, OS:8.1, name:iPhone 5 }
    { platform:iOS Simulator, id:3DD4CAA5-6CD7-4DFB-AF95-6494EAE6E90F, OS:7.0, name:iPhone 5s }
    { platform:iOS Simulator, id:6856CCCF-842E-48E8-897B-87BB1865CD10, OS:7.1, name:iPhone 5s }
    { platform:iOS Simulator, id:0AC6BB28-E860-4320-A532-272BE43C067C, OS:8.1, name:iPhone 5s }
    { platform:iOS Simulator, id:E574C367-1BAA-4F9F-BB92-BD5F6BAB1226, OS:8.1, name:iPhone 6 Plus }
    { platform:iOS Simulator, id:7953EE9F-19E8-4D0C-9219-268FB0BA6626, OS:8.1, name:iPhone 6 }
    { platform:iOS Simulator, id:15FC1628-B369-44DE-8CE0-756439D9AEBC, OS:8.1, name:Resizable iPad }
    { platform:iOS Simulator, id:5E7A9E8C-D3A8-4E58-935F-8754B100E867, OS:8.1, name:Resizable iPhone }
    { platform:iOS Simulator, id:9151073B-3B7D-441A-8069-E797FA5059CE, OS:8.1, name:MyIPhone6 }
    { platform:iOS, id:5dc0e5a8a9f7c0af1feea4bfa13860c9e61350d6, name:Maksym's iPhone }
{% endhighlight %}

## Back to Destination

Now that last output from `xcodebuild` is much better than anything else. It gives you all the key-value pairs as is, no additional guesswork involved. You get the "platform", "OS" and "name" keys, and as a bonus you get an undocumented "id" key. Give it a try and see that it actually works.

{% highlight bash %}
xcodebuild test -project MyProject.xcodeproj -scheme MyScheme -destination "id=E574C367-1BAA-4F9F-BB92-BD5F6BAB1226"
{% endhighlight %}

It's a bit annoying that it takes a while for `xcodebuild` to figure out that you've given it an invalid key-value pair, but still you can adopt this approach as part of CI workflow automation and grep all key-value pairs from `xcodebuild` output.
