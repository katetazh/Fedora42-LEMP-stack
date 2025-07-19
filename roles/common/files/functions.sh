#!/usr/bin/env bash







misc::addr(){
	local arg ; 
	arg="${1:-US}" 
	curl -s -X GET https://api.testingbot.com/v1/free-tools/random-address?"${arg}" | jq -r
}




vm_reset(){
  virsh snapshot-revert --domain core2 --snapshotname "ansible-readyy" || return 11 
  virsh snapshot-revert --domain core1 --snapshotname "ansible-readyy" || return 12
}


vm_stop(){
  virsh shutdown core1 || return 11 
  virsh shutdown core2 || return 12 
}


vm_start(){
  virsh start core1 || return 11 
  virsh start core2 || return 12
}



ex() {

	[[ $# -eq 0 ]] && {
		echo "Please enter at least 1 argument!"
		return 1
	}

	local files=$@

	for file in "${files[@]}"; do
		if ! [[ -f "${file}" ]]; then
			echo "${file} not a file" && continue
		fi

		case $file in
		*.tar.bz2 | *.tbz2) tar xvjf "$file" ;;
		*.tar.gz | *.tgz) tar xvzf "$file" ;;
		*.tar.xz | *.txz) tar xvJf "$file" ;;
		*.tar) tar xvf "$file" ;;
		*.gz) gunzip "$file" ;;
		*.bz2) bunzip2 "$file" ;;
		*.Z) uncompress "$file" ;;
		*.zip) unzip "$file" ;;
		*.rar) unrar x "$file" ;;
		*.7z) 7z x "$file" ;;
		*) echo "Can't extract '$file'..." ;;
		esac

	done
}


sys::pslogs(){
 { while IFS= read -r pid ; do    echo -e  "\n\n Process: $( cat /proc/$pid/stat | awk '/\(.*\)/ { print $2 }') $( pslog $pid 2>/dev/null ) " ; done < <( ps faux | awk '{ print $2 }' | uniq ) ;} 2>/dev/null | grep -iB 1 'log path:' 
}




get_local_ip() {
  # Start with the 'ip' command
  if hash ip; then
    ip -o -4 a show up | awk -F '[ /]' '/brd/{print $7}'
    return "${?}"
  # Failover to 'ifconfig'
  elif hash ifconfig; then
    ifconfig -a \
      | awk -F ':' '/inet addr/{print $2}' \
      | awk '{print $1}' \
      | grep -v "127.0.0.1"
    return "${?}"
  fi

  # If we get to this point, we hope that DNS is working
  if hash nslookup; then
    # Because nslookup exits with 0 even on failure, we test for failure first
    if nslookup "$(hostname)" 2>&1 \
         | grep -E "Server failed|SERVFAIL|can't find" >/dev/null 2>&1; then
      printf '%s\n' "Could not determine the local IP address"
      return 1
    else
      nslookup "$(hostname)" \
        | awk -F ':' '/Address:/{gsub(/ /, "", $2); print $2}' \
        | grep -v "#"
      return "${?}"
    fi
  fi

  # If we get to this point, return nothing but a failure code
  return 1
}







D(){
  if [[ -d $1 ]]; then
    cd -P "$1"
  elif [[ -e $1 ]]; then
    cd -P "${1%/*?}"
  else
    mkdir -p "$1"
    cd -P "$1"
  fi
}



psgrep() {
  [[ "${1:?Usage: psgrep [search term]}" ]]
  ps auxf | grep -i "[${1:0:1}]${1:1}" | awk '{print $2}'
}





stooge(){
  pattern="${*}"
  rg -i "${pattern:-}" ~/Documents/leaks/ | bat -pP
}

ipInfo(){
  [[ -n "${@}" ]] && { 
  curl -s https://ipinfo.io/${1}/json | jq -r
}
}


anichange() {
	local animations_dir
	animations_dir="$HOME/.config/hypr/animations"
	local animation_name=$(ls "${animations_dir}" | fzf --prompt "Animations for hyprland: ")
	local animation="${animations_dir}/${animation_name}"
	cp "${animation}" "$HOME/.config/hypr/animations.conf" || (echo "Failed" && return 1)
}

function log::try_catch() {
  local line="${LINENO:-}"
  local code="${?:-}"
  if [[ -z "${line}" ]] || [[ -z "${code}" ]]; then
    echo "catch failed: Invalid Params!" >&2
    exit 1
  fi
  case "${code}" in
  1) msg="General error" ;;
  2) msg="Misuse of shell builtins" ;;
  126) msg="Command invoked cannot execute" ;;
  127) msg="Command not found" ;;
  128) msg="Invalid exit argument" ;;
  130) msg="Script terminated by Control-C" ;;
  137) msg="Killed by SIGKILL" ;;
  *) msg="Unknown error (code: ${code})" ;;
  esac
  echo "Error: ${msg} on line: ${line}" >&2
  exit "${code}"
}


dns::check(){
  local domain="${1}"
  local regex="^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"
  {
  for x in A AAAA CNAME MX NS TXT SOA PTR ; do
    echo "$x records:"
    curl -s -H "accept: application/dns-json" "https://dns.google/resolve?name=$domain&type=$x" | jq -r '.Answer[].data'
    echo
  done
  } 2>/dev/null
}



# // PREFERED TO BE USED AROUND A WRAPPED SCRIPT. 
log::info() {
  echo "[$(date +"%Y-%m-%d-%H-%M-%S")]" "$*" >&1
}

log::warning(){
  echo "$(date +"%Y-%m-%d-%H-%M-%S")] [WARNING]" "$*" >&2
}

log::err(){
  echo "$(date +"%Y-%m-%d-%H-%M-%S")] [ERROR]" "$*" >&2
}

misc::ssl_exp(){
openssl s_client --connect "$1":"$2" 2>/dev/null | openssl x509 -noout -dates 
}

# // FIND LIBRARIES FOR AN EXECUTABLE. 
function misc::flibs() {
  if (($# > 0)); then
    for arg in "${@}"; do
     if [[ -n "${arg}" ]]; then
        ldd "${arg}" | \grep /usr/lib | awk '{print $3}' || return 1
      fi
    done
  fi
}

# // works fine if you don't need any fancy syntax.
text::field(){
    awk -F "${2:- }" '{ print $'"${1:-1}"'}'
}

# // No need to fork out to a gnu util. 
str::head(){
    mapfile -tn "${2:-20}" line < "${1:-/dev/stdin}"
    printf '%s\n' "${line[@]}" 

}


str::head(){
  local num="${1:-20}"
  local src="${2:-/dev/stdin}"
  mapfile -tn "${num}" line < "${src}"
  printf '%s\n' "${line[@]}}"
}



# // Get the length of a string. 
str::len(){
    if (( $# > 0 )) ; then 
            for x in "${@}" ; do 
                    echo -e "${#x}" 
            done 
    fi 
}

str::tail(){
  mapfile -tn 0 line < "${2:-/dev/stdin}" 
  printf "%s\n" "${line[@]: -"${1:-20}"}"
}

text::lines(){
  mapfile -tn 0 lines < "${1:-/dev/stdin}" 
  echo -e "${#lines[@]}\n" 
}

text::trun(){
  printf '%s\n' "${1//${2:-}}"
}


## reverse the case same as `tr a-z A-Z` 
text::rev_case(){
  input="${1:-$(cat -)}" 
  echo -e "${input~~}\n"
}

## will rewrite them at one point IG
text::lstrip() {
    printf '%s\n' "${1##$2}"
}

## will rewrite them at one point IG
text::rstrip() {
    printf '%s\n' "${1%%$2}"
}

## regex 
text::regex() {
    [[ $1 =~ $2 ]] && {
    echo -e "${BASH_REMATCH[1]}\n"
  }
} 

# // Only to be used with pipes. 
text::tolower() {
  local input="${1:-$(</dev/stdin)}"
  echo "${input,,}" 
}
# // Only to be used with pipes.
text::toupper(){
  local input="${1:-$(</dev/stdin)}"  
  echo -e "${input^^}\n" 
} 

## split items to an array 
text::split() {
  IFS=$'\n' read -d "" -ra arr <<<"${1//$2/$'\n'}"
  printf '%s\n' "${arr[@]}"
}

text::remove_arr_dups() {
    declare -A tmp_array
    for i in "$@"; do
        [[ $i ]] && IFS=" " tmp_array["${i:- }"]=1
    done
    printf '%s\n' "${!tmp_array[@]}"
}

text::random_arr_element() {
    local arr=("$@")
    printf '%s\n' "${arr[RANDOM % $#]}"
}

# // Trim leading and trailing whitespaces.
text::trimm() {
    : "${1#"${1%%[![:space:]]*}"}"
    : "${_%"${_##*[![:space:]]}"}"
    printf '%s\n' "$_"
}

# // Trim all occurrences of whitespaces. 
text::trim_all() {
    set -f
    set -- $*
    printf '%s\n' "$*"
    set +f
}


stat::get_oldest(){
  local oldest 
  for x in "${1}" ; do 
      [[ -f "${x}" ]] || continue 
      if [[ -z "${x}" ]] ; then 
          oldest="${x}" 
      fi 
      if [[ "${x}" -ot "${oldest}" ]] ; then 
          oldest="${x}" 
      else 
          continue 
      fi 
  done 
}

stat::get_latest(){
  unset -v latest;  
  for x in ${1:-./}* ; do 
      [[ -f "${x}" ]] || continue 
      [[ -z "${x}" ]] && latest="${x}" 
      if [[ "${x}" -nt "${latest}" ]] ; then 
        latest="${x}" 
      else 
        continue 
      fi 
  done  
  echo "${latest}" 
}


# // Function to sort files based on their timestamps. 
# // Shell requires dotglob and nullglob to be set. 
stat::get_sorted_new(){
  local files; files=(*)
  for ((i = 0; i < ${#files[@]}; i++)); do
    for ((j = i + 1; j < ${#files[@]}; j++)); do
      if [[ "${files[j]}" -ot "${files[i]}" ]]; then
        temp="${files[i]}"
        files[i]="${files[j]}"
        files[j]="$temp"
      fi
    done
done

for f in "${files[@]}"; do
  [[ -f "$f" ]] && echo "$f"
done
}

# // Check if a directory is empty or not. 
# // Executing in a subshell to not fuck up the environment. 
stat::is_empty_dir(){
  if ( shopt -s nullglob dotglob ; f=(*) ; (( ${#f[@]} ))) ; then 
      echo "Not empty!" 
      return 0 
  else 
      echo "Empty"
      return 1  
  fi 
}

:() {
	[[ ${1:--} != ::* ]] && return 0
	printf '%s\n' "${*}" >&2
}



misc::alachange(){
  local -r base_path="/home/admin/.config/alacritty/themes/"
  local -r config="${base_path}$( ls -1 ${base_path} | fzf )" 
  [[ -n "${config}" ]] && cp "${config}" "/home/admin/.config/alacritty/alacritty.toml"
}

misc::noerr(){
  eval "${*}" 2>/dev/null
}


ssh::start_agent(){
  eval "$(ssh-agent)" 
  ssh-add ~/.ssh/id_rsa
}


file::fcat(){
  find . -type f -name "${@}" -print0 | xargs -0 -I {} sh -c '
  echo "${@}"
  bat -pP "$@";
' _ {}
}

text::tolower() {
	local input="${1:-$(cat -)}"
	echo "${input,,}" 
}

text::toupper(){
	local input="${1:-$(cat -)}"	
	echo -e "${input^^}\n" 
} 
text::split() {
  IFS=$'\n' read -d "" -ra arr <<<"${1//$2/$'\n'}"
  printf '%s\n' "${arr[@]}"
}
text::remove_arr_dups() {
    declare -A tmp_array
    for i in "$@"; do
        [[ $i ]] && IFS=" " tmp_array["${i:- }"]=1
    done
    printf '%s\n' "${!tmp_array[@]}"
}
text::random_arr_element() {
    local arr=("$@")
    printf '%s\n' "${arr[RANDOM % $#]}"
}
text::trimm() {
    # Usage: trim_string "   example   string    "
    : "${1#"${1%%[![:space:]]*}"}"
    : "${_%"${_##*[![:space:]]}"}"
    printf '%s\n' "$_"
}
text::trim_all() {
    set -f
    set -- $*
    printf '%s\n' "$*"
    set +f
}

mpg(){
  man -S 1,8,9 -k . | awk '{print $1}' | fzf | while IFS= read -r line ;do 
      [[ -n "${line}" ]] &&  {
        man -Tpdf "${line}" | zathura - >/dev/null 2>&1 & 
        disown 
      }
  done 
}
#!/usr/bin/env bash

# =============================================================================
# MISC FUNCTIONS
# =============================================================================

misc::addr(){
    local arg ; 
    arg="${1:-US}" 
    curl -s -X GET https://api.testingbot.com/v1/free-tools/random-address?"${arg}" | jq -r
}

misc::ssl_exp(){
    openssl s_client --connect "$1":"$2" 2>/dev/null | openssl x509 -noout -dates 
}

misc::flibs() {
    if (($# > 0)); then
        for arg in "${@}"; do
            if [[ -n "${arg}" ]]; then
                ldd "${arg}" | \grep /usr/lib | awk '{print $3}' || return 1
            fi
        done
    fi
}

misc::alachange(){
    local -r base_path="/home/admin/.config/alacritty/themes/"
    local -r config="${base_path}$( ls -1 ${base_path} | fzf )" 
    [[ -n "${config}" ]] && cp "${config}" "/home/admin/.config/alacritty/alacritty.toml"
}

misc::noerr(){
    eval "${*}" 2>/dev/null
}

# =============================================================================
# VM MANAGEMENT
# =============================================================================

vm_reset(){
    virsh snapshot-revert --domain core2 --snapshotname "ansible-readyy" || return 11 
    virsh snapshot-revert --domain core1 --snapshotname "ansible-readyy" || return 12
}

vm_stop(){
    virsh shutdown core1 || return 11 
    virsh shutdown core2 || return 12 
}

vm_start(){
    virsh start core1 || return 11 
    virsh start core2 || return 12
}

# =============================================================================
# EXTRACTION
# =============================================================================

ex() {
    [[ $# -eq 0 ]] && {
        echo "Please enter at least 1 argument!"
        return 1
    }

    local files=$@

    for file in "${files[@]}"; do
        if ! [[ -f "${file}" ]]; then
            echo "${file} not a file" && continue
        fi

        case $file in
        *.tar.bz2 | *.tbz2) tar xvjf "$file" ;;
        *.tar.gz | *.tgz) tar xvzf "$file" ;;
        *.tar.xz | *.txz) tar xvJf "$file" ;;
        *.tar) tar xvf "$file" ;;
        *.gz) gunzip "$file" ;;
        *.bz2) bunzip2 "$file" ;;
        *.Z) uncompress "$file" ;;
        *.zip) unzip "$file" ;;
        *.rar) unrar x "$file" ;;
        *.7z) 7z x "$file" ;;
        *) echo "Can't extract '$file'..." ;;
        esac
    done
}

# =============================================================================
# SYSTEM FUNCTIONS
# =============================================================================

sys::pslogs(){
    { while IFS= read -r pid ; do    
        echo -e  "\n\n Process: $( cat /proc/$pid/stat | awk '/\(.*\)/ { print $2 }') $( pslog $pid 2>/dev/null ) " 
    done < <( ps faux | awk '{ print $2 }' | uniq ) ;} 2>/dev/null | grep -iB 1 'log path:' 
}

get_local_ip() {
    # Start with the 'ip' command
    if hash ip; then
        ip -o -4 a show up | awk -F '[ /]' '/brd/{print $7}'
        return "${?}"
    # Failover to 'ifconfig'
    elif hash ifconfig; then
        ifconfig -a \
            | awk -F ':' '/inet addr/{print $2}' \
            | awk '{print $1}' \
            | grep -v "127.0.0.1"
        return "${?}"
    fi

    # If we get to this point, we hope that DNS is working
    if hash nslookup; then
        # Because nslookup exits with 0 even on failure, we test for failure first
        if nslookup "$(hostname)" 2>&1 \
             | grep -E "Server failed|SERVFAIL|can't find" >/dev/null 2>&1; then
            printf '%s\n' "Could not determine the local IP address"
            return 1
        else
            nslookup "$(hostname)" \
                | awk -F ':' '/Address:/{gsub(/ /, "", $2); print $2}' \
                | grep -v "#"
            return "${?}"
        fi
    fi

    # If we get to this point, return nothing but a failure code
    return 1
}

psgrep() {
    [[ "${1:?Usage: psgrep [search term]}" ]]
    ps auxf | grep -i "[${1:0:1}]${1:1}" | awk '{print $2}'
}

# =============================================================================
# DIRECTORY FUNCTIONS
# =============================================================================

D(){
    if [[ -d $1 ]]; then
        cd -P "$1"
    elif [[ -e $1 ]]; then
        cd -P "${1%/*?}"
    else
        mkdir -p "$1"
        cd -P "$1"
    fi
}

# =============================================================================
# SEARCH FUNCTIONS
# =============================================================================

stooge(){
    pattern="${*}"
    rg -i "${pattern:-}" ~/Documents/leaks/ | bat -pP
}

ipInfo(){
    [[ -n "${@}" ]] && { 
        curl -s https://ipinfo.io/${1}/json | jq -r
    }
}

# =============================================================================
# ANIMATION FUNCTIONS
# =============================================================================

anichange() {
    local animations_dir
    animations_dir="$HOME/.config/hypr/animations"
    local animation_name=$(ls "${animations_dir}" | fzf --prompt "Animations for hyprland: ")
    local animation="${animations_dir}/${animation_name}"
    cp "${animation}" "$HOME/.config/hypr/animations.conf" || (echo "Failed" && return 1)
}

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log::try_catch() {
    local line="${LINENO:-}"
    local code="${?:-}"
    if [[ -z "${line}" ]] || [[ -z "${code}" ]]; then
        echo "catch failed: Invalid Params!" >&2
        exit 1
    fi
    case "${code}" in
    1) msg="General error" ;;
    2) msg="Misuse of shell builtins" ;;
    126) msg="Command invoked cannot execute" ;;
    127) msg="Command not found" ;;
    128) msg="Invalid exit argument" ;;
    130) msg="Script terminated by Control-C" ;;
    137) msg="Killed by SIGKILL" ;;
    *) msg="Unknown error (code: ${code})" ;;
    esac
    echo "Error: ${msg} on line: ${line}" >&2
    exit "${code}"
}

log::info() {
    echo "[$(date +"%Y-%m-%d-%H-%M-%S")]" "$*" >&1
}

log::warning(){
    echo "$(date +"%Y-%m-%d-%H-%M-%S")] [WARNING]" "$*" >&2
}

log::err(){
    echo "$(date +"%Y-%m-%d-%H-%M-%S")] [ERROR]" "$*" >&2
}

# =============================================================================
# DNS FUNCTIONS
# =============================================================================

dns::check(){
    local domain="${1}"
    local regex="^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"
    {
        for x in A AAAA CNAME MX NS TXT SOA PTR ; do
            echo "$x records:"
            curl -s -H "accept: application/dns-json" "https://dns.google/resolve?name=$domain&type=$x" | jq -r '.Answer[].data'
            echo
        done
    } 2>/dev/null
}

# =============================================================================
# TEXT PROCESSING FUNCTIONS
# =============================================================================

text::field(){
    awk -F "${2:- }" '{ print $'"${1:-1}"'}'
}

text::head(){
    mapfile -tn "${2:-20}" line < "${1:-/dev/stdin}"
    printf '%s\n' "${line[@]}" 
}

text::len(){
    if (( $# > 0 )) ; then 
        for x in "${@}" ; do 
            echo -e "${#x}" 
        done 
    fi 
}

text::tail(){
    mapfile -tn 0 line < "${2:-/dev/stdin}" 
    printf "%s\n" "${line[@]: -"${1:-20}"}"
}

text::lines(){
    mapfile -tn 0 lines < "${1:-/dev/stdin}" 
    echo -e "${#lines[@]}\n" 
}

text::trun(){
    local input pattern 
    input="${2:-$(cat -)}" 
    pattern="${1:-}"  
    echo -e "${input//$pattern/}" 
}

text::strip(){
    local input pattern 
    input="${2:-$(cat -)}"
    pattern="${1:-}"  
    echo -e "${input/$pattern/}"
}

text::rev_case(){
    input="${1:-$(cat -)}" 
    echo -e "${input~~}\n"
}

text::lstrip() {
    printf '%s\n' "${1##$2}"
}

text::rstrip() {
    printf '%s\n' "${1%%$2}"
}

text::regex() {
    [[ $1 =~ $2 ]] && {
        echo -e "${BASH_REMATCH[1]}\n"
    }
} 

text::tolower() {
    local input="${1:-$(</dev/stdin)}"
    echo "${input,,}" 
}

text::toupper(){
    local input="${1:-$(</dev/stdin)}"  
    echo -e "${input^^}\n" 
} 

text::split() {
    IFS=$'\n' read -d "" -ra arr <<<"${1//$2/$'\n'}"
    printf '%s\n' "${arr[@]}"
}

text::remove_arr_dups() {
    declare -A tmp_array
    for i in "$@"; do
        [[ $i ]] && IFS=" " tmp_array["${i:- }"]=1
    done
    printf '%s\n' "${!tmp_array[@]}"
}

text::random_arr_element() {
    local arr=("$@")
    printf '%s\n' "${arr[RANDOM % $#]}"
}

text::trimm() {
    : "${1#"${1%%[![:space:]]*}"}"
    : "${_%"${_##*[![:space:]]}"}"
    printf '%s\n' "$_"
}

text::trim_all() {
    set -f
    set -- $*
    printf '%s\n' "$*"
    set +f
}

# =============================================================================
# STAT FUNCTIONS
# =============================================================================

stat::get_oldest(){
    local oldest 
    for x in "${1}" ; do 
        [[ -f "${x}" ]] || continue 
        if [[ -z "${x}" ]] ; then 
            oldest="${x}" 
        fi 
        if [[ "${x}" -ot "${oldest}" ]] ; then 
            oldest="${x}" 
        else 
            continue 
        fi 
    done 
}

stat::get_latest(){
    unset -v latest;  
    for x in ${1:-./}* ; do 
        [[ -f "${x}" ]] || continue 
        [[ -z "${x}" ]] && latest="${x}" 
        if [[ "${x}" -nt "${latest}" ]] ; then 
            latest="${x}" 
        else 
            continue 
        fi 
    done  
    echo "${latest}" 
}

stat::get_sorted_new(){
    local files; files=(*)
    for ((i = 0; i < ${#files[@]}; i++)); do
        for ((j = i + 1; j < ${#files[@]}; j++)); do
            if [[ "${files[j]}" -ot "${files[i]}" ]]; then
                temp="${files[i]}"
                files[i]="${files[j]}"
                files[j]="$temp"
            fi
        done
    done

    for f in "${files[@]}"; do
        [[ -f "$f" ]] && echo "$f"
    done
}

stat::is_empty_dir(){
    if ( shopt -s nullglob dotglob ; f=(*) ; (( ${#f[@]} ))) ; then 
        echo "Not empty!" 
        return 0 
    else 
        echo "Empty"
        return 1  
    fi 
}

# =============================================================================
# SSH FUNCTIONS
# =============================================================================

ssh::start_agent(){
    eval "$(ssh-agent)" 
    ssh-add ~/.ssh/id_rsa
}

# =============================================================================
# FILE FUNCTIONS
# =============================================================================

file::fcat(){
    find . -type f -name "${@}" -print0 | xargs -0 -I {} sh -c '
        echo "${@}"
        bat -pP "$@";
    ' _ {}
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

:() {
    [[ ${1:--} != ::* ]] && return 0
    printf '%s\n' "${*}" >&2
}

mpg(){
    man -S 1,8,9 -k . | awk '{print $1}' | fzf | while IFS= read -r line ;do 
        [[ -n "${line}" ]] &&  {
            man -Tpdf "${line}" | zathura - >/dev/null 2>&1 & 
            disown 
        }
    done 
}

sudowrap () {
    # init variables. 
    local c="" t="" parse=""
    local -a opt

    #parse sudo args
    OPTIND=1
    i=0

    while getopts xVhlLvkKsHPSb:p:c:a:u: t; do
        if [ "$t" = x ]; then
            parse=true
        else
            opt[$i]="-$t"
            (( i++ ))
            if [ "$OPTARG" ]; then
                opt[$i]="$OPTARG"
                let i++
            fi
        fi
    done
    shift $(( $OPTIND - 1 ))
    if [ $# -ge 1 ]; then
        c="$1";
        shift;
        case $(type -t "$c") in 
        "")
            echo No such command "$c"
            return 127
            ;;
        alias)
            c="$(type "$c")"
            # Strip "... is aliased to `...'"
            c="${c#*\`}"
            c="${c%\'}"
            ;;
        function)
            c="$(type "$c")"
            # Strip first line
            c="${c#* is a function}"
            c="$c;\"$c\""
            ;;
        *)
            c="\"$c\""
            ;;
        esac
        if [ -n "$parse" ]; then
            # Quote the rest once, so it gets processed by bash.
            # Done this way so variables can get expanded.
            while [ -n "$1" ]; do
                c="$c \"$1\""
                shift
            done
        else
            # Otherwise, quote the arguments. The echo gets an extra
            # space to prevent echo from parsing arguments like -n
            while [ -n "$1" ]; do
                t="${1//\'/\'\\\'\'}"
                c="$c '$t'"
                shift
            done
        fi
        echo sudo "${opt[@]}" -- bash -xvc \""$c"\" >&2
        command sudo "${opt[@]}" bash -xvc "$c"
    else
        echo sudo "${opt[@]}" >&2
        command sudo "${opt[@]}"
    fi
}

# Allow sudowrap to be used in subshells
export -f sudowrap

