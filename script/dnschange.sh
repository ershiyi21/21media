#!/bin/sh

[[ $EUID -ne 0 ]] && echo -e "必须使用root用户运行此脚本！" && exit 1
[[ ! -f /etc/resolv.conf ]] && echo "该脚本修改DNS方法 不适合本系统！"
[[ ! -f /etc/resolv.conf ]] && exit 1

nslookup bing.com >/dev/null
if [[ $? != 0 ]] ;then
    sudo apt update || sudo yum update
    sudo apt install dnsutils -y || sudo yum install bind-utils -y
fi

function dnsset() {
    [[ -n "$1" ]] && dns1=$1 || read -r -p "请输入DNS IP: " dns1
    sudo chattr -i /etc/resolv.conf
    cp -f /etc/resolv.conf /etc/resolv.conf.dnsback
    echo "nameserver ${dns1}" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    sudo chattr +i /etc/resolv.conf
    dns2=`nslookup bing.com | grep Server | awk '{print $2}'`

    if [[ ${dns1} == "${dns2}" ]] ;then
        echo "系统DNS已永久设置为 ${dns1} "
    
    else
    echo "DNS设置失败，恢复原来系统设置"
    sudo rm /etc/resolv.conf
    sudo mv -f /etc/resolv.conf.dnsback /etc/resolv.conf 
    
    fi
}

function dnsback() {
    [[ ! -f /etc/resolv.conf.dnsback ]] && echo "无系统dns备份,退出脚本..." 
    [[ ! -f /etc/resolv.conf.dnsback ]] && exit 1
    sudo chattr -i /etc/resolv.conf
    sudo mv -f /etc/resolv.conf.dnsback /etc/resolv.conf
    echo "系统dns已恢复,如还未恢复，请手动重启：reboot"
}


function menu() {
echo "1.设置DNS"
echo "2.恢复系原来DNS"
echo "3.退出脚本"

read -r -p "请输入数字：" selectnum 
case $selectnum in
    1)
    dnsset
    ;;
    2)
    dnsback
    ;;
    3)
    exit 1
    ;;
    *)
    echo "输入错误"
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
