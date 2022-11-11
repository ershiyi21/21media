#!/bin/sh

[[ $EUID -ne 0 ]] && echo -e "必须使用root用户运行此脚本！\n" && exit 1
[[ ! -f /etc/resolv.conf ]] && echo -e "该脚本修改DNS方法 不适合本系统！\n"
[[ ! -f /etc/resolv.conf ]] && exit 1

nslookup bing.com >/dev/null 2>&1
if [[ $? != 0 ]] ;then
    sudo apt update || sudo yum update
    sudo apt install dnsutils -y || sudo yum install bind-utils -y
fi

ipv6calc -v >/dev/null 2>&1
if [[ $? != 0 ]] ;then
    sudo apt update || sudo yum update
    sudo apt install ipv6calc -y || sudo yum install ipv6calc -y
fi

function dnsset() {
    [[ -n "$1" ]] && dns1=$1 || read -r -p "请输入DNS IP: " dns1
    sudo chattr -i /etc/resolv.conf
    [[ ! -f /etc/resolv.conf.dnsback ]] && cp -f /etc/resolv.conf /etc/resolv.conf.dnsback
    echo "nameserver ${dns1}" > /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
    sudo chattr +i /etc/resolv.conf
    dns2=`nslookup bing.com | grep Server | awk '{print $2}'`
    
    dns1=`ip_type ${dns1}`
    dns2=`ip_type ${dns2}`
    
    if [[ ${dns1} == "${dns2}" ]] ;then
        echo -e "系统DNS已永久设置为 ${dns1} \n"
    
    else
    echo -e "DNS设置失败，恢复原来系统设置\n"
    sudo chattr -i /etc/resolv.conf
    rm /etc/resolv.conf
    mv -f /etc/resolv.conf.dnsback /etc/resolv.conf 
    
    fi
}

function dnsback() {
    [[ ! -f /etc/resolv.conf.dnsback ]] && echo -e "无系统dns备份,退出脚本...\n" 
    [[ ! -f /etc/resolv.conf.dnsback ]] && exit 1
    sudo chattr -i /etc/resolv.conf
    mv -f /etc/resolv.conf.dnsback /etc/resolv.conf
    echo -e "系统dns已恢复,如还未恢复，请手动重启恢复：reboot\n"
}

function ip_type() {
if [[ -n `echo $1 | grep ":"` ]] ;then
    echo `ipv6calc --addr2compaddr -q $1`
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
    ;;
    2)
    dnsback
    ;;
    3)
    echo
    exit 1
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
