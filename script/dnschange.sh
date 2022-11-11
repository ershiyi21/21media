#!/bin/sh

[[ $EUID -ne 0 ]] && echo -e "必须使用root用户运行此脚本！\n" && exit 1
[[ ! -f /etc/resolv.conf ]] && echo -e "该脚本修改DNS方法 不适合本系统！\n"
[[ ! -f /etc/resolv.conf ]] && exit 2

nslookup bing.com >/dev/null 2>&1
if [[ $? != 0 ]] ;then
    sudo apt update || sudo yum update
    sudo apt install dnsutils -y || sudo yum install bind-utils -y
    nslookup bing.com >/dev/null 2>&1
    [[ $? != 0 ]] && exit 3
fi

ipv6calc -v >/dev/null 2>&1
if [[ $? != 0 ]] ;then
    sudo apt update || sudo yum update
    sudo apt install ipv6calc -y || sudo yum install ipv6calc -y
    ipv6calc -v >/dev/null 2>&1
    [[ $? != 0 ]] && exit 4
fi

function dnsset() {
    [[ -n "$1" ]] && dns1=$1 || read -r -p "请输入DNS IP: " dns1
    sudo chattr -i /etc/resolv.conf
    
    domain=`echo /etc/resolv.conf | grep domain`
    search=`echo /etc/resolv.conf | grep search`
    sortlist=`echo /etc/resolv.conf | grep sortlist`
    
    [[ ! -f /etc/resolv.conf.dnsback ]] && cp -f /etc/resolv.conf /etc/resolv.conf.dnsback
    
    echo "${domain}" > /etc/resolv.conf
    echo "${search}" >> /etc/resolv.conf
    echo "${sortlist}" >> /etc/resolv.conf   
    echo "nameserver ${dns1}" >> /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
  
    sudo chattr +i /etc/resolv.conf
    dns2=`nslookup bing.com | grep Server | awk '{print $2}'`
    
    dns1=`ip_type ${dns1}`
    dns2=`ip_type ${dns2}`
    
    if [[ ${dns1} == "${dns2}" ]] ;then
        echo -e "系统DNS已永久锁定为 ${dns1} \n"
        return 0
    else        
        sudo chattr -i /etc/resolv.conf
        rm /etc/resolv.conf
        mv -f /etc/resolv.conf.dnsback /etc/resolv.conf 
	echo -e "DNS设置失败，已恢复原来系统设置\n"
        return 5
    fi
}

function dnsback() {
    [[ ! -f /etc/resolv.conf.dnsback ]] && echo -e "无系统dns备份,退出脚本...\n" 
    [[ ! -f /etc/resolv.conf.dnsback ]] && return 2
    sudo chattr -i /etc/resolv.conf && \
    mv -f /etc/resolv.conf.dnsback /etc/resolv.conf && \
    echo -e "系统dns已恢复,如还未恢复，请手动重启恢复：reboot\n" && \
    return 0 || return 6
}

function ip_type() {
if [[ -n `echo $1 | grep ":"` ]] ;then
    iprt=`ipv6calc --addr2compaddr -q $1`
    [[ $? != 0 ]] && echo "ipv6输入有误，请检查！" && exit 7
    echo ${iprt}
else
    echo $1
fi
}

function menu() {
echo
echo "1.设置DNS"
echo "2.恢复DNS"
echo "3.退出脚本"
echo

read -r -p "请输入数字：" selectnum 
case $selectnum in
    1)
    dnsset
    exit $?
    ;;
    2)
    dnsback
    exit $?
    ;;
    3)
    echo
    exit
    ;;
    *)
    echo -e "\n输入错误，请重新输入！\n"
    menu
    ;;
esac
}

case $1 in
    [1sS])
	  dnsset $2
	  ;;
    [2bB])
	  dnsback
	  ;;
        *)
	  menu
	  ;;
esac

<<COMMENT

!=中!要放在前面,表示否定

变量赋值时,要保留格式,加双引号，如 a=`cat xxx|grep xxx` ;echo "$a"可保留行，echo $a不保留行

>/dev/null 2>&1 日志重定向、丢弃

exit表示系统层面的进程退出,ps -ef可查看,后可跟数字&变量,表示某个系统进程退出时返回值;
return表示某个函数、模块的退出,后跟数字表示函数返回值,某个函数的结束不代表该系统程序的结束,
其返回值仅仅代表函数模块的执行情况,如需要返回值传递到系统之外,可在函数模块调用后,利用 exit $? 退出系统主进程.

一个脚本中执行另外一个脚本,另外一个脚本是系统层面再起一个程序运行的,ps -ef可查看,如前者有调用后者的函数模块,
return仅仅代表后者的某个函数模块结束运行,但后者的剩下的命令仍会继续执行.
但如果函数中含有exit,那么代表后者直接全部over了,但也仅仅代表后者结束,前者依然会继续运行.

简而言之,exit可处于任意位置(非函数模块内、函数内),只要调用,包含该函数的主程序就结束运行.
return只能用于函数模块内,只能作为某个系统进程的一部分,return仅仅代表该部分的结束，该部分余下的命令不再运行,但函数外的命令仍旧运行.

COMMENT
