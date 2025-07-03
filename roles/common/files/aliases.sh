alias ls='lsd --color=auto'
alias ll='lsd -l --color=auto' # Long list with colors
alias la='lsd -A --color=auto' # List all files with colors
alias l='lsd -F --color=auto'  # List files with colors
alias ls='lsd  --color=auto'   # List files with colors (default)
alias lss='lsd -hsra'          # List files with human-readable sizes
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias vim='nvim'
alias perms='stat -c "%U %G %a %n %s"'
alias ssl_exp='openssl s_client --connect ids.al:993 | openssl x509 -noout -dates'
alias getcli=" awk '{print 11}' "
alias wut_failed="	journalctl --no-pager --since today --grep 'fail|error|fatal' --output json|jq '._EXE' | sort | uniq -c | sort --numeric --reverse --key 1"
alias wut_installed='cat /var/log/pacman.log | grep "$(date +%Y-%m-%d)" | grep -i "installed" | cut -f 1,4 '
alias wut_removed='cat /var/log/pacman.log | grep  "$(date +%Y-%m-%d)" | grep -i "removed" | cut -f 1,4 '
alias ip='ip -c=always'
alias remove='pacman -Qqe | fzf -m --print0 | xargs -0 sudo pacman -Rcns --noconfirm '
alias lsorphans='sudo pacman -Qdt'
alias rmorphans='sudo pacman -Rs $(pacman -Qtdq)'
alias anp='ansible-playbook'
alias grep='grep --color=auto'
alias kys='killall'
alias night_='wlsunset -t 4000 -T 4501 &>/dev/null &'
alias ff='fastfetch'
alias lister='find /etc/systemd -type l -exec readlink -f {} \;'
alias pf='profanity'
alias tl='tldr'
alias copy='wl-copy'
alias sc='screen'
alias cd='z'
alias send='curl -F 'file=@-' 0x0.st'
alias cat='bat -pP'
alias ka='killall'
alias virsh='sudo virsh'
alias _short="PS1=' \n \e[32m\$ \e[0m'"
alias fchange='sed -i "s|/usr/share/foot/themes/.*|/usr/share/foot/themes/$(ls -1 /usr/share/foot/themes | fzf)|" ~/.config/foot/foot.ini'
alias cl_wipe='cliphist wipe'
alias secure_boot='od --address-radix=n --format=u1 /sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c'
alias reset='virsh shutdown archlinux; sleep 3 ; virsh snapshot-revert --domain "archlinux" --snapshotname "ssh-ready-1" ; sleep 2 ; virsh start archlinux'
alias lusers="getent passwd | awk -F: '{print \$1, \$3}' | sort -k2"
alias lfailed="journalctl --no-pager --since today \
--grep 'fail | error | fatal' --output json|jq '._EXE' | \
sort | uniq -c | sort --numeric --reverse --key 1 "
alias ldups='find -not -empty -type f -printf "%s
" |  sort -rn |  uniq -d |  xargs -I{} -n1  find -type f -size {}c -print0 |  xargs -0  md5sum |  sort |  uniq -w32 --all-repeated=separate'
