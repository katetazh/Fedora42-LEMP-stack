#!/usr/bin/env bash


net::conns () {
    local flags="$(@)"
    misc::noerr netstat -tn
}

net::web_conns(){
        netstat -tn 2>/dev/null | grep -e :80 -e :443 | awk '{print $5 }' | sort | uniq -c | sort -rn | head
}
