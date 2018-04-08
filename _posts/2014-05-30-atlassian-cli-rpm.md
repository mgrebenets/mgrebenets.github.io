---
layout: post
title: "Install Atlassian CLI with RPM"
description: "Atlassian CLI RPM"
category: Atlassian
tags: [atlassian, cli, rpm, rhel, linux, aws]
---
{% include JB/setup %}

Another follow up to [introduction to Atlassian CLI]({% post_url 2014-05-29-atlassian-cli %}).

This post describes how to create an RPM package for Atlassian CLI to install it on [RMP-based Linux distributions](http://en.wikipedia.org/wiki/Category:RPM-based_Linux_distributions).

<!--more-->

Jump directly to [Summary](#tldr) if just want to grab the end result.

# Why Bother?

Same question as one would as for using [Homebrew on OS X]({% post_url 2014-05-30-atlassian-cli-homebrew%}). And same answer again - Automation.

Let's assume you already use Atlassian CLI Client for number of build tasks, like automatically updating JIRA tickets, Confluence pages, Stash pull requests, etc.

Let's further assume that your company has a proper CI environment, for example RPM-based Linux instances running in [AWS cloud](http://aws.amazon.com/). Each instance runs one build agent (slave, node or whatever you call it).

One of the reasons going into the cloud is scalability, you can go from one to few dozens of identically cloned agents with literally one click of a mouse.

Normal practice is to refresh those instances repeatedly, e.g. on a 2 weeks schedule, and _refresh_ in this context means recreating them from scratch. This is when an updated OS image is used for new instances, you can put new updates and packages into this new image to make it available to all build tasks by default without additional installation. For example, you could not just have [RVM](https://rvm.io/) installed, but also install few most used rubies for 2.0 and 2.1.

Preparing new image has a funny name, that is _Baking_ (remember _Brewing_?). What's amusing, the whole baking process is done by the very same CI setup it will be applied to. Keeping an eye on the whole infrastructure is actually quite a challenge and you would most likely have DevOps or DevSupport team to look after it.

In any case, to conclude this long passage, one of the reasons to have an RPM package for Atlassian CLI is to be able to bake it into your build agent.

# Create RPM Spec

Creating and RPM package is very similar to creating Homebrew tap, only in this case instead of Formula you need to create [RPM Spec](http://www.rpm.org/max-rpm/ch-rpm-inside.html).

```bash
touch rpm.spec
```

Let's put first lines into the spec

```bash
%define __spec_install_post %{nil}
%define __os_install_post %{nil}
%define debug_package %{nil}
Summary: nsbogan-atlassian-cli
Name: nsbogan-atlassian-cli
Version: %{version}
Release: %{release}
License: Atlassian EULA Standard License
Vendor: Bob Swift Software, LLC
Packager: Maksym Grebenets <mgrebenets@gmail.com>
Group: Application/Development
Provides: %{name}
Requires: java
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}
Source: %{name}-%{version}.tar.gz
BuildArch: %{arch}

%description
Atlassian CLI tools by Bob Swift. See https://marketplace.atlassian.com/plugins/org.swift.atlassian.cli
```

First three lines are a result of googling as well ans trial and error process. I'm not an experienced RPM package builder, so there are things that I will have to leave unexplained.

Next lines are self descriptive. The `%{varname}` syntax is the way you can pass variables into RPM spec when using it with `rpmbuild`, for example

```bash
export VERSION=1.0
export RELEASE=1
# Set locale to C.
LC_ALL=C rpmbuild --define "version ${VERSION}" --define "release ${RELEASE}" --define "arch noarch" -bb ~/path/to/rpm.spec
```

Some of the header attributes worth mentioning separately. For starters the _Source:_ attribute should point to your source tarball. But it doesn't have to be a local file, it can be a URL just like Homebrew's `url` attribute. You can then download and unzip it with one call to [`%setup` macro](http://www.rpm.org/max-rpm-snapshot/s1-rpm-inside-macros.html).

```bash
%prep
%setup
```

I myself just found out about it recently and didn't try it yet. So in this article I'll do the job of setup macro with shell commands, but this is definitely where improvements should be made.

Then there's `_tmppath` variable. You will notice later that it's not passed to RPM script directly anywhere, instead, it's picked up from a special `.rpmmacros` file. You'll see how it's used later on.

## Install

Now it's time to define install command. It's again very similar to Homebrew's install. So I will give here brief description of the steps with the code and for more details you can always get back to [Homebrew post]({% post_url 2014-05-30-atlassian-cli-homebrew%}).

### Prepare and Setup

Since we don't use `%setup` macro, we have to some of the work here.
Remove old build directory, unzip the source tarball and cleanup Windows stuff right away.

```bash
%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/opt/nsbogan-atlassian-cli
tar -zxvf %{_sourcedir}/%{name}-%{version}.tar.gz -C %{buildroot}/opt/nsbogan-atlassian-cli

# cleanup windows bats
rm -f %{buildroot}/opt/nsbogan-atlassian-cli/*.bat
```

### Patch and Move

Next is patching time and once patching is over move the files to a proper location (`bin` folder). I've explained why this is required in the post related to Homebrew formula, so have a peek there.

When patching we'll update all the `.sh` scripts and put new relative path to JAR files, we'll also insert proper `JAVA_HOME` export in each.

```bash
# Patch shell scripts, rename and move to bin.
mkdir -p %{buildroot}/opt/nsbogan-atlassian-cli/bin

# Patch .sh files.
for file in %{buildroot}/opt/nsbogan-atlassian-cli/*.sh; do
    # patch the path to lib before moving
    sed -i -e 's,/lib,/../lib,g' ${file}
    # inset JAVA_HOME export at 2nd line
    # use awk since couldn't figure out how to do it with sed '2i\ construction'
    awk 'NR==2 {print "[[ -d /usr/java ]] && export JAVA_HOME=/usr/java/$(ls -1 /usr/java | grep %{java_version} | tail -n1)"} {print}' ${file} > ${file}.bak && mv ${file}.bak ${file}
done
```

Then it's time to customize all the Atlassian product URLs as well as put a proper service account username and password if you plan to save keystrokes in the future.

```bash
# Customize atlassian.sh with products username, password and URLs.
filename=%{buildroot}/opt/nsbogan-atlassian-cli/atlassian.sh
sed -i.bak -e "s/\(.*user=\)'.*'/\1'%{username}'/g" $filename
sed -i.bak -e "s/\(.*password=\)'.*'/\1'%{password}'/g" $filename

# Product URLs.
sed -i.bak -e "s,\(.*\)https://jira.example.com\(.*\),\1http://jira.nsbogan.com.au\2,g" $filename
sed -i.bak -e "s,\(.*\)https://bamboo.example.com\(.*\),\1http://bamboo.nsbogan.com.au\2,g" $filename
sed -i.bak -e "s,\(.*\)https://stash.example.com\(.*\),\1http://stash.nsbogan.com.au\2,g" $filename
sed -i.bak -e "s,\(.*\)https://confluence.example.com\(.*\),\1http://wiki.nsbogan.com.au\2,g" $filename
sed -i.bak -e "s,\(.*\)https://fisheye.example.com\(.*\),\1https://fisheye.nsbogan.com.au\2,g" $filename
sed -i.bak -e "s,\(.*\)https://crubicle.example.com\(.*\),\1https://crubicle.nsbogan.com.au\2,g" $filename
```

Finally rename ambiguous `all.sh` to `atlassian-all.sh` and move all `.sh` files to `bin` folder. I personally prefer to drop `.sh` part from the filename in the process.

```bash
# all.sh - rename to atlassian-all.sh before moving.
mv %{buildroot}/opt/nsbogan-atlassian-cli/all.sh %{buildroot}/opt/nsbogan-atlassian-cli/atlassian-all.sh

# Move shell files.
for file in %{buildroot}/opt/nsbogan-atlassian-cli/*.sh; do
    # move to bin with renaming
    BASE=$(basename ${file})
    NEW_NAME=${BASE%.sh}
    chmod +x ${file}
    # cat ${file} > $HOME/tmp/$(basename ${file}).txt

    # Backwards compatibility (payback for bad decisions).
    cp ${file} %{buildroot}/opt/nsbogan-atlassian-cli/bin/atlas-${NEW_NAME}

    mv ${file} %{buildroot}/opt/nsbogan-atlassian-cli/bin/${NEW_NAME}
done

# Cleanup backup files.
rm -rf *.bak
```

## Files and Symlinks

Now it's time to tell RPM spec which files are part of final installation.

```bash
%files
/opt/nsbogan-atlassian-cli
```

In post-install stage we want to symlink all the shell scripts and JAR files to a corresponding directory in `/usr/local`. The reason behind that is because `/usr/local/bin` is already on our `PATH` (if not, then add it as described in Homebrew post).

We also add info for post-uninstall process so it can remove all these symlinks for us.

```bash
%post
# Link binaries to /usr/local/bin.
for file in /opt/nsbogan-atlassian-cli/bin/*; do
    ln -fs ${file} /usr/local/bin/$(basename ${file})
done

# link libraries to /usr/local/bin
for file in /opt/nsbogan-atlassian-cli/lib/*; do
    ln -fs ${file} /usr/local/lib/$(basename ${file})
done

%postun
# Unlink binaries.
for file in /opt/nsbogan-atlassian-cli/bin/*; do
    rm -f /usr/local/bin/$(basename ${file})
done

# Unlink libs.
for file in /opt/nsbogan-atlassian-cli/lib/*; do
    rm -f /usr/local/lib/$(basename ${file})
done
```

### Clean

No comments on this one.

```bash
%clean
rm -rf %{buildroot}
```

## Changelog

Add some change log and you are done with the spec.

```bash
* Feb 18 2014 - Maksym Grebenets <mgrebenets@gmail.com> %{version}-%{release}
- Upgrade to 3.9.0
```

# Build RPM

It's time to build an RPM based on the spec we have just came up with.
In this example I'll use Makefile which helps to present material in more simple and organized way than just shell scripts.

```bash
touch Makefile
```

Define all the basic configuration, like version, release, Java version, etc.
Note the use of `noarch` here for architecture. We are working with collection of JARs and shell scripts, there are no sources files that need any compilation at all, so we specify that we are not building for any particular architecture.

```makefile
PACKAGE = nsbogan-atlassian-cli
VERSION = 3.9.0
RELEASE = 1
ARCH = noarch
NSBOGAN_USERNAME = automation
NSBOGAN_PASSWORD = automation
JAVA_VERSION = 1.6
PACKAGE_URL = https://marketplace.atlassian.com/download/plugins/org.swift.atlassian.cli/version/$(subst .,,${VERSION})

# Source directory
SRC_DIR=src
# Distribution directory where the source distributive is located
DIST_DIR=dist
# RPM file name
RPM_FILE=${PACKAGE}-${VERSION}-${RELEASE}.${ARCH}.rpm
```

Now define step by step what needs to be done using Makefile targets (aka recepies).

Download the package if it doesn't exist yet.

```makefile
download:
    @echo "Downloading from $(PACKAGE_URL) ..."
    @mkdir -p $(SRC_DIR)
    @(if [ ! -f $(SRC_DIR)/${PACKAGE}.zip ] ; then curl -o $(SRC_DIR)/${PACKAGE}.zip --progress -fSL $(PACKAGE_URL) ; fi)
```

Then unzip. This place partially explains why I avoided `%setup` macro. Setup macro assumes source is a tarball and uses `tar` utility to unpack it. But with Atlassian CLI the source is just a `.zip` file, so setup macro generates commands that don't work.

```makefile
unzip: download
    @(cd $(SRC_DIR) && unzip -qox ${PACKAGE}.zip)
    @(cd $(SRC_DIR) && ln -fFs atlassian-cli-[0-9]* ${PACKAGE})
```

Once unzipped, we also link symbolically versioned folder to `${PACKAGE}` file. This makes it easier to write next steps.

Now pack unzipped file into a tarball. This is all due to specifics of `rpmbuild`, it want's tarball and we have to comply. Put the tarball into distributive directory.

```makefile
dist: unzip
    @mkdir -p $(DIST_DIR)/
    @(cd $(SRC_DIR)/${PACKAGE} && tar -czf ../../$(DIST_DIR)/${PACKAGE}-${VERSION}.tar.gz .)
```

Finally we can build RPM.

Still we end up doing some additional work here. `rpmbuild` expects a certain directory structure in it's root build folder. Once again, we're pretty much doing the `%setup` job here.

- We will build an RPM in `~/rpmbuild` directory, so we create one with number of required subdirectories (all those names in caps and tmp).
- Then move tarball to `SOURCES` directory
- Copy our RPM spec to `SPECS`
- Then add `%_topdir` and `%_tmppath` to a special `~/.rpmmacros` file. `rpmbuild` will scan `~/.rpmmacros` and pass all picked up values to RPM spec when building it.
- Finally call rpmbuild passing version, release and all the other vars.
  - The [`-bb` option](http://www.rpm.org/max-rpm-snapshot/ch-rpm-b-command.html) tells `rpmbuild` which steps to execute.
- Once `rpmbuild` is done, copy RPM package to distributive directory.

```makefile
rpm: dist
    @echo "Making RPM..."
    @mkdir -p ~/rpmbuild/{RPMS,SRPMS,BUILD,SOURCES,SPECS,tmp}
    @cp -f $(DIST_DIR)/${PACKAGE}-${VERSION}.tar.gz ~/rpmbuild/SOURCES/
    @cp -f rpm.spec ~/rpmbuild/SPECS/
    @echo "%_topdir ${HOME}/rpmbuild" > ~/.rpmmacros
    @echo "%_tmppath %_topdir/tmp" >> ~/.rpmmacros
    @(LC_ALL=C rpmbuild -v --define "version ${VERSION}" --define "release ${RELEASE}" --define "arch ${ARCH}" --define "java_version ${JAVA_VERSION}" --define "username ${NSBOGAN_USERNAME}" --define "password ${NSBOGAN_PASSWORD}" -bb ~/rpmbuild/SPECS/rpm.spec)
    # copy to dist
    @cp -f ~/rpmbuild/RPMS/${ARCH}/$(RPM_FILE) $(DIST_DIR)/
```

So, are you ready to try it?

```bash
make rpm
```

I ran it on Fedora 20 as well on a custom Linux distribution running in AWS cloud. Since the package does not depend on architecture, you could in theory build it on OS X machine, but it's not what I would recommend, getting proper `rpmbuild` port configured is not something you enjoy very much.

# Install RPM

To test your installation, use these commands

```bash
# rpm install
rpm --install --replacepkgs --replacefiles --nosignature --nodigest $(DIST_DIR)/$(RPM_FILE)

# test rpm install
rpm --freshen -v --test --replacepkgs --replacefiles --nosignature --nodigest $(DIST_DIR)/$(RPM_FILE)
```

Now you can hand RPM package over to your Dev Support guys, they'll put it into local repo and make RPM install a part of bake or post-bake process.

Yet nothing stops you from creating a CI plan (job) for the Atlassian CLI RPM package itself. You can run `make rpm` and test rpm install on the very same build agent this package is targeted for, thus creating yet another "CI Loop", which is good.

# <a name="tldr"/> Summary

- Create [RPM spec](https://gist.github.com/mgrebenets/b40ad2077172db9cdb2d)
- Run `make rpm -f RPMMakefile` using this [RPMMakefile](https://gist.github.com/mgrebenets/b1b9d52e135561362666)
