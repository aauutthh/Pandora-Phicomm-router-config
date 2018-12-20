#!/bin/sh

__CMDBASE="/usr/bin/wget-ssl -v -t 1 --no-check-certificate "
__CMDBASE="${__CMDBASE}  --referer 'https://www.west.cn/manager/domain/rsall.asp?domainid=111'" 
__CMDBASE="${__CMDBASE}  --post-data='act=rsalldomod&did=111&cid=222&val=${__IP}&ttl=900&lng='"
__CMDBASE="${__CMDBASE}  --header 'Cookie: LoginInfo=5g; ASPSESSIONIDQARCTBAD=OJOGBHG; ASPSESSIONIDSQRRTBAT=JC; ASPSESSIONIDCSBBSQQA=KAO;'"
__CMDBASE="${__CMDBASE}  --header 'X-Requested-With: XMLHttpRequest'" 
__CMDBASE="${__CMDBASE}  --header 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.108 Safari/537.36'"
__CMDBASE="${__CMDBASE}  --header 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8'"
__CMDBASE="${__CMDBASE}  -O $DATFILE -o $ERRFILE"

__URLBASE="https://www.west.cn/Manager/domain/load.asp" \

    __RUNPROG="${__CMDBASE} ${__URLBASE}"

write_log 6 "#> $__RUNPROG"
eval $__RUNPROG
__ERR=$?
[ $__ERR -eq 0 ] && return 0

write_log 3 "wget 错误代码: '$__ERR'"
write_log 7 "$(cat $ERRFILE)"

if [ $VERBOSE -gt 1 ]; then
    write_log 4 "传输失败 - 详细模式: $VERBOSE - 出错后不再重试"
    return 1
fi

