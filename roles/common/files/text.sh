#!/usr/bin/env bash 

## get field 
text::field(){
    awk -F "${2:- }" '{ print $'"${1:-1}"'}'
}

# head remade in bash ( never intended to work with big files )

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


## Tail remade in bash ( never intended to work with big files )
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
	input="${2:-$(cat -)}" ## this won't work since it wont' take input from a file. Instead you can specify to use `cat - ` if not able else. 
	pattern="${1:-}"  
	echo -e "${input/$pattern/}" ##here the input doesn't need to be a var since you're expanding it first
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

