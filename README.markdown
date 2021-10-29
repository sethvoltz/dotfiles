```
.     ██            ██     ████ ██  ██
     ░██           ░██    ░██░ ░░  ░██
     ░██  ██████  ██████ ██████ ██ ░██  █████   ██████
  ██████ ██░░░░██░░░██░ ░░░██░ ░██ ░██ ██░░░██ ██░░░░
 ██░░░██░██   ░██  ░██    ░██  ░██ ░██░███████░░█████
░██  ░██░██   ░██  ░██    ░██  ░██ ░██░██░░░░  ░░░░░██
░░██████░░██████   ░░██   ░██  ░██ ███░░██████ ██████
 ░░░░░░  ░░░░░░     ░░    ░░   ░░ ░░░  ░░░░░░ ░░░░░░

# Assumes Homebrew is installed
git clone git://github.com/sethvoltz/dotfiles ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```

# .dotfiles

The install script will symlink the appropriate files in `.dotfiles` to your home directory.
Everything is configured and tweaked within `~/.dotfiles`, though.

The main file you'll want to change right off the bat is `zsh/zshrc.symlink`, which sets up a few
paths that may be different on your particular machine.

Files in `.dotfiles/bin` will be available in your path. For executables that are private or should
not be added to this repository, use `~/bin` instead. See [Components][#components] below for more
information.

## Topical

Everything's built around topic areas. If you're adding a new area to your forked dotfiles — say,
"Java" — you can simply add a `java` directory and put files in there. Anything with an extension of
`.zsh` will get automatically included into your shell. Anything with an extension of `.symlink`
will get symlinked without extension into `$HOME` when you run `script/bootstrap`. Anything with an
extension of `.config` will be symlinked without extension into `$HOME/.config`.

## Components

There are a few special files in the hierarchy.

* **bin/**: Anything in `bin/` will get added to your `$PATH` and be made available everywhere.
* **topic/\*.zsh**: Any files ending in `.zsh` get loaded into your environment.
* **topic/\*.symlink**: Any files ending in `*.symlink` get symlinked into your `$HOME`. This is so
  you can keep all of those versioned in your dotfiles but still keep those autoloaded files in your
  home directory. These get symlinked in when you run `script/bootstrap`.
* **topic/\*.config**: Any files ending in `*.config` get symlinked into `$HOME/.config`. This is so
  you can keep all of those versioned in your dotfiles but still keep those autoloaded files in your
  home directory. These get symlinked in when you run `script/bootstrap`.
* **topic/\*.path**: Any files ending in `*.path` get loaded after path cleanup has been performed
  to ensure they have priority control over order.
* **topic/completion.sh**: Any files named `completion.sh` get loaded last so that they get loaded
  after we set up zsh autocomplete functions.
* **topic/install.sh**: Any file named `install.sh` will be run during the installation phase of
  `script/bootstrap`, or manually at any time with `script/install`.

## Add-ons

There are a few things I use to make my life awesome. They're not a required dependency, but if you
install them they'll make your life a bit more like a bubble bath.

* If you install the excellent [rbenv](https://github.com/sstephenson/rbenv) to manage multiple
  rubies, your current branch will show up in the prompt. Bonus.

## Bugs

I want this to work for everyone; that means when you clone it down it should work for you even
though you may not have `rbenv` installed, for example. That said, I do use this as *my* dotfiles,
so there's a good chance I may break something if I forget to make a check for a dependency.

If you're brand-new to the project and run into any blockers, please [check out the original
project](https://github.com/holman/dotfiles/) on his repository.

## Thanks

I forked [Zach Holman](http://github.com/holman)'s excellent
[dotfiles](http://github.com/holman/dotfiles) and tweaked for all my needs.

Where possible, I have attributed scripts found around the Internet to their original authors
through comments at the top of the file, or next to some day-saving code I found. Check those
authors out for more of their wonderful work.

## Thoughts

Use this somewhere for something...

```
⠇⠏⠋⠙⠹⠸⠼⠴⠦⠧
```
