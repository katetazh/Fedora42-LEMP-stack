#!/usr/bin/env bash


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
