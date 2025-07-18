#!/usr/bin/env bash



net::ddos_suspect(){
    netstat -tn 2>/dev/null | awk '{ print $2 }' | grep -e :80 -e :443 | sort | uniq -c | sort -rn | head
}



net::temp_block(){
 for j in $(for i in `netstat -tn 2>/dev/null | grep :80 | awk '{print $5}' | cut -d: -f1 | awk -F"." '{print $1"."$2}' | sort | uniq -c | sort -nr | head | awk '{if ($1 > 2) print $2}'`; do netstat -tn 2>/dev/null | grep :80 | awk '{print $5}' | cut -d: -f1 | grep $i |           uspect"; done
}




net::get_local_ip()
{
    if hash ip; then
        ip -c=always -o -4 a show up | awk -F '[ /]' '/brd/{print $7}';
        return "${?}";
    else
        if hash ifconfig; then
            ifconfig -a | awk -F ':' '/inet addr/{print $2}' | awk '{print $1}' | grep --color=auto -v "127.0.0.1";
            return "${?}";
        fi;
    fi;
    if hash nslookup; then
        if nslookup "$(hostname)" 2>&1 | grep --color=auto -E "Server failed|SERVFAIL|can't find" > /dev/null 2>&1; then
            printf '%s\n' "Could not determine the local IP address";
            return 1;
        else
            nslookup "$(hostname)" | awk -F ':' '/Address:/{gsub(/ /, "", $2); print $2}' | grep --color=auto -v "#";
            return "${?}";
        fi;
    fi;
    return 1
}




