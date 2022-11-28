#!/bin/sh

##环境检测
[[ $EUID -ne 0 ]] && echo -e "必须使用root用户运行此脚本！\n" && exit 2
touch /etc/resolv.conf.test && chattr +i /etc/resolv.conf.test >/dev/null 2>&1
[[ $? != 0 ]] && echo -e "缺少chattr，该脚本修改DNS方法 不适合本系统！\n" && \
chattr -i /etc/resolv.conf.test >/dev/null 2>&1 && rm /etc/resolv.conf.test && exit 3
chattr -i /etc/resolv.conf.test >/dev/null 2>&1 && rm /etc/resolv.conf.test

##DNS设置
function dnsset() {
    [[ -n "$1" ]] && dns1=$1 || read -r -p "请输入DNS IP: " dns1
    
    chattr -i /etc/resolv.conf >/dev/null 2>&1
    [[ ! -f /etc/resolv.conf.dnsback ]] && mv /etc/resolv.conf /etc/resolv.conf.dnsback
    rm -f /etc/resolv.conf >/dev/null 2>&1
    domain=`cat /etc/resolv.conf.dnsback | grep domain`
    search=`cat /etc/resolv.conf.dnsback | grep search`
    options=`cat /etc/resolv.conf.dnsback | grep options`
    sortlist=`cat /etc/resolv.conf.dnsback | grep sortlist`
    
    echo "${domain}" > /etc/resolv.conf
    echo "${search}" >> /etc/resolv.conf
    echo "${options}" >> /etc/resolv.conf
    echo "${sortlist}" >> /etc/resolv.conf   
    echo "nameserver ${dns1}" >> /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
    echo "nameserver 2606:4700:4700::1111" >> /etc/resolv.conf
  
    chattr +i /etc/resolv.conf
    echo -e "系统DNS已设置为 ${dns1} ,即将检测是否设置成功...\n"
}

##DNS获取,优先输出联网检测结果
function dnsget() {
    local_dns=`cat /etc/resolv.conf | grep nameserver | head -n 1 | awk '{print $2}'`
    dnsget=${local_dns}
    dnstype="本地"
    
    nslookup bing.com >/dev/null 2>&1
    if [[ $? != 0 ]] ;then
        sudo apt-get update || sudo yum update
        sudo apt-get install dnsutils -y || sudo yum install bind-utils -y
        nslookup bing.com >/dev/null 2>&1
        [[ $? != 0 ]] && return 1
    fi
    
    online_dns=`nslookup bing.com | grep Server | awk '{print $2}'`
    dnsget=${online_dns}
    dnstype="联网"
    return 0
}

##DNS是否设置成功检测
function dnscheck() {
    dns1=$1
    dnsget
    dns2=${dnsget}
    
    dns3=`ip_type ${dns1}`
    dns4=`ip_type ${dns2}`
    
    if [[ ${dns3} == "${dns4}" ]] ;then
	echo -e "${dnstype}检测显示，系统DNS已永久锁定为 ${dns1} \n"
	return 0
    else
	chattr -i /etc/resolv.conf
        mv -f /etc/resolv.conf.dnsback /etc/resolv.conf 
	echo -e "${dnstype}检测显示，DNS设置失败；DNS设置已自动恢复为原来系统的DNS设置\n"
	return 1
    fi
}

##DNS恢复系统设置
function dnsback() {
    [[ ! -f /etc/resolv.conf.dnsback ]] && echo -e "无系统dns备份,退出脚本...\n" 
    [[ ! -f /etc/resolv.conf.dnsback ]] && return 2
    chattr -i /etc/resolv.conf && \
    mv -f /etc/resolv.conf.dnsback /etc/resolv.conf && \
    echo -e "DNS设置已恢复为原来系统的DNS设置\n" && \
    return 0 || return 1
}

##IPV6地址格式转换
function ip_type() {
    if [[ -n `echo $1 | grep ":"` ]] ;then
        ipv6calc -v >/dev/null 2>&1
        if [[ $? != 0 ]] ;then
            sudo apt-get update || sudo yum update
            sudo apt-get install ipv6calc -y || sudo yum install ipv6calc -y
            ipv6calc -v >/dev/null 2>&1
            [[ $? != 0 ]] && "ipv6calc安装失败!退出DNS设置检测" && exit 4
        fi
	
	iprt=`ipv6calc --addr2compaddr -q $1`
        [[ $? != 0 ]] && echo "ipv6输入有误，请检查！退出DNS设置检测" && exit 5
        echo ${iprt}
    else
        echo $1
    fi
}

##可视化Shell界面
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
          dnsget
	  echo -e "${dnstype}检测显示，系统当前首选DNS服务器为： ${dnsget}\n"
	  ;;
        *)
          echo -e "\n输入错误，请重新输入！\n"
          menu
          ;;
    esac
}

##带参一键运行
case $1 in
    [1sS])
          echo
	  dnsset $2
	  dnscheck ${dns1}
	  exit $?
	  ;;
    [2bB])
	  echo
	  dnsback
	  exit $?
	  ;;
    [3gG])
          echo
	  dnsget
	  echo -e "${dnstype}检测显示，系统当前首选DNS服务器为： ${dnsget}\n"
	  ;;
	 *)
	  menu
	  ;;
esac

##time：2022/11/12
##github：ershiyi21
