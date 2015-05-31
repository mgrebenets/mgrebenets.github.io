---
layout: post
title: "Fix Objective-C File Header Comment"
description: "Fix Objective-C File Header Comment"
category: Objective-C
tags: [objective-c, xcode, apple, ios, style, format]
---
{% include JB/setup %}

A simple way to fix file headers in your Objective-C (an not only) files.

<!--more-->

Might be worth to clean up confusions, if any. By "file header" in this case I mean the C-style header comment like this

{% highlight c %}
//
// Copyright (c) 2015 NSBogan. All rights reserved.
//
{% endhighlight %}

# Problem

For some people it doesn't really matter what sits at the top of the file. In big projects it may become more important. I have one particular case in mind where information in file headers needs to be anonymous and should contain only a company name and copyright notice, just like the code sample at the top. There are pros and cons to this approach. You may argue that it is important to know who created the file to point a finger, but when the project is large enough, dozens of people end up touching the same file, the project _outlives_ developers (they just come and go, but the project stays), there's no point to point a finger any more (apologies for the tautology here).

Another note is that we are here talking about existing files. When it comes to creating new files, it is [possible](http://stackoverflow.com/questions/2381149/changing-the-default-header-comment-license-in-xcode) to modify [default Xcode templates](http://stackoverflow.com/questions/20311839/change-copyright-top-comment-header-on-all-new-files-in-xcode-5), and even manage to [preserve the changes on Xcode upgrade](http://stackoverflow.com/questions/33720/change-templates-in-xcode/33743#33743). There's even [a tool](https://github.com/royclarkson/xcode-templates) to automate the process to a certain level.

However, if you have a script that can fix header comments in existing files, you can reuse the very same script in your git commit hooks to fix the header comments of new files. Kill two birds with one stone (though in my native language we choose hares as objects of violence for this proverb).

# Solution

So, at the high level, the way to approach this problem is

- Remove all blank lines at the start of the file
- Remove all lines that start with `//` from the start of the file
- Insert you custom header comment at the start of the file

Before proceeding further, let's agree we are working with a source file named `Source.m` and have an environment variable defined as `FILE_PATH=Source.m`.

## Remove Blank Lines

The blank lines at the start of the file are a rare exception, but sometimes they do occur. Fixing this is possible with `sed` is _easy_

{% highlight bash %}
sed -i . '/./,$!d' "${FILE_PATH}"
{% endhighlight %}

This is one of those they call _read-only language_. A one-liner that takes hours to decipher, unless you are fluent with `sed` already.

- The `-i . ` option means _inplace_ edit and weird looking `.` with a must-have space after `-i` option is OS X specific way to tell `sed` not to create backup file.
- The `/./,$` construction is a range and means _from `/./` to `$`_. `/./` is a regex that matches any non-blank line, `$` is a special address and means last line of the input. So `/./,$` in English means _from first non-blank line to the end of file_.
- `!` means negation. So if you negate `/./,$` you get the following human language description _from first line of the input to last blank line inclusive_. In other words, all consequent leading blank lines in the file.
- Finally, `d` command means _delete_, so you tell `sed` to delete all lines in the given range.

Whoa, that was a lot of words to explain one 7-characters `sed` command...

## Remove Header

Next thing to do is to remove existing header comment. This is a matter of removing consequent lines starting with `//` from the start of the file. You may think this sounds just like removing consequent blank lines. It does! But I failed big time to do it with sed. I originally assumed this is just a matter of replacing `/./` regex with something like `/^\/\//`, but no, it didn't work for me. I spent a fair amount of time googling and trying my best with `sed` and `awk`, before I gave up and came up with the solution you will see below. However, it would be fair to say that my seding and awking skills are nowhere near good enough, I am sure there's a better way to do it and I would welcome any comments.

{% highlight bash %}
# Count number of consequent lines starting with // at the beginning of the file
N=$(cat "${FILE_PATH}" | awk '{ if(/^\/\//) print; else exit; }' | wc -l | xargs)

# Remove first N lines from the file
[[ ${N} -gt 0 ]] && sed -i . "1,${N}d" "${FILE_PATH}"
{% endhighlight %}

You can see here that the very same `/^\/\//` regex I tried to use with `sed` works perfectly with `awk`. The `awk` command will execute `print` until file lines match the pattern and will stop (using `exit` command) as soon as the first non-matching line occurs.

Word count (`wc`) command is used to count lines then (`-l` option) and `xargs` is handy in this case because it strips leading and trailing spaces from the input.

Next if `N` is greater than zero, use good old `sed` to remove first `N` lines from the file. This is done by using `1,${N}` address range and `d`elete command. Note the use of _"weak"_ quotation marks in sed regex, this is to resolve reference to `N` inside the regex string.

## Insert New Header

Finally, you have the file stripped of its old header comment, time to insert a new header.

{% highlight bash %}
# Insert new header using current year
HEADER="//\\
// Copyright (c) $(date +'%Y') NSBogan All rights reserved.\\
//\\
\\
"

sed -i . "1s|^|${HEADER}|g" "${FILE_PATH}"
{% endhighlight %}

The header here is using `date` command to insert current year in _YYYY_ format, e.g. 2015.

`sed` matches the beginning of the line (`^` anchor) and inserts the header there. The `1` before replacement pattern is there to make sure replacement is made only once.

## Edge Cases

The described approach will not work for header comments that use block style, e.g.

{% highlight c %}
/**
    File header comment.
*/
{% endhighlight %}

# Summary

As usual I link a version of [slightly improved script](https://github.com/mgrebenets/mgrebenets.github.io/blob/master/assets/scripts/fix-c-header-comments). As a bonus this script can fix header comments in `xcconfig` files as well. I still say _slightly_, because it can be improved more. One possible step up is to create a text file with you custom header comment and pass this file path as an input to a header fixing script.

You can bundle this script up with [imports fixing script]({% post_url 2015-05-29-fix-objective-c-imports %}) and use as part of git commit hooks to eliminate some of the code style debates during code reviews.
