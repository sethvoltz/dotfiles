# Vim dotfiles

This repo was created for two primary reasons: firstly to preserve the
effort placed in getting these configs continually closer to my ideal
and secondly to give back to the community that has enabled me to create
them in the first place. Please feel free to copy, share, reuse, etc.

## Installation

	git clone git://github.com/tauceti/dotvim.git ~/.vim

## Create symlinks

	ln -s ~/.vim/vimrc ~/.vimrc
	ln -s ~/.vim/gvimrc ~/.gvimrc

## Setup Plugins

Switch to the `~/.vim` directory, and fetch submodules:

	cd ~/.vim
	git submodule init
	git submodule update

## Updating Plugins

	cd ~/.vim
	git submodule foreach git pull

# Credits

Many many thanks to the [Janus][] project for providing the foundation
for my `vimrc` file. Thanks also goes to [Tim Pope][] for the
[Pathogen][] plugin and several others that laid the groundwork. Other
additions I will try to mark with URLs inline with the source. If you
see something missing credit, feel free to shoot me a message.

[janus]: https://github.com/carlhuda/janus
[tim pope]: https://github.com/tpope
[pathogen]: https://github.com/tpope/vim-pathogen
