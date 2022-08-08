---
layout: single
title: Understanding Protobuf
author: Jonas Carpay
issue-date: 2022-08-05
excerpt: Protobuf isn't just another serialization format.
tags: protobuf compatibility json xml serialization
---

This is a post on _protobuf_.

According to a quick informal survey, ~80% of the engineers at this company have at least heard of protobuf.
Unfortunately, I think most people don't actually understand what makes protobuf special or interesting, even among people who have some experience with it.
My goal today is to explain that; how to think about protobuf, and why it works the way it does.

The target audience is anybody who is interested in protobuf.
If you have never used it before, don't worry.
This is not about the details of how protobuf works but about the larger ideas, there are no examples to follow.
It's about the why, not the how.

The outline is as follows:

- What is protobuf
- Protobuf's killer feature
- Protobuf under the hood

# What is protobuf?

Any introduction on protobuf starts by mentioning that protobuf was invented at Google.
Now, that is true, but it doesn't say much.
Many things were invented at Google, most of which don't exist anymore.
Protobuf is different, though.

Google _runs_ on protobuf.

Engineering at Google is about taking protobuf from one place, and sending them to another.

## Immediate insights

Just from this, before we even know what protobuf actually is, we already know a few important properties

- It is designed for scale, since it works on Google-scale
- It is load-bearing, a lot of money rides on it
- There is an enormous engineering effort behind it
- Protobuf has a different set of values and constraints than most software; it cannot afford to be a toy

## What is protobuf, really?

Let's get down to the details.

Protobuf is short for _Protocol Buffer_, which is a horrible name, since it doesn't have much to do with protocols or buffers.

Superficially, protobuf is a data serialization format, like JSON or XML.

The first thing that makes protobuf different from these formats is the workflow.

### Protobuf workflow

When I originally gave this presentation, this is where I did a little demonstration of what using protobuf looks like in practice.
There should be a video recording available if you're interested, but the main takeaways are:

1. You define your data schema/format in a protobuf file
2. You automatically generate code to serialize and deserialize your data into these formats

So, the first advantage over traditional formats is that we get automatically get fast, efficient and easy-to-use (de)serialization code, for any supported language.

However, this is not actually protobuf's killer feature...

# Extreme compatibility

First, compatibility generally comes in three flavors:

- Backwards compatibility; code that you write now works with **past** versions
- Forwards compatibility; code that you write now works with **future** versions
- Sideways compatibility; code that you write now works with different code

## Why do we care about compatibility?

The usual situation is that when you hand-write a serialization format, and you then update your data types, all code the old data is now corrupted.
JSON makes it so that it might still be human-readable, but that doesn't mean that your new code automatically knows what to do with it.

If you're Google, these are big problems.
You have services in production that you cannot all take down at the same time to update them.
So, they need to be able to talk to each other _despite version mismatches_.
And, in the meantime, you cannot afford to have a single error!

But, these are not just problems for Google, at Cross Compass we have the same concerns.
AI typically has very long-lived data; you train a model now and need to be able to read it back for years afterwards.
This is double true when dealing with customers; we can't ask them to retrain all their data just because we want to push a new version of our software.
Besides, Cross Compass is an extremely polyglot environment, we have systems using Python, Haskell, Purescript, C, C++, C#, and probably many more!

Protobuf's killer feature is that it makes compatibility of any kind easy.
Actually, if you look at how protobuf has evolved over time, most of the changes have all been to further improve compatibility.
There's a lot you can learn about how to write lasting code just by studying the changes that protobuf has gone through over the years.
For reference, [here](https://capnproto.org/faq.html#how-do-i-make-a-field-required-like-in-protocol-buffers) is an insightful discussion about why protobuf doesn't allow you to make fields required anymore.

## How is this backwards compatibility achieved?

When I originally gave this as a presentation, this is where I would go through a number of examples and show you how protobuf often works in surprising ways.
Unfortunately, that demonstration does not translate nicely to a blog post, but I can try to sum it up as best I can in a few key points.

### What is in a protobuf message?

There's two important pieces of information to understand.

1. A protobuf message value is an associative array/dictionary/mapping of integers to values.
In python, you would call this something like `Dict[int, Any]`.

2. Missing values are treated as default values for that type, and vice versa.
In other words, we cannot actually check if a given field is present, we can only check if it's that type's default value.

Given that a protobuf _message_ is just a bag of integer/value associations, a protobuf _file_ assigns names and types to these integer keys.
That's it.

It doesn't require all the defined keys to be present, because it cannot tell the difference between a default value and a missing field.
It doesn't care if there are more fields than expected by the protobuf definition in the file, it just doesn't give you any names or allow you to manipulate them.
Messages are opaque collections of values, and protobuf files only give you named handles for things that may or may not be inside them.
You can store a protobuf message to disk, change every name in the protobuf file, add some fields, remove others, change the directory structure, and read it back from disk without issue.

The only thing that you can do to make a protobuf message incompatible is to change the type of a field.
If, for example, you write a message where field 1 is an integer, store it to disk, and then read the message back with field 1 as a float, you get undefined behavior.

### Protobuf best practices

It's important to understand what a protobuf message actually is, and how loose the connection between the definition file and the message actually is.
In practice, this means that protobuf files tend to become a sort of append-only log of things that we once expected to be in them, rather than an actual format description.
This is why unset/default values are missing values: it makes it so that the cost of adding fields is always zero, and more importantly, the benefit of removing old fields is always zero.

This means that we never delete fields, we just mark them as deprecated.
We can do this by adding a comment, by changing the field's name, or by adding a special deprecation token.
It doesn't really matter, none of it has any bearing on the actual serialized message.

# Conclusion

Protobuf is simple, but there are a lot of lessons in its simplicity.
It embodies the maxim "simple ain't easy", after all, it took Google 18 years to make it as simple as it is.
It is one of my favorite technologies because of that, and I hope I have given you some appreciation for it as well.
