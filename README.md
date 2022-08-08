Blog Posts README
=================

This repository contains a series of blog posts intended for posting on the
Cross Compass website.

Code: https://github.com/xc-jp/blog-post-code

All content is copyright Cross Compass LLC 2021.

## Building

HTML files will be automatically created by GitHub Pages.
Create a .md file to be posted under "\_posts" folder in the rule "YYYY-MM-DD-(name).md".
The folder "\_draft" can be used to keep the files not to be posted.
Images that will be embedded in pages should be kept under /assets/images/ folder.
To be able to access to images embedded in pages, it should be written with relative path ../../..//assets/images/(image filename).
Remember to add following block to be properly processed.
The first entry layout should be "single".

```
---
layout: single
title: (title of the post)
issue-date: 2022.01.01
author: name
tags: tag1 tag2
excerpt: Short description of the post
---
```

To build locally, Jekyll should be installed. https://jekyllrb.com/
Then Jekyll theme: https://mademistakes.com/work/minimal-mistakes-jekyll-theme/
