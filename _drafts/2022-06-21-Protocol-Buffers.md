---
layout: default
title: Understanding Protobuf
date: 2022.06.21
author: Jonas Carpay
tags: Google "Protocol Buffers"
excerpt: Overview of Protocol Buffers
---

# Understanding Protobuf

<p align="center">
date: 2022.06.21<br>
author: Jonas Carpay
</p>

## Goals

- Teach just enough to follow some examples
- How to think about it
- Why does it work the way it does

### NOT GOALS
- Best practices
- How to use
- What features does it have

## OUTLINE
- What is protobuf?
    - Demo
- Protobuf's killer feature and how ti relates to Cross Compass
- Protobuf under the hood
    - Demo

## WHAT IS PROTOBUF?

"Protobuf was invented at Google"
"Google runs on Protobuf"

### Four insights right off the bat
- Desinged for scale.
- Tremendously load-bearing.
- Enormous engineering effort behind it.
- Different set of values and constraints than most software.

### What is protobuf?
- Short for "Protocol Buffers" -> Horrible name.
- Serialization format, "It's like JSON/XML".
- Data description language
- Serialization format
- Workflow

## Protobuf's killer feature
- Yes, it's small
- Yes, it's pretty fast...

### Extreme compatibility
- Backwards compatibility
   - Code you write now oworks with past versions.
- Forwards compatibility
   - Code you write now owkrs with future versions.
- Sideways compatibility
   - Code you write works with different code.


