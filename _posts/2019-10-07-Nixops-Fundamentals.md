---
layout: default
title: NixOps Fundamentals
date: 2019.10.07
author: Robert Prije
tags: Nix NixOps
excerpt: Explaining very basic of NixOps
---

# NixOps Fundamentals

<p align="center">
date: 2019.10.07<br>
author: Robert Prije
</p>

Before covering the specific problems we encountered and solved with NixOps,
we'll go over some fundamentals of NixOps to familiarise you with the tools
and background that you may need for later posts.

If you are already familiar with NixOps, or are comfortable finding what
you need from the more comprehensive [manual](https://nixos.org/nixops/manual/)
then you may want to
[skip this post](http://cross-magazine.sub.jp/magazine/2019/08/29/fixing-nixpkgs-in-nixops/).
This post is not intended to duplicate the work in the manual, but rather
condense the information relevant to the remaining blog posts for easy
reference.

## Overview of NixOps

NixOps provides a way to use the
[Nix programming language](https://nixos.org/nix/manual/) to define a
NixOps "network specification", which is a declarative description of a set of
machines in the cloud. Once defined, NixOps converts the network specification
into a "deployment" which is a combination of the network specification
describing how the machines "should be" as well as the current state of those
machines as last known by NixOps. Through the deployment, NixOps is capable of
provisioning and decommissioning those machines, deploying updates to them,
starting and stopping them, and accessing them via ssh. Such actions
update the running state of the machines and NixOps' internal record of that
machine state whenever appropriate.

A network specification describes a set of resources including a mapping of
machine names to
[NixOS modules](https://nixos.org/nixos/manual/index.html#sec-writing-modules).
Any attribute name not already reserved for a resource is assumed to be the
name of a machine. A network specification can be defined across multiple
network files. If a machine shows up in multiple files, the mapped NixOS modules
are merged. This means we can adopt the standard NixOps practice of separating
a machine's "logical" specification (the software that runs on the machine) from
a machine's "physical" specification (the provisioned hardware and cloud service
the machine runs on).

For example, here is a logical specification describing just the software
running on a machine named `example`:

```
{
  network.description = "Example";

  example =
    { pkgs, ... }:
    { environment.systemPackages = with pkgs; [ pkgs.dhall ];
    };
}
```

Here is the physical specification for the same machine describing a virtual
machine running under [VirtualBox](https://www.virtualbox.org/):

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

The actual deployment is stored in an [SQLite](https://sqlite.org/index.html)
database. This database is located, by default, in the user's home directory
under `~/.nixops`. This deployment can be exported to JSON format for backups or
transferring to other machines and imported again from JSON format.

The deployment does not actually store the contents of the network
specification, only the file paths containing the network specification. This
means if the files are updated, NixOps can redeploy the specification from
the changes without needing to have the changes explicitly loaded. It also
means that if the files are moved, NixOps must be notified of the change in
path.

Multiple deployments can be defined each with their own network paths.
The deployment being targeted can be specified to the `nixops` commands either
from the `-d` argument or the `NIXOPS_DEPLOYMENT` environment variable.

Most commands in the `nixops` executable target the entire deployment rather
than specific machines. These commands often provide a `--include` or
`--exclude` argument for targetting a more constrained set of machines within
a deployment.

## NixOps Commands

The following table lists a subset of the subcommands available from the
`nixops` executable which are relevant to these blog posts or may assist
in debugging

| Command | Description |
| --- | --- |
| `create` | create a new deployment |
| `modify` | modify an existing deployment (for example, changing the network file paths) |
| `list` | list all known deployments |
| `info` | show the state of the deployment (including network files passed by `create` and arguments passed by `set-args`) |
| `set-args` | persistently set arguments to the deployment specification |
| `show-arguments` | print the arguments to the network expressions |
| `deploy` | deploy the network configuration |
| `ssh` | login on the specified machine via SSH |
| `destroy` | destroy all resources in the specified deployment |
| `delete` | delete a deployment |
| `export` | export the state of a deployment to JSON format |
| `import` | import deployments into the state file from JSON format |

## Assumptions in these Blog Posts

The commands described in these blog posts have only been tested from
a NixOS machine. There may be problems when, for example, running from
a MacOSX machine. Feedback suggests you may need to be careful about how
the `system` argument gets passed to NixPkgs. Describing how to get other
operating systems working with NixOps is outside the scope of these
blog posts.

The deployments described in these blog posts target
[VirtualBox](https://www.virtualbox.org/). This is for simplicity in
being able to run the deployment on the machine being tested from without
needing a third party cloud service. VirtualBox will require having
some specialised VirtualBox and other virtualisation kernel modules installed.
These blog posts assume you have a working VirtualBox environment already. If
you are using NixOS, virtualbox support can be enabled by specifying
`virtualisation.virtualbox.host.enable = true;` in your NixOs configuration
then rebuilding and rebooting your machine.
