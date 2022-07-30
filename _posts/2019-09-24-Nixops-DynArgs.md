---
layout: single
title: Passing Dynamic Arguments to NixOps
date: 2019.09.24
author: Robert Prije
tags: Nix NixOps
excerpt: Guide how to use NixOps
---

# Passing Dynamic Arguments to NixOps

<p align="center">
date: 2019.09.24<br>
author: Robert Prije
</p>

NixOps' declarative configuration is statically defined. But sometimes we want
parts of the configuration to be dynamic. At Cross Compass there were two
classes of configurations we wanted to be dynamic: the repository revisions to
build our platform from, and a set of secrets to be used.

The revisions need to be dynamic because we intend to automatically trigger
a redeployment using the latest available revisions of our codebases. Ideally
we don't want to generate a full new NixOps configuration each time we do this:
we want the NixOps configuration to stay mostly static and amenable to being
checked into a version control repository of its own.

We don't want that checked in configuration to contain secrets both because we
don't want secrets in version control, and because secrets in
nix expressions get copied into the world-readable `/nix/store`.

Fortunately, NixOps supports passing arguments to expressions defined in
network files. This is described in the
[Network Arguments section](https://nixos.org/nixops/manual/#idm140737322350416)
of the [NixOps Manual](https://nixos.org/nixops/manual/).

Along with providing code for following along with this blog post, the repository
[git@github.com:xc-jp/blog-post-code.git](https://github.com/xc-jp/blog-post-code)
will serve as a test for dynamically passing Git revisions and secrets to
NixOps. Included in the `DynArgs` directory is a Nix expression which builds a
small script `my-app`. This script simply takes a file containing a secret and
prints the contents within a message.

```
{ pkgs ? import <nixpkgs> {}}:

pkgs.writeScriptBin "my-app" ''
  #!${pkgs.runtimeShell}
  set -euo pipefail
  SECRET=''${1:-}

  [[ -n $SECRET ]] || (echo "Usage: $0 SECRET_FILE" && exit 1)

  echo "Running with secret: $(cat $SECRET)"
''
```

Here's an example of a network file describing the software to install and
run on a NixOS host. It includes the derivation for `my-app`:

`dynargs.nix`:
```
{ myApp, secret }:

let
  myAppSrc = builtins.fetchGit {
    url = "git@github.com:xc-jp/blog-post-code.git";
    inherit (myApp) rev ref;
  };
in

{
  network.description = "Example";

  example =
    { pkgs, lib, ... }:
    let
      # This turns a string into an absolute or relative
      # nix path conditional on whether the string begins with a '/'
      toPath = s:
        if lib.hasPrefix "/" s
        then /.  + s
        else ./. + "/${s}";
    in

    {
      environment.systemPackages =
        [ (import "${myAppSrc}/DynArgs" {inherit pkgs;}) ];
      deployment.keys.my-app-secret = {
        text = builtins.readFile (toPath secret);
      };
    };
}
```

Notice that this logical file takes an argument `{ myApp, secret }`.
This turns the network file into a function taking a dynamic argument that
can be supplied from `nixops set-args`.

We'll try it out using `example-vbox.nix` which was described in a
[previous blog post](http://cross-magazine.sub.jp/magazine/2019/08/29/fixing-nixpkgs-in-nixops/):

`example-vbox.nix`:
```
{
  example =
    { config, pkgs, ... }:
    { deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 1024; # megabytes
      deployment.virtualbox.vcpu = 2; # number of cpus
    };
}
```

Note if you have already run `nixops create -d example` once (either from an
earlier run of the code in this blog post, or while following along with the
[previous blog post](http://cross-magazine.sub.jp/magazine/2019/08/29/fixing-nixpkgs-in-nixops/)
) then you already have an `example` deployment and may need `nixops modify`
instead of `nixops create` here:

```
$ echo "my password" > /tmp/secret
$ nixops create -d example ./example-vbox.nix ./dynargs.nix
$ nixops set-args -d example \
    --arg myApp '{ref = "master"; rev = "675b7705d46dfc567c768f0f725eb2bbc55b0675"; }' \
    --argstr secret /tmp/secret
$ nixops deploy -d example --allow-reboot
example>
[...]
example> deployment finished successfully
$ nixops ssh -d example example
# my-app /var/run/keys/my-app-secret
Running with secret: my password
```

You can stop the running instance with
`nixops stop -d example --include example`.

A few things were introduced here.

First, we used `builtins.fetchGit` to checkout a commit from
[git@github.com:xc-jp/blog-post-code.git](https://github.com/xc-jp/blog-post-code)
which contains our `my-app`.

The Git commit revision and Git reference defining the commit to build against
is given through the NixOps argument under the `myApp` attribute:
`--arg myApp '{ ref = "master"; rev = "675b7705d46dfc567c768f0f725eb2bbc55b0675"; }'`
This value is then used by `builtins.fetchGit`: `inherit (myApp) rev ref;`

We can see `my-app` producing the output we expected when run against the
file `/var/run/keys/my-app-secret`.

`/var/run/keys/my-app-secret` itself was deployed from nixops via the
use of `deployment.keys`. `deployment.keys` is documented in the
NixOps manual under
[Managing Keys](https://nixos.org/nixops/manual/#idm140737322342384). In
brief, it provides a way of deploying secrets to a NixOS machine without those
secrets being copied to the world-readable Nix store. The keys are deployed
to a volume residing in volatile memory ensuring that the keys are not
persistently stored on a disk controlled by a third-party cloud provider.

We populated the text of `deployment.keys.my-app-secret` by using
a combination of `builtins.readFile` and `toPath` to ensure the
path to the secret file remains a string for as long as possible
minimising the time it exists as a Nix path and the risk of it getting copied
into the Nix store.

The path used in `deployment.keys.my-app-secret` is defined in the
`secret` argument we provided to NixOps: `--argstr secret /tmp/secret`.

Note that we used `--argstr` rather than `--arg`. This guarantees that the
argument will be passed to our function as a string and further reduce the
likelihood that we unintentionally copy the contents into the world-readable
nix store.

In this way, we have successfully passed run-time arguments to NixOps
setting both the revision of our repository to build our application against,
and a secret to be used by our application.

Should we want to change the secret path or the repository revision, we will
need to make another call to `nixops set-args`.

If you'd like to see what files and arguments NixOps has registered for a
deployment, you can use `nixops info`.

One behaviour I noticed that may be counterintuitive is that if paths
passed as arguments do not change, no update will take place even if the
contents of the path changes. As such, a more realistic example of
`/tmp/secrets` should use something like `mktemp` to ensure a new file path
is created each time. The file can then be removed after the deployment.
