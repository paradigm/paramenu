ParaMenu
========

Description
-----------

Many tasks done with Vim can be achieved in an extremely keystroke-efficient
manner, but sadly there are exceptions which are a bit more tedious than
necessary.  ParaMenu is a simple framework for creating keystroke-efficient
user interfaces.  It should be fit to be used in most situations where the user
needs to select an item from a list of items.  In practice, this can end up
saving a number of keystrokes compared to quickfix-window-style (e.g. :cwindow)
or cmdline-style (e.g. :ls, :bn, :b) selection.  At the very least, they
require input to be completed with a <cr> whereas ParaMenu does not. ;)

For each item the user may select, ParaMenu will display a series of keys
corresponding to that item.  The user may enter a string from one of these
items to select it, or enter from the paired series of keys to select it.

ParaMenu is bundled with three commands which utilize this functionality:
ParaBuffers for managing buffers, ParaTags for managing tags, and ParaQuickFix,
an alternate interface for :cwindow.

Installation
------------

There are a few ways you could go about installing ParaMenu, all of which are
fairly standard for Vim plugins:

* Untar/unzip the ParaMenu package in your vimfiles
  directory.  (See ":help vimfiles".)
* Untar/unzip the ParaMenu package in some temporary location, then manually
  copy the ParaMenu.vim file into the "plugin" directory under your vimfiles
  directory and the ParaMenu.txt file into the "doc" directory under your
  vimfiles directory.
* If you use the pathogen vim plugin, you can untar/unzip the ParaMenu package
  and place it within its own folder in the "bundle" directory under your
  vimfiles directory.

On a Unixy system without pathogen, the ParaMenu.vim file should be located at:

	~/.vim/plugin/ParaMenu.vim

On a Unixy system with pathogen, the ParaMenu.vim file should be located at:

	~/.vim/bundle/ParaMenu/plugin/ParaMenu.vim

On a Windows system without pathogen, the ParaMenu.vim file should be located at:

	%USERPROFILE%\vimfiles\plugin\ParaMenu.vim

On a Windows system with pathogen, the ParaMenu.vim file should be located at:

	%USERPROFILE%\vimfiles\bundle\ParaMenu\plugin\ParaMenu.vim

Further Documentation
---------------------

Once installed, further documentation for ParaMenu and its bundled commands
(ParaBuffers, ParaTags and ParaQuickFix) can be viewed by running the command
":help ParaMenu.txt"

![paramenu example](https://raw.github.com/paradigm/paramenu/images/images/paramenu.png)
