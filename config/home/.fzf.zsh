# Setup fzf
# ---------
if [[ ! "$PATH" == */home/eli/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/eli/.fzf/bin"
fi

source <(fzf --zsh)
