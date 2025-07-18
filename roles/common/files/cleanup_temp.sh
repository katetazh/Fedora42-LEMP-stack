#!/usr/bin/env bash




# // Catch arguments.
ARGA=("${@}")
readonly ARGA


# // Setting up global variables.-
TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")
readonly TIMESTAMP


# // Initialize array to contain list of suspicious files.
FILE_LIST=()
SUID_LIST=()
SUS_FILES=()
TMP_CLEAN=


# // Logging functions.
log::err() {
  echo -e "[$TIMESTAMP] ${*}" >&2
}

log::info() {
  echo -e "[$TIMESTAMP] ${*}" >&1
}


draw_progress_bar() {
  local green blue cyan nc progress total_width bar_length
  green='\033[0;32m'
  nc='\033[0m'
  progress=$1
  let bar_length=$(($total_width - 10))*$progress/100
  printf "\r${green}["
  printf "%0.s=" $(seq 1 $bar_length)
  printf "%0.s " $(seq 1 $(($total_width - $bar_length - 10)))
  printf "] %3d%%${nc}" $progress
}


show_help() {
  cat <<EOF
    Usage: ${PWD##*/} - [hc] --cleanup

        -h|--help  Show this message.
        --cleanup  Cleanup old and suspicious files from /tmp.
EOF
}


_get_files() {


  log::info "[INFO] Finding files..."
  for i in {1..100}; do
    draw_progress_bar "${i}"
    sleep 0.01
  done


  while IFS= read -d '' -r key; do
    log::info "[INFO] Adding ${key} to FILE_LIST.."
    FILE_LIST+=("${key}")
  done < <(find /tmp -type f -mtime +14 -print0 2>/dev/null)


  while IFS= read -d '' -r key; do
    log::warning "[WARNING] SUID file found ${key}"
    SUID_LIST+=("${key}")
  done < <(find /tmp -type f -perm 4000 -print0 2>/dev/null)


  while IFS= read -d '' -r key; do
    log "[WARNING] Suspicious file found!"
    SUS_FILES+=("${key}")
  done < <(find /tmp -type p -a -type l -print0 2>/dev/null)
  (($? > 0)) && {
    return 1
  } || {
    return 0
  }


}


# // Function that parses arguments.
argparse() {
  if ((${#ARGA[@]} > 0)); then
    for arg in "${ARGA[@]}"; do
      case "${arg}" in
      -h | --help | -\? | \?)
        show_help
        exit 1
        ;;
      --cleanup | -c)
        TMP_CLEAN=1
        shift #
        ;;
      *)
        show_help
        exit 1
        ;;
      esac
    done
  else
    show_help
    exit 1
  fi
}










if (( EUID != 0 )); then
  exit 1
fi


if { set -C; : 2>/dev/null >/tmp/cleanup3301; }; then  
         trap "rm -f /tmp/cleanup3301" EXIT
else  
    echo "Lock file exists… exiting"  
    exit  
fi


argparse "${ARGA[@]}"


exec 3>&1 4>&2


exec 1> >(tee -a >(gzip >>/dev/shm/_tmp_clean_stdout.log)) 2> >(tee -a >(gzip >> /dev/shm/_tmp_clean_stderr.log))


main() {

[[ -n "${TMP_CLEAN}" ]] && {
  _get_files
  ((${#SUID_LIST} > 0)) && {
    printf '%s\n' "${SUID_LIST[@]}" | while IFS= read -r file; do
      log::info "[INFO] Deleting ${file}"
      rm -f "${file}" || log::err "[Warning] Failed to delete ${file}"
    done
  }

  ((${#FILE_LIST} > 0)) && {
    printf '%s\n' "${FILE_LIST[@]}" | while IFS= read -r file; do
      log::info "[INFO] Deleting ${file}"
      rm -f "${file}" || log::err "[Warning] Failed to delete ${file}"
    done
  }


  ((${#SUS_FILES} > 0)) && {
    printf '%s\n' "${SUS_FILES[@]}" | while IFS= read -r file; do
      log::info "[INFO] Deleting ${file}"
      rm -f "${file}" || log::err "[Warning] Failed to delete ${file}"
    done
  }
}


}

main
