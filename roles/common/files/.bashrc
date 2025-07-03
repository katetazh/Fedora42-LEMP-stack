case $- in
*i*) ;;
*) return ;;
esac

if [[ -e /usr/bin/nvim && -x /usr/bin/nvim ]]; then
  export EDITOR="nvim"
fi

if [[ -e /usr/bin/bat ]]; then
  export BAT_THEME="1337"
fi

export FZF_DEFAULT_OPTS="  --multi \
  --highlight-line \
  --no-scrollbar \
  --height=80%
  --style=full \
  --color=dark \
  --layout=reverse \
  --margin=15% \
  --border=rounded \
  --no-scrollbar \
"

shopt -s autocd
shopt -s cdspell
shopt -s histappend
shopt -s extglob
shopt -s dotglob
shopt -s checkhash
shopt -s checkjobs

eval "$(fzf --bash)"


eval "$(starship init bash)"
source "$HOME/libs.d/aliases.sh"

source "$HOME/libs.d/functions.sh"
source "$HOME/libs.d/colors.sh"

eval "$(zoxide init bash)"
