---
layout: single
title: Fixing Nixpkgs in NixOps
date: 2019.08.29
author: Robert Prije
tags: Nix NixOps Nixpkgs
excerpt: Guide how to use NixOps to fix Mixpkgs
---

When building with Nix, one of the typical things developers will want to do is
fix the version of Nixpkgs being used. For those not already familiar,
[Nixpkgs](https://github.com/NixOS/nixpkgs) is the official repository of Nix
derivations (the Nix equivalent of dpkg's and rpm's packages). When the version
of Nixpkgs is fixed, it guarantees that the same derivation will build exactly
the same output every time. This frees developers from being concerned about
changes in upstream dependencies while developing their applications. Or worse,
dependencies changing and breaking their application after development and
testing but before building and deploying.

That need to keep the development environment the same as the
deployment build environment means that if NixOps is to be used for building
and deploying applications, its Nixpkgs version needs to be fixed to the same
version used during development.

Fixing Nixpkgs in NixOps is not well documented.
[The official manual](https://nixos.org/nixops/manual/), sadly, doesn't describe
how to do it. **To summarise, it is done by setting the
`nixpkgs` prefix in the `NIX_PATH` environment variable**. Before describing
how we did this for our environment, I'd like to describe how something similar
is achieved from within Nix itself, and why it's not quite as rigourous as using
`NIX_PATH`.

We'll use a simple NixOS machine with the [dhall](https://dhall-lang.org/)
package installed to illustrate. I will be assuming a lot of what's already
covered in [the NixOps Manual](https://nixos.org/nixops/manual/). If a command
or configuration setting is unclear, I recommend checking the manual for
clarification.

First we'll define a simple VirtualBox physical specification to deploy to.
I've opted for VirtualBox here to keep things simple but the choice of
platform isn't important to this post. If you want to follow along you can
install VirtualBox and use this physical specification, or you can refer
to [the NixOps Manual](https://nixos.org/nixops/manual/) on how to retarget
the physical specification to a different platform:

`example-vbox.nix`:

```nix
{
  example =
    { pkgs, ... }:
    { deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 1024; # megabytes
      deployment.virtualbox.vcpu = 2; # number of cpus
    };
}
```

The logical specification of the box to deploy with dhall installed and without a fixed Nixpkgs:

`example.nix`:

```nix
{
  network.description = "Example";

  example =
    { pkgs, ... }:
    { environment.systemPackages = with pkgs; [ pkgs.dhall ];
    };
}
```

Trying it out:

```console
$ nixops create -d example ./example.nix example-vbox.nix
created deployment ‘994abedc-c273-11e9-950b-d89ef34b67c0’
994abedc-c273-11e9-950b-d89ef34b67c0
$ nixops deploy -d example
example> creating VirtualBox VM...
[...]
example> activation finished successfully
example> deployment finished successfully
$ nixops ssh -d example example
# readlink $(which dhall)
/nix/store/fk9433yg8hr71pzrm8gvakp6mfhnrdf0-dhall-1.19.1/bin/dhall
# readlink $(which bash)
/nix/store/mn4jdnhkz12a6yd6jg6wvb4mqpxf8q1f-bash-interactive-4.4-p23/bin/bash
```

The machine is up, we have SSH access to it and dhall is installed.

Going forward I will continue the convention introduced above of using a
`$` prompt when executing commands on the local machine, and a `#` prompt when
executing commands as root on the deployed virtual machine.

We want to fix Nixpkgs to a specific version. Let's try to do it
the way we ordinarily might when setting up a build environment (I'm pinning to
an older 18.09 version of nixos for illustration purposes):

`example-2.nix`:

```nix
let
  nixpkgs_src =
    builtins.fetchTarball {
      # nixos-18.09
      url = "https://github.com/NixOS/nixpkgs/archive/a7e559a5504572008567383c3dc8e142fa7a8633.tar.gz";
      sha256 = "16j95q58kkc69lfgpjkj76gw5sx8rcxwi3civm0mlfaxxyw9gzp6";
    };
  fixedpkgs = import nixpkgs_src {};
in

{
  network.description = "Example";

  example =
    { pkgs, ... }:
    { environment.systemPackages = with pkgs; [ fixedpkgs.dhall ];
    };
}
```

Redeploy and check the versions:

```console
$ nixops modify -d example ./example-vbox.nix ./example-2.nix
$ nixops deploy -d example
building all machine configurations...
[...]
example> activation finished successfully
example> deployment finished successfully
$ nixops ssh -d example example
# readlink $(which dhall)
/nix/store/8m0bqimml5malpm02yajf35z5b9hqv8n-dhall-1.15.1/bin/dhall
# readlink $(which bash)
/nix/store/mn4jdnhkz12a6yd6jg6wvb4mqpxf8q1f-bash-interactive-4.4-p23/bin/bash
```

This has successfully changed the version of `dhall` to the one in our pinned
version of Nixpkgs. However, notice that everything else, including bash,
remains the same as the unpinned version. What if we want to pin the whole
operating system?

Our strategy of loading up the nix tarball within `example-2.nix` won't work.

```nix
   { pkgs, ...}:
   { environment.systemPackages = with pkgs; [ fixedpkgs.dhall ];
   };
```

The above configuration is a
[NixOS module](https://nixos.org/nixos/manual/index.html#sec-writing-modules)
which is defined as the following:

- a function taking a set (which includes a `pkgs` attribute)
- the function produces a NixOS configuration specifying how to build the machine

The `pkgs` attribute is given by NixOps itself. We can use individual packages
from a different, pinned version of Nixpkgs in cases where we explicitly refer
to something in Nixpkgs (as we did for our dhall installation).  However, the
operating system itself is implicitly built off whatever NixOps chose to pass
as that `pkgs` attribute.

To tell NixOps which Nixpkgs to use, the `NIX_PATH` environment variable must
be used. Since we're now pinning the Nixpkgs passed as `pkgs`, we'll revert to
the original `example.nix` configuration without the specially defined
`fixedpkgs`:

```
$ nix-prefetch-url https://github.com/NixOS/nixpkgs/archive/a7e559a5504572008567383c3dc8e142fa7a8633.tar.gz --unpack
unpacking...
[14.4 MiB DL]
path is '/nix/store/qbzbhgq78m94j4dm026y7mi7nkd4lgh4-a7e559a5504572008567383c3dc8e142fa7a8633.tar.gz'
16j95q58kkc69lfgpjkj76gw5sx8rcxwi3civm0mlfaxxyw9gzp6

$ nixops modify -d example ./example-vbox.nix ./example.nix
$ NIX_PATH="nixpkgs=/nix/store/qbzbhgq78m94j4dm026y7mi7nkd4lgh4-a7e559a5504572008567383c3dc8e142fa7a8633.tar.gz" nixops deploy -d example
building all machine configurations...
[...]
example> activation finished successfully
example> deployment finished successfully
$ nixops ssh -d example example
# readlink $(which dhall)
/nix/store/8m0bqimml5malpm02yajf35z5b9hqv8n-dhall-1.15.1/bin/dhall
# readlink $(which bash)
/nix/store/6sczmwmyx81z1h88v2x434jr3s8qd1vz-bash-interactive-4.4-p23/bin/bash
```

And now we see that not just dhall, but the whole operating system has been
pinned to the version of Nixpkgs set in `NIX_PATH`.

Having to set `NIX_PATH` for every invocation of `nixops deploy` is not very
user friendly or robust. And we'd like to be able to check our fixed Nixpkgs in
to a version control system. So we set up a `shell.nix` to  take care of it all
for us:

`shell.nix`:

```nix
{ config ? {}
, nixpkgs ? null
} :

let

  nixpkgs_src =
    if nixpkgs == null
    then builtins.fetchTarball {
      # nixos-18.09
      url = "https://github.com/NixOS/nixpkgs/archive/a7e559a5504572008567383c3dc8e142fa7a8633.tar.gz";
      sha256 = "16j95q58kkc69lfgpjkj76gw5sx8rcxwi3civm0mlfaxxyw9gzp6";
    }
    else nixpkgs;

  pkgs = import nixpkgs_src { inherit config; };

in

pkgs.mkShell {
  buildInputs = [ pkgs.nixops ];
  NIX_PATH = "nixpkgs=" + nixpkgs_src;
  NIXOPS_DEPLOYMENT = "example";
}
```

Getting into that Nix shell and redeploying:

```console
$ nix-shell
$ # we are now in the above nix shell
$ nixops deploy
building all machine configurations...
[..]
example> activation finished successfully
example> deployment finished successfully
```

Now the `NIX_PATH`and the `NIXOPS_DEPLOYMENT` (the equivalent of the
`-d` flag we've been passing to `nixops`) variables are set in our shell. Users
no longer even need to install `nixops` themselves. So long as they have `nix`
installed, the shell will take care of ensuring `nixops` is available.

As long as `nix-shell` is run before any `nixops` commands, the correct version
of Nixpkgs will always be used.

## References

* [The Official NixOps Manual](https://nixos.org/nixops/manual/)
* [Discourse discussion on pinning Nixpkgs in NixOps](https://discourse.nixos.org/t/nixops-pinning-nixpkgs/734)
* [Domen Kožar's FAQ on pinning Nixpkgs in general](https://nix-cookbook.readthedocs.io/en/latest/faq.html#how-to-pin-nixpkgs-to-a-specific-commit-branch)
