# Seth does dotfiles

## Dotfiles

This dotfiles organization system is heavily based on @holman's dotfiles repository. [Read his post
on the subject](http://zachholman.com/2010/08/dotfiles-are-meant-to-be-forked/).

## Install

- `git clone git://github.com/tauceti/dotfiles ~/.dotfiles`
- `cd ~/.dotfiles`
- `rake install`

The install rake task will symlink the appropriate files in `.dotfiles` to your home directory.
Everything is configured and tweaked within `~/.dotfiles`, though.

The main file you'll want to change right off the bat is `zsh/zshrc.symlink`, which sets up a few
paths that'll be different on your particular machine.

Files in `.dotfiles/bin` will be added to your path. For executables that are private or should not
be added to this repository, use `~/bin` instead. See [Components][#components] below for more
information.

## Topical

Everything's built around topic areas. If you're adding a new area to your forked dotfiles — say,
"Java" — you can simply add a `java` directory and put files in there. Anything with an extension of
`.zsh` will get automatically included into your shell. Anything with an extension of `.symlink`will
get symlinked without extension into `$HOME` when you run `rake install`.

## Components

There are a few special files in the hierarchy.

* **bin/**: Anything in `bin/` will get added to your `$PATH` and be made available everywhere.
* **topic/\*.zsh**: Any files ending in `.zsh` get loaded into your environment.
* **topic/\*.symlink**: Any files ending in `*.symlink` get symlinked into your `$HOME`. This is so
  you can keep all of those versioned in your dotfiles but still keep those autoloaded files in your
  home directory. These get symlinked in when you run `rake install`.
* **topic/\*.completion.sh**: Any files ending in `completion.sh` get loaded last so that they get
  loaded after we set up zsh autocomplete functions.

## Add-ons

There are a few things I use to make my life awesome. They're not a required dependency, but if you
install them they'll make your life a bit more like a bubble bath.

* If you want some more colors for things like `ls`, install grc: `brew install
  grc`.
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
