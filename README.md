# 在线媒体下载&管理一键安装脚本
- 一键安装运行nas-tools,jackett,qbittorrent,chinesesubfinder,rclone.
- 配置好nas-tools媒体库等设置.
- 仅适用于debian&ubuntu x86系统.

## 一键安装脚本：

```
cd /root && apt install wget -y && wget https://raw.githubusercontent.com/ershiyi21/media21/main/nastools/21media.sh && chmod +x 21media.sh && bash 21media.sh
```
## 安装后打开脚本启动界面
```
bash /root/21media.sh
```
## 后续操作：

1、复制rclone配置文件到目录下：/home/shh/

2、修改qbittorrent用户名,密码
默认用户名：admin 默认密码：adminadmin 登录地址：
```
http://ip:8080
```
3、初始化jackeet,复制api_key[未安装则跳过] 登录地址：
```
http://ip:47555
```
4、注册tmdb账号，申请tmdb_apikey，并且在nas-tools中完成配置
```
https://www.themoviedb.org/settings/api
```
5、配置nas-tools,默认登陆,用户名: admin 密码: password .基础设置,配置移动方式为硬链接或者移动.索引器为内置或者jackeet,下载器qbittorrent.登录地址：
```
http://ip:3000
```
6、初始化字幕chinesesubfinder下载工具，打开实验室功能，生成api_key保存，开启进程守护" 登录地址：
```
http://ip:19035
```
