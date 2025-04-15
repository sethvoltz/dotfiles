[ -f $HOMEBREW_PREFIX/share/forgit/forgit.plugin.zsh ] && source $HOMEBREW_PREFIX/share/forgit/forgit.plugin.zsh

# Fix from: https://github.com/wfxr/forgit/issues/121#issuecomment-725358145
export FORGIT_PAGER='delta --side-by-side -w ${FZF_PREVIEW_COLUMNS:-$COLUMNS}'
