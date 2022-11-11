#!/bin/sh

[[ $EUID -ne 0 ]] && echo -e "必须使用root用户运行此脚本！\n" && exit 1
touch /etc/resolv.conf.test && chattr +i /etc/resolv.conf.test >/dev/null 2>&1
[[ $? != 0 ]] && echo -e "缺少chattr，该脚本修改DNS方法 不适合本系统！\n" && exit 2
chattr -i /etc/resolv.conf.test >/dev/null 2>&1 && rm /etc/resolv.conf.test

function dnsset() {
    [[ -n "$1" ]] && dns1=$1 || read -r -p "请输入DNS IP: " dns1
    
    chattr -i /etc/resolv.conf >/dev/null 2>&1
    [[ ! -f /etc/resolv.conf.dnsback ]] && mv /etc/resolv.conf /etc/resolv.conf.dnsback
    rm -f /etc/resolv.conf >/dev/null 2>&1
    domain=`cat /etc/resolv.conf.dnsback | grep domain`
    search=`cat /etc/resolv.conf.dnsback | grep search`
    sortlist=`cat /etc/resolv.conf.dnsback | grep sortlist`
    
    echo "${domain}" > /etc/resolv.conf
    echo "${search}" >> /etc/resolv.conf
    echo "${sortlist}" >> /etc/resolv.conf   
    echo "nameserver ${dns1}" >> /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
  
    chattr +i /etc/resolv.conf
    echo -e "系统DNS已设置为 ${dns1} ,即将联网检测是否设置成功...\n"
}

function dnscheck() {
    
    dns1=$1
    dnsquery
    dns2=${dns}
    
    dns3=`ip_type ${dns1}`
    dns4=`ip_type ${dns2}`
    
    if [[ ${dns3} == "${dns4}" ]] ;then
        echo -e "脚本检测确认，系统DNS已永久锁定为 ${dns1} \n"
        return 0
    else        
        chattr -i /etc/resolv.conf
        mv -f /etc/resolv.conf.dnsback /etc/resolv.conf 
	echo -e "脚本检测确定，DNS设置失败，DNS设置已自动恢复为原来系统的DNS设置\n"
        return 4
    fi
}

function dnsback() {
    [[ ! -f /etc/resolv.conf.dnsback ]] && echo -e "无系统dns备份,退出脚本...\n" 
    [[ ! -f /etc/resolv.conf.dnsback ]] && return 2
    chattr -i /etc/resolv.conf && \
    mv -f /etc/resolv.conf.dnsback /etc/resolv.conf && \
    echo -e "DNS设置已恢复为原来系统的DNS设置\n" && \
    return 0 || return 5
}

function dnsquery() {
    nslookup bing.com >/dev/null 2>&1
    if [[ $? != 0 ]] ;then
        sudo apt update || sudo yum update
        sudo apt install dnsutils -y || sudo yum install bind-utils -y
        nslookup bing.com >/dev/null 2>&1
        [[ $? != 0 ]] && echo "nslookup相关包安装失败！退出DNS设置检测" && exit 3
    fi
    
    dns=`nslookup bing.com | grep Server | awk '{print $2}'`
}

function ip_type() {
    if [[ -n `echo $1 | grep ":"` ]] ;then
        ipv6calc -v >/dev/null 2>&1
        if [[ $? != 0 ]] ;then
            sudo apt update || sudo yum update
            sudo apt install ipv6calc -y || sudo yum install ipv6calc -y
            ipv6calc -v >/dev/null 2>&1
            [[ $? != 0 ]] && "ipv6calc安装失败!退出DNS设置检测" && exit 6
        fi
	
	iprt=`ipv6calc --addr2compaddr -q $1`
        [[ $? != 0 ]] && echo "ipv6输入有误，请检查！退出DNS设置检测" && exit 7
        echo ${iprt}
    else
        echo $1
    fi
}

function menu() {
    echo
    echo "0.退出脚本"
    echo "1.设置DNS"
    echo "2.恢复DNS"
    echo "3.系统DNS服务器查询"
    echo 

    read -r -p "请输入数字：" selectnum 
    
    case $selectnum in
        0)
	  echo -e "退出脚本...\n"
          exit
          ;;
	1)
          dnsset
	  dnscheck ${dns1}
          exit $?
          ;;
        2)
          dnsback
          exit $?
          ;;
	3)
          dnsquery
	  echo -e "系统现在使用的首选DNS服务器为：${dns}\n"
	  ;;
        *)
          echo -e "\n输入错误，请重新输入！\n"
          menu
          ;;
    esac
}

case $1 in
    [1sS])
          echo
	  dnsset $2
	  dnscheck ${dns1}
	  ;;
    [2bB])
	  echo
	  dnsback
	  ;;
    [3qQ])
          echo
	  dnsquery
	  echo -e "系统现在使用的首选DNS服务器为：${dns}\n"
	  ;;
	 *)
	  menu
	  ;;
esac
