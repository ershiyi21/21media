
## dns修改
```
bash <(curl -L -s https://raw.githubusercontent.com/ershiyi21/21media/main/script/dnschange.sh)
```
待优化：1.输入ip格式准确性判断;2.ipv6使用shell正则,无需借助ipv6calc,实现ipv6本地双向格式转换;3.e2fsprogs包的安装[chattr]

## nas-tool套件安装
```
cd /root && apt install wget -y && wget https://raw.githubusercontent.com/ershiyi21/21media/main/nastools/21media.sh && chmod +x 21media.sh && bash 21media.sh
```

 注：tmdb_api申请地址：https://www.themoviedb.org/settings/api

- 一键安装运行nas-tools,jackett,qbittorrent,chinesesubfinder,rclone.
- 配置好nas-tools媒体库等设置.
- 仅适用于debian&ubuntu系统.
- nas-tools硬链接文件到其它目录，rclone实时借助api上传云端，做种&上传两不误
- rclone上传线程可控，同时运行进程数数唯一，不会出现单文件多传或rclone重复运行导致服务器过载死机


### 安装后打开脚本
```
21media
```
### 安装后指南：
1、删除文件/home/shh/rclone.conf，复制rclone配置文件到目录/home/shh/下,并且重启服务器.若未进行该操作，则不会进行进行rclone上传.

2、修改qbittorrent用户名,密码
默认用户名：admin 默认密码：adminadmin 登录地址：
```
http://ip:8080
```
3、初始化jackeet,复制api_key[未安装则跳过] 登录地址：
```
http://ip:47555
```
4、配置nas-tools,默认登陆,用户名: admin 密码: password .基础设置,配置移动方式为硬链接或者移动.索引器为内置或者jackeet,下载器qbittorrent.登录地址：
```
http://ip:3000
```
5、初始化字幕chinesesubfinder下载工具，打开实验室功能，生成api_key保存，开启进程守护" 登录地址：
```
http://ip:19035
```
### 脚本运行逻辑
 - nas-tools借助qbittorrent下载种子
 - nas-tools识别、重命名、移动（硬链接）下载文件
 - nas-tools通知chinesesubfinder字幕下载
 - nasup.sh监控文件夹文件变化，如有文件则开始rclone上传，直到文件夹为空
 - nasup.sh通知emby进行扫库，继续监控文件夹
 
   注：emby入库tg通知需要自己配置，项目地址 https://github.com/bjoerns1983/Emby.Plugin.TelegramNotification

### 媒体分类
- 电影：动漫、华语、欧美、日韩、未分类
- 剧集：国产剧、日韩剧、欧美剧、儿童、纪录片、综艺、未分类
- 动漫：国内、国外 【动漫剧集单独分类】
- 其它： 
