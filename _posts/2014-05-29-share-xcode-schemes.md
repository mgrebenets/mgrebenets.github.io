---
layout: post
title: "Share Xcode Schemes"
description: "Share Xcode Schemes for Build Server"
category: Xcode
tags: [apple, ios, xcode, osx, xcodeproj, ruby, shell, resign]
---
{% include JB/setup %}

So you are facing one of these Xcode errors where it tells you that there's no such scheme? This post could help to explain why Xcode does it and how to solve this problem.

<!--more-->

# Shared vs User Schemes

While setting up build server for iOS app I have faced this issue multitude of times. Xcode schemes can be either shared or not. By default schemes are not shared and are owned by a user that creates them.

Here's how it looks in Xcode, note the last column with checkboxes.
![Manage Schemes]({{ site.url }}/assets/images/schemes-list.png)

If you look inside `kartoteka-reloaded.xcodeproj` folder you will see how Xcode stores the schemes.
Here's how it looks when `kartoteka-reloaded.xcscheme` is not shared

```bash
kartoteka-reloaded.xcodeproj/
├── project.pbxproj
├── project.xcworkspace
│   └── contents.xcworkspacedata
├── xcshareddata
│   └── xcschemes
└── xcuserdata
    └── grebenetsm.xcuserdatad
        └── xcschemes
            ├── kartoteka-reloaded.xcscheme
            └── xcschememanagement.plist
```

Now let's tick the "Shared" checkbox then list directory contents again

```bash
kartoteka-reloaded.xcodeproj/
├── project.pbxproj
├── project.xcworkspace
│   └── contents.xcworkspacedata
├── xcshareddata
│   └── xcschemes
│       └── kartoteka-reloaded.xcscheme
└── xcuserdata
    └── grebenetsm.xcuserdatad
        └── xcschemes
            └── xcschememanagement.plist
```

Notice how the `kartoteka-reloaded.xcscheme` moved from user data folder to shared data folder. This is basically what makes scheme a shared one.

The general practice for Xcode projects `.gitignore` file is to ignore user data

```bash
# .gitignore
xcuserdata/
*.xcuserdatad
```

So when you check out source code on a build box, there won't be any user schemes inside `.xcodeproj` folder and `xcodebuild` won't be able to see the schemes and will fail to build them.

# Solution

You can solve this problem either manually or automatically.

Of course you can just talk to devs and ask them to share the scheme. Done!
You can even do this change yourself and create pull request with changes.

But this approach will not work in some cases. For example, if you want to run UI automation tests with Calabash, the steps are

- Duplicate existing Xcode target and name new test target with `-cal` suffix
- Add Calabash framework to test target
- Build `-cal` test target and run tests

The first step is done with `calabash-ios setup` command. When new target is created a scheme is created for it as well. This is the default setting for all Xcode projects and in this post we'll assume that's the way you have it configured as well.

Now the tricky part, it doesn't matter if original scheme was shared, the new `-cal` scheme will not be shared. That means you won't be able to build it from command line.

Since it all happens on a build box as part of a build plan, you can't push anything back to the repository, you have to find a way to make this new scheme shared right now.

The answer to your problems comes from Ruby world. In particular the [xcodeproj](https://rubygems.org/gems/xcodeproj) Ruby gem. This is an incredibly handy library to work with Xcode projects and workspaces. You can do pretty much anything you need, create and modify targets and schemes, add new files to targets, modify build settings and other properties, and, of course, share schemes. By the way, `xcodeproj` is used by [CocoaPods](https://github.com/CocoaPods/Xcodeproj) and that says a lot.

Go ahead and install the gem

```bash
[sudo] gem install xcodeproj
```

Now create a simple Ruby file, name it whatever you want

```ruby
#!/usr/bin/env ruby
# share_schemes.rb

require 'xcodeproj'
xcproj = Xcodeproj::Project.open("MyProject.xcodeproj")
xcproj.recreate_user_schemes
xcproj.save
```

This is it! Put your Xcode project name in there, then run and the scheme will be shared.

```bash
chmod +x share_schemes.rb
./share_schemes.rb
```

# Caveats

It sounds to good to be true, right?
There's a number of situations where sharing a scheme via Ruby script will not work as expected.

If your Xcode project already has a shared scheme, then you will end up having one scheme from user's data directory and another one form `xcshareddata`. Xcode IDE will pick up both and that's the reason why you see same scheme twice with project name in parentheses.
![Manage Schemes]({{ site.url }}/assets/images/duplicated-schemes-list.png)

That's not very bad and doesn't normally cause any problems. Until that moment of time when you modify one scheme and forget about another. The best way to avoid this problem is to share schemes from day 1, Xcode will not create user schemes then.

The real trouble begins if you didn't have any shared schemes and the scheme that you want to recreate and share is linked to a test target. That's the default configuration for unit tests. So the problem is that `xcodeproj` [doesn't recreate dependencies to test target](https://github.com/CocoaPods/Xcodeproj/issues/139). If you run a `xcodebuild test` action you'll be surprised to see it failing. Unfortunately there isn't an easy workaround for this problem, so you'd better share those schemes manually and commit changes to source control system.

# Summary

Surely the Ruby script can be improved, you'd want to pass Xcode project name as an argument or even look it up automatically.

As usual, in Summary I just provide file listing with a solution ready to copy-paste. Here's more advanced Ruby script for your use. You can just get the file directly if you'd like, [share-schemes.rb](https://gist.github.com/mgrebenets/041a0b61cd5e4aaa9bdd)

```ruby
#!/usr/bin/env ruby
# share_schemes.rb

require 'optparse'
require 'ostruct'
require 'rubygems'
require 'xcodeproj'
require 'colorize'
require 'fileutils'

# Option parser
class OptionParser

    # Parse options
    # @param [Array<String>] args command line args
    # @return [OpenStruct] parsed options
    def self.parse(args)
        options = OpenStruct.new
        options.project = nil

        opt_parser = OptionParser.new do |opts|

            opts.banner = "Usage: #{File.basename($0)} [options]"

            opts.separator("")
            opts.on('-p [PROJECT]', '--project [PROJECT]', "Xcode project path. Automatically look up if not provided.") do |project|
                options.project = project
            end

            opts.separator("")
            opts.separator("Help:")
            opts.on_tail('-h', '--help', 'Display this help') do
                puts opts
                exit
            end

        end

        opt_parser.parse!(args)
        options
    end # parse()
end

options = OptionParser.parse(ARGV)

# Lookup for Xcode project other than Pods
# @return [String] name of Xcode project or nil if not found
def lookup_project
    puts "Looking for Xcode project..."
    # list all .xcodeproj files except Pods
    projects_list = Dir.entries(".").select { |f| (f.end_with? ".xcodeproj") && (f != "Pods.xcodeproj") }
    projects_list.empty? ? nil : projects_list.first
end

# lookup if not specificed
options.project = lookup_project if !options.project
if !options.project then
    puts "Error".red.underline + ": No Xcode projects found in the working folder"
    exit 1
end

puts "Using project path: " + "#{options.project}".green

xcproj = Xcodeproj::Project.open(options.project)
xcproj.recreate_user_schemes
xcproj.save

```

Right, this is one of those cases where actual meaningful code is very small (just 4 lines), the rest is options parsing and error checking, but then it's worth it in the end.

Finally run it

```bash
chmod +x share_schemes.rb
./share_schemes.rb -p "MyProject.xcodeproj"
```

## P.S.

[Related thread](http://stackoverflow.com/questions/14368938/xcodebuild-says-does-not-contain-scheme) on StackOverflow.
