Nix and NixOps at Cross Compass: Introduction
=============================================

This is the first blog post of a mini-series of blog posts describing our
experiences with using Nix and NixOps at Cross Compass. Through this series
of blog posts, we hope to document what we've learned along the way, both for
our own reference and to help anyone else who may be attempting similar things.

Background
----------

Cross Compass is developing a web service built around a software suite
developed in Haskell with a Ruby on Rails backend and a frontend developed using
React, TypeScript and Webpack. The Haskell code is already built using Nix while the frontend and
backend are built for deployment using Docker. The application is divided across
three separate repositories managed by different teams. Code is kept on
[GitHub](https://github.com) while we use [Buildkite](https://buildkite.com) for
continuous integration.

To ease testing the application in its fully deployed state, we want two
servers serving up production and staging versions of the web application.
In this context, "production" means a production release-ready version of the
code base, while "staging" means whatever the current `master` branch is
on GitHub. To that end, we want to trigger a build on Buildkite when any of the
three repositories is updated (either the master branch or when a release
is tagged) and we want Buildkite to deploy the fully-built application to GCP.

We decided to go with [NixOps](https://nixos.org/nixops/) for deploying the
staging and production servers from the Buildkite CI server. Here's
a summary of what we thought NixOps would give us:

* Use our existing [Nix Cache](https://nixos.org/nix/manual/#ssec-s3-substituter)
  to eliminate duplicating the build process
* Allow us to deploy to [NixOS servers](https://nixos.org/nixos/), which we were
  aready doing for some of our testing. The big benefit here is being able to
  declaratively specify how the machine should be built and updated and be
  confident we can rebuild that same machine if ever we need to.
* Make it easy to use [Nix](https://nixos.org/nix/) to build and deploy to the
  server giving us all the confidence that Nix gives us for reliable,
  reproducible building and deploying.
* Make it easy to reuse the code to deploy other services later on

On the other hand, it wouldn't be using Docker for deployment which we were
using before and intended to continue using for production deployments. We
decided that using the same docker deployment wasn't too important for this.

The other main problem is that Nix can be a little hard to break into with
few good examples to follow. This blog series will hopefully help a little
with that.

Coming Up
---------

Future blog posts will document the journey to getting automatic deployments of
our full stack web application to GCE using NixOps. In particular we will cover:

* Fundamentals
* Fixing NixPkgs
* Passing dynamic arguments to NixOps
* Getting a Ruby on Rails application to Run Using Nix
* Defining Systemd Services with NixOS Modules
* Using Re-usable Overlays to Share Modifications to NixPkgs Across Repositories
* Declaratively Installing AWS Keys using NixOS Modules
