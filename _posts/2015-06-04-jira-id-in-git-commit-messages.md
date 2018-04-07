---
layout: post
title: "JIRA ID in Git Commit Messages"
description: "JIRA ID in Git Commit Messages"
category: Tools
tags: [jira, git, hooks]
---
{% include JB/setup %}

A quick tip on how to automatically add [JIRA](http://en.wikipedia.org/wiki/JIRA) ID in each git commit message.

<!--more-->

# What & Why

[JIRA](https://translate.google.com.au/?ie=UTF-8&hl=en&client=tw-ob#auto/en/JIRA) or not, if you use some kind of issue tracker and want to get a certain level of integration with Git, it is a good idea to include ticket IDs into commit message.

A couple of assumptions then.

Ticket IDs are in the `PROJ-1234` format, where `PROJ` is the short reference to the project (usually uppercase) at least 1 character long, and `1234` represents a ticket number.

Let's also assume that you are naming your branches in the following way: `prefix/JIRA-1234-optional-description`. Prefix is arbitrary and optional as well. Usual examples are `feature/` or `bugfix/`. So now you are working on the branch named like this and you want all your commits to have `[JIRA-123]` added at the start of commit message, for example

```bash
[JIRA-123] Fix the crash
```

# How

You should use Git hooks to achieve the goal.

There are subtle differences when doing it for a main git repo and for submodules.

## Main Repo

Git hooks are located in `.git/hooks/`. The particular hook you are interested in is commit message hook. Copy a default sample `.git/hooks/commit-msg.sample` and name it `.git/hooks/commit-msg`.

```bash
cp .git/hooks/commit-msg.sample .git/hooks/commit-msg
```

Now edit `commit-msg` and remove the example code from it.

```bash
# Remove this code.
test "" = "$(grep '^Signed-off-by: ' "$1" |
     sort | uniq -c | sed -e '/^[   ]*1[    ]/d')" || {
    echo >&2 Duplicate Signed-off-by lines.
    exit 1
}
```

Then add this code at the end of the file.

```bash
# If commit message is a fixup message, ignore it.
[[ -n "$(cat $1 | grep 'fixup!')" ]] && FIXUP="YES"

TICKET=$(git symbolic-ref HEAD | rev | cut -d/ -f1 | rev | grep -o -E "[A-Z]+-[0-9]+")
if [[ -n "${TICKET}" && -z "${FIXUP}" ]]; then
    sed -i.bak -e "1s/^/[${TICKET}] /" $1
fi
```

Some explanation might be helpful. First the line that sets the `TICKET` variable.

```bash
TICKET=$(git symbolic-ref HEAD | rev | cut -d/ -f1 | rev | grep -o -E "[A-Z]+-[0-9]+" | head -n1)
```

The `git symbolic-ref HEAD` commands gets the name of the current git branch, which may look like `refs/heads/feature/JIRA-1234-description`.

Then `rev` turns it into `noitpircsed-4321-ARIJ/erutaef/sdaeh/sfer`.

When the branch name is reversed, the last component is now first in the string, and that's exactly the component we are after, so get it with `cut` command using `/` as a separator. `cut -d/ -f1` splits by `/` and takes `1`st component. The result is `noitpircsed-4321-ARIJ`.

Next reverse it back into `JIRA-1234-description` and at this moment we expect the string to start with JIRA ID. JIRA ID by itself is more than one capital letter, then dash `-` and then more than one digit, this is exactly what `[A-Z]+-[0-9]+` regex describes. If your project name is different, you can adjust regex. `grep` with the given regex and `-o` option will return the match `o`nly, which is `JIRA-1234`. Finally `head -n1` will take only the first match, that's in case you have more than one JIRA ID in the branch name.

If the `TICKET` has a value, then modify current commit message by adding value of `TICKET` at the start of it. The commit message is actually a file and that file can be accessed via bash script `$1` variable. `sed` is used to find a beginning of the line `^` and add `[${TICKET}] `, but only once, which is controlled by `1` before before the `s/` path: `1s/^/[${TICKET}] /`.

```bash
if [[ -n "${TICKET}" && -z "${FIXUP}" ]]; then
    sed -i.bak -e "1s/^/[${TICKET}] /" $1
fi
```

And last thing to explain is `FIXUP` variable. If you are using commands like `git commit -a --fixup HEAD` then `fixup!` string is added to the start of commit message automatically. But the problem is that `fixup!` is added _before_ commit hook is called, so you end up with commit messages like this.

```bash
[JIRA-1234] fixup! [JIRA-1234] Commit message
```

That's not what you want if you want to take advantage of autosquasing feature. This is why there is this bit of code at the start of the script.

```bash
[[ -n "$(grep 'fixup!' $1)" ]] && FIXUP="YES"
```

It searches for `fixup!` string in commit message file `$1` and if a match is found sets `FIXUP` variable to `"YES"`.

## Submodules

OK, so now you have commit hook working for main repo, but what if you also have a number of in-house submodules and work with them in the same workspace? In that case you'd want to have the same hooks for submodules.

The problem is that hooks for submodules are located in different directories. Submodules git configuration and other files are located in `.git/modules`. The simplest way would be to find all `hooks` directories inside `.git/modules` and copy commit message hook file we created previously. This will works if you are OK to have same hooks for main repo and submodules, and none of the submodules paths contains `hooks` string. The script below does exactly what I described in English just now. `smh` here stands for `submodule hooks`.

```bash
for smh in $(find .git/modules -name hooks); do \
    cp -f .git/hooks/commit-msg ${smh}/; \
done
```

Don't forget to update submodule hooks when you change the main repo hooks.
