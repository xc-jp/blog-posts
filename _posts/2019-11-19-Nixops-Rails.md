---
layout: single
title: Deploying a Ruby on Rails Application with NixOps
issue-date: 2019.11.19
author: Robert Prije
tags: ["Ruby on Rails", "Nix", "NixOps"]
excerpt: How to use NixOps to deploy Ruby on Rails application
---

[Rails](https://rubyonrails.org/) applications depend on installed Ruby
libraries provided by gems. Usually gems are installed imperatively. However,
we want to leverage NixOps to manage both Rails applications and their gem
dependencies in its customary declarative and reproducable manner.

In this blog post we will examine how to use Nix and NixOps to:
* initialise a Rails application
* script the starting of that Rails application
* deploy the Rails application and starter script to a host.

Code has been written to assist in describing this process. That code is
available at
[https://github.com/xc-jp/blog-post-code](https://github.com/xc-jp/blog-post-code)
under the `Rails` subdirectory. To keep this blog post reasonably high level
and easy to understand, only sections of code relevant to the topics being
discussed will be pasted along with the filename in the repository the code
segment can be found in. If you are following along with the blog, you are
encouraged to check out a copy of the repository and run the provided commands
from within the checked out `Rails` directory as well as explore the code
in the `Rails` directory.

## Gems

Rails dependencies and Rails itself are supplied through gems. NixOS supports
gems through an application named
[Bundix](https://github.com/nix-community/bundix). Bundix itself builds upon
[Bundler](https://bundler.io/), a management system for projects using gems.
What Bundix provides on top of Bundler is management of a `gemset.nix` file
which associates each gem with a hash to allow nix to guarantee the same
dependencies will be used whenever the project is built.

The following script found under `update_gemset_nix.sh` takes a Bundler
`Gemfile` and produces a Bundler `Gemfile.lock` and Bundix `gemset.nix`:

```
#!/usr/bin/env bash

set -e -u -o pipefail

GEMFILE="${1:-}"

[[ -n $GEMFILE ]] || (echo "Usage: $0 GEMFILE"; exit 1)

[[ -e $GEMFILE ]] || (echo "Couldn't find $GEMFILE"; exit 1)

[[ $(basename $GEMFILE) == Gemfile ]] || \
  (echo "$GEMFILE doesn't look like a Gemfile"; exit 1)

NIXPKG_FILE="$(dirname $(readlink -f $0))/package-set.nix"

cd $(dirname $GEMFILE)

nix run -f "$NIXPKG_FILE" bundler -c bundler lock

rm -f gemset.nix

nix run -f "$NIXPKG_FILE" bundix -c bundix
```

The `Gemfile`, `Gemfile.lock` and the `gemset.nix` can then be fed into the
Nix function `bundlerEnv`. `overlay.nix` contains a function `rubyEnv` which
takes a directory containing these files and uses `bundlerEnv` to produce
a derivation providing the gems described in the `Gemfile`:

```
  rubyEnv = dir: super.bundlerEnv {
    name = "example-ruby-env";
    inherit (self) ruby;
    gemfile = dir + /Gemfile;
    lockfile = dir + /Gemfile.lock;
    gemset = dir + /gemset.nix;
  };
```

## Initialising a Rails Application

Initiating a Rails application within nix requires some bootstrapping. A Rails
application generates its own gem dependencies upon initialisation but at the
same time is itself installed as a gem.

We create a `Gemfile` specifically for bootstrapping:

```
source 'https://rubygems.org'

ruby '2.6.5'

gem 'rails', '~> 6.0.0'
```

We also create a shell environment with access to the Rails gem. In
`overlays.nix`:

```
  initShell = mkShell { buildInputs = [
    (self.rubyEnv ./.)
  ];};
```

Finally, the script `new_rails_app.sh` contains the steps needed for
bootstrapping a new Rails application:

```
#!/usr/bin/env bash

set -e -u -o pipefail

cd "$(dirname $0)"

./update_gemset_nix.sh ./Gemfile

nix-shell package-set.nix -A initShell --run "rails new example --skip-bundle --skip-bootsnap --skip-webpack-install"

./update_gemset_nix.sh ./example/Gemfile

cd example

nix-shell ../package-set.nix -A devShell --run "rails webpacker:install"
```

This calls the previously mentioned `update_gemset_nix.sh` on the Gemfile
used for bootstrapping. `update_gemset_nix.sh` initialises Gemfile.lock, and
gemset.nix giving us everything we need to be able to enter into a Nix shell
containing Rails. We use that nix shell to initialise the Rails application
with `rails new example` which will put the Rails application under a
subdirectory named `example`.

The created `example` directory will contain its own `Gemfile` along with
the rest of the initialised application. We run `update_gemset_nix.sh` on
this new `Gemfile` to generate another `Gemfile.lock` and `gemset.nix` this
time with for creating a Nix shell environment with all dependencies required
for the Rails application to run.

The `--skip-bootsnap` and `--skip-webpack-install` arguments are necessary
because Bootsnap and Webpack rely on the gems found in the newly created
`Gemfile` but our initialisation Nix environment doesn't have access to
those. So instead, we create the Rails application without them.

[Bootsnap](https://github.com/Shopify/bootsnap) is an optimising cache library
that's not critical for the running of a Rails Application. Getting this working
is left as an exercise for the reader.

[Webpack](https://webpack.js.org/) provides Rails' JavaScript environment and
is critical for Rails to run. We manually install it from within our newly
created Nix shell environment providing all Rails' dependencies with the command
`nix-shell ../package-set.nix -A devShell --run "rails webpacker:install"`

Let's run `new_rails_app.sh` now:

```
$ ./new_rails_app.sh
Fetching gem metadata from https://rubygems.org/.............
Fetching gem metadata from https://rubygems.org/.
Resolving dependencies...
[...]
Done in 4.83s.
Webpacker successfully installed 🎉 🍰

$ ls example
app              config.ru     gemset.nix    package.json       README.md  vendor
babel.config.js  db            lib           postcss.config.js  storage    yarn.lock
bin              Gemfile       log           public             test
config           Gemfile.lock  node_modules  Rakefile           tmp
```

Now that we've initialised the Rails application, we no longer need the
bootstrap `Gemfile` in the top-level directory. From now on we'll only need the
generated `Gemfile` within the `example` directory. We can enter into a shell
within which the `rails` command and dependencies needed by our application are
available with the command:

```
$ nix-shell ./package-set.nix -A devShell
```

If extra dependencies need to be added to `Gemfile`, `update_gemset_nix.sh` can
regenerate the `Gemfile.lock` and `gemset.nix` needed to ensure the environment
receives the updated dependencies:

```
$ ./update_gemset_nix.sh ./example/Gemfile
```

## Rails Startup Script

Next we'll create a conventient way for entering into the Rails environment and
starting the web service. This is accomplished with a simple shell script
constructed within Nix. In `overlay.nix`:

```
  railsApp = super.writeShellScriptBin "start-app" ''
    set -e -u -o pipefail
    export APP_PATH="''${APP_PATH:-$(mktemp -p /tmp -d rb.XXXXXX)}"

    cd $APP_PATH

    tar -xzf ${self.rubySrcTarball}
    chmod -R u+w $APP_PATH

    export PATH=$PATH:${self.yarn}/bin
    ${self.rubyEnv rubySource}/bin/rails server --binding 0.0.0.0 --port 3000
  '';
```

Here we initialise an `APP_PATH` environment variable for use by Rails. We can
supply it as an environment variable outside the script, otherwise it will
be initialised as a temporarily created path.

We then unpack `rubySrcTarball` which is just a tar'd version of everything in
the example directory:

```
let
[...]
  rubySource = ./example;
[...]
in

{

  rubySrcTarball = buildTar "rails-blog-example" rubySource;

```

We then ensure the `yarn` binary is available to Rails and start the Rails
server listening on all addresses and on port 3000.

Testing it out:

```
$ nix-build ./package-set.nix -A railsApp
[...]
/nix/store/dxxacgjj1b40sy6qwx0d1maaf15qpiwp-start-app
$ /nix/store/dxxacgjj1b40sy6qwx0d1maaf15qpiwp-start-app/bin/start-app
=> Booting Puma
=> Rails 6.0.1 application starting in development
=> Run `rails server --help` for more startup options
Puma starting in single mode...
* Version 4.3.0 (ruby 2.6.5-p114), codename: Mysterious Traveller
* Min threads: 5, max threads: 5
* Environment: development
* Listening on tcp://0.0.0.0:3000
Use Ctrl-C to stop
```

Navigating a web browser to http://localhost:3000/ now shows the default Rails
application welcome page.

## Deploying a Rails Application

Finally, we'll use NixOps to deploy our script and the Rails application
environment to a host. The minimal logical network specification looks like
this is in rrails-nixops.nix:

```
{
  network.description = "Example";

  example =
    { pkgs, ... }:

    {

      nixpkgs.overlays = [
        (import ./overlay.nix)
      ];

      environment.systemPackages = [
        pkgs.railsApp
      ];

      networking.firewall.allowedTCPPorts = [ 3000 ];

    };
}
```

We see here why we've been placing all our packages in an
[overlay](https://nixos.org/nixpkgs/manual/#chap-overlays) within `overlay.nix`.
Overlays allow us to take a nixpkgs package set and make modifications to it.
In short, an overlay is a function taking a `self` argument representing the
final package set after all modifications have been made, and a `super` argument
representing the package set before the modifications in the current overlay
have been made. `self` is able to refer to the final package set because
Nix is a lazy language. The contents of `self` will not be computed until
needed.

The file `package-set.nix` used `overlay.nix` to define a a NixPkgs
package set extended with our own packages for use by `shell.nix` and many of
our Nix commands above:

```
{ pkgs ? (import ./pkgs.nix) }:

import pkgs { overlays = [ (import ./overlay.nix) ]; }
```

Now we use that same `overlay.nix` in our logical network definition to
extend the NixPkgs provided to NixOps with our same modifications.

Having made our modifications with `overlay.nix`, we have access to
`pkgs.railsApp` which we make available as a system package.

Finally, we ensure port 3000 is open on the host firewall allowing our
Rails application to be reached from outside the virtual host.

Now we try deploying our host and starting the app:

```
$ nix-shell
# example-vbox.nix is the same as from earlier blog posts
$ nixops create ./example-vbox.nix rrails-nixops.nix
$ nixops deploy --force-reboot
example> creating VirtualBox VM...
[...]
example> activation finished successfully
example> deployment finished successfully
$ nixops ssh example
# ip addr show | grep inet
[...]
inet 192.168.56.105/24 brd 192.168.56.255 scope global dynamic noprefixroute enp0s8
[...]
# start-app
=> Booting Puma
=> Rails 6.0.1 application starting in development
=> Run `rails server --help` for more startup options
Puma starting in single mode...
* Version 4.3.0 (ruby 2.6.5-p114), codename: Mysterious Traveller
* Min threads: 5, max threads: 5
* Environment: development
* Listening on tcp://0.0.0.0:3000
Use Ctrl-C to stop
```

Then navigating to http://192.168.56.105:3000/ (with the IP address found
through the above `ip addr show` command) successfully displays our Rails
applicaiton start page.
