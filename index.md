---
layout: page
title: NSBogan
tagline: An Automation Blog
---
{% include JB/setup %}

I have started this blog after doing UI Automation Testing for a while.

If you are interested in topics like

- Cross-platform UI Automation for Mobile (Calabash, Cucumber)
- Build automation for iOS and Android
- Tools and scripts

You might find something useful in this blog.

<ul>
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a>
      {{ post.excerpt }}
    </li>
  {% endfor %}
</ul>

- Email: [mgrebenets@gmail.com](mailto:mgrebenets@gmail.com)
- GitHub: [mgrebenets](https://github.com/mgrebenets)
- Bitbucket: [i4niac](https://bitbucket.org/i4niac)
- LinkedIn: [Maksym Grebenets](http://au.linked.com/in/mgrebenets)
