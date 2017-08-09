# From https://github.com/cehoffman/dotfiles/blob/f547809430ddedae4b4816743556a2293e99aca2/zsh/config
# Uses https://github.com/sickill/stderred -- See ./install.sh for installation

# NOTE! This currently breaks fzf -- revisit periodocally to see if a fix is available.

# if [[ -o interactive ]]; then
#   # Color all stderr lines red only when interactive. The guard prevents
#   # a proliferation of processes when using exec to replace the current shell
#   # with a fresh instance
#   export STDERRED_ESC_CODE=$(echo -e '\e[;91m')
#   if [[ -f ~/Development/DotfilesBuild/stderred/build/libstderred.dylib ]]; then
#     typeset -TgU DYLD_INSERT_LIBRARIES dyld_insert_libraries
#     dyld_insert_libraries[1,0]=(~/Development/DotfilesBuild/stderred/build/libstderred.dylib(-.))
#     export DYLD_INSERT_LIBRARIES
#   fi
# else
#   # Remove the stderr coloring libs from the env variables to prevent
#   # complaints on setuid/setgid programs
#   if (( $#dyld_insert_libraries )); then
#     dyld_insert_libraries=("${(@)dyld_insert_libraries:#$HOME/Development/DotfilesBuild/stderred/build/libstderred.dylib}")
#   fi
# fi
