#!/usr/bin/env bash


# // Get line count.
str::lines(){
  mapfile -tn 0 lines < "${1:-/dev/stdin}"
  echo -e "${#lines[@]}\n"
}

# // remove $1 from $2
str::trun(){
  printf '%s\n' "${2//${1:-}}"
}


# // Reverse the case for a string of chars.
str::rev_case(){
  input="${1:-$(cat -)}"
  echo -e "${input~~}\n"
}

###
# // Remove from $2 $1
###

# str::lstrip "hello world" hello
# output: `world`

str::lstrip() {
    printf '%s\n' "${1##$2}"
}

###
# // Remove $2 from $1 on the right.
str::rstrip() {
    printf '%s\n' "${1%%$2}"
}


## regex
str::regex() {
    [[ $1 =~ $2 ]] && {
    echo -e "${BASH_REMATCH[1]}\n"
  }
}


str::tolower() {
  local input="${1:-$(</dev/stdin)}"
  echo "${input,,}"
}




text::toupper(){
  local input="${1:-$(</dev/stdin)}"
  echo -e "${input^^}\n"
}



