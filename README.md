# mediascript
media21.sh.原创个人自用辣鸡脚本.仅适用于ubuntu x86系统.

一键安装运行nas-tools,jackett,qbittorrent,chinesesubfinder,rclone.配置好nas-tools媒体库等设置.

使用方法：

1.root权限
```
sudo -i
```
2.下载wget
```
apt install wget -y 
```
3.下载21media.sh
```
wget https://raw.githubusercontent.com/ershiyi21/mediascript/main/nastools/21media.sh
```
4.授于执行权限
```
chmod +x 21media.sh
```
5.执行脚本，注意替换""里面内容为自己配置
```
bash 21media.sh "盘符:路径" "emby_url" "emby_api_key"
```

登陆地址：

1.nas-tools:
```
http://ip:3000
```
2.jackett:
```
http://ip:47555
```
3.qbittorrent
```
http://ip:8080
```
4.chinesesubfinder
```
http://ip:19035
```

安装后：

1.复制rclone配置文件到：/home/shh/rclone.conf

2.修改qbittorrent用户名,密码.默认用户名：admin 密码：adminadmin

3.初始化jackeet,复制api_key

4.初始化chinesesubfinder字幕工具，打开实验室功能，生成api_key保存，开启进程守护

5.申请配置tmdb_api

6.配置nas-tools,默认登陆,用户名:admin 密码:password.基础设置,配置移动方式为硬链接或者移动.索引器jackeet,下载器qbittorrent.

