# // If shell is interactive, source the files.
case $- in
*i*) ;;
*) return ;;
esac


# // Selecting default editors.


# // FZF themes.
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
# // Shell options.
shopt -s autocd
shopt -s cdspell
shopt -s histappend
shopt -s extglob
shopt -s dotglob
shopt -s checkhash
shopt -s checkjobs

# // fzf and starship
eval "$(fzf --bash)"


# // Sourcing libraries... 
source "$HOME/libs.d/aliases.sh"
source "$HOME/libs.d/functions.sh"



# // Evaling code here since it needs to be last.
eval "$(zoxide init bash)"
