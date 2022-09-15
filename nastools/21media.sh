#!/bin/bash
remote_dir=$1 #rclone远端地址.格式: "盘符:路径"
emby_url=$2 #emby地址,比如,http://1.1.1.1:8896,https://emby.com:8896
api_key=$3 #emby api_key，用于扫库

#系统升级
echo "ubuntu系统升级"
sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get clean
sudo apt-get autoremove

#设置北京时间
sudo apt install ntp -y
sudo apt install ntpdate -y
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate us.pool.ntp.org

#安装docker
echo "安装docker"
wget -qO- get.docker.com | bash

#安装rclone
echo "安装rclone"
curl https://rclone.org/install.sh | bash

#安装rclone挂载fuse
echo "安装fuse"
apt-get install fuse

#创建需要的目录
mkdir -p /home/nastools/config
mkdir -p /home/nastools/media/downloads/电影
mkdir -p /home/nastools/media/downloads/剧集
mkdir -p /home/nastools/media/downloads/动漫
mkdir -p /home/nastools/media/storage/电影/动漫
mkdir -p /home/nastools/media/storage/电影/华语
mkdir -p /home/nastools/media/storage/电影/欧美
mkdir -p /home/nastools/media/storage/电影/日韩
mkdir -p /home/nastools/media/storage/电影/未分类
mkdir -p /home/nastools/media/storage/剧集/国产剧
mkdir -p /home/nastools/media/storage/剧集/日韩剧
mkdir -p /home/nastools/media/storage/剧集/欧美剧
mkdir -p /home/nastools/media/storage/剧集/未分类
mkdir -p /home/nastools/media/storage/剧集/儿童
mkdir -p /home/nastools/media/storage/剧集/纪录片
mkdir -p /home/nastools/media/storage/剧集/综艺
mkdir -p /home/nastools/media/storage/动漫/国内
mkdir -p /home/nastools/media/storage/动漫/国外
mkdir -p /home/nastools/media/storage/其它

mkdir -p /home/jackett1/config
mkdir -p /home/jackett1/downloads

mkdir -p /home/cnsub/config
mkdir -p /home/cnsub/browser

mkdir /home/shh
mkdir /home/log
touch /home/shh/rclone.conf

#安装nas-tools
echo "安装nas-tools"

#下载nas-tools配置文件
wget -P /home/nastools/config https://raw.githubusercontent.com/ershiyi21/mediascript/main/nastools/config.yaml
wget -P /home/nastools/config https://raw.githubusercontent.com/ershiyi21/mediascript/main/nastools/default-category.yaml

#nas-tools运行docker容器
docker run -d  \
    --restart=always \
    --name nas-tools \
    --hostname nas-tools \
    -p 3000:3000   `# 默认的webui控制端口` \
    -v /home/nastools/config:/config  `# 冒号左边请修改为你想在主机上保存配置文件的路径` \
    -v /home/nastools/media:/media    `# 媒体目录，多个目录需要分别映射进来` \
    -e PUID=0     `# 想切换为哪个用户来运行程序，该用户的uid，详见下方说明` \
    -e PGID=0     `# 想切换为哪个用户来运行程序，该用户的gid，详见下方说明` \
    -e UMASK=000  `# 掩码权限，默认000，可以考虑设置为022` \
    -e NASTOOL_AUTO_UPDATE=false `# 如需在启动容器时自动升级程程序请设置为true` \
    jxxghp/nas-tools

#安装字幕下载器chinesesubfinder	
echo "安装chinesesubfinder"
docker run -d \
    --restart=always \
    -v /home/cnsub/config:/config   `# 冒号左边请修改为你想在主机上保存配置、日志等文件的路径` \
    -v /home/nastools/media/storage:/media/storage     `# 请修改为需要下载字幕的媒体目录，冒号右边可以改成你方便记忆的目录，多个媒体目录需要添加多个-v映射` \
    -v /home/cnsub/browser:/root/.cache/rod/browser `# 容器重启后无需再次下载 chrome，除非 go-rod 更新` \
    -e PUID=0 \
    -e PGID=0 \
    -e TZ=Asia/Shanghai `# 时区` \
    -e UMASK=000        `# 权限掩码` \
    -p 19035:19035 `# 从0.20.0版本开始，通过webui来设置` \
    -p 19037:19037 `# webui 的视频列表读取图片用，务必设置不要暴露到外网` \
    --name cnsub \
    --hostname chinesesubfinder \
    --log-driver "json-file" \
    --log-opt "max-size=100m" `# 限制docker控制台日志大小，可自行调整` \
    allanpk716/chinesesubfinder	

#安装种子索引器jackett
echo "安装jackett"
docker run -d \
  --restart=always \
  --name=jackett \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=/Asia/Shanghai \
  -e AUTO_UPDATE=true `#optional` \
  -p 47555:9117 \
  -v /home/jackett1/config:/config \
  -v /home/jackett1/downloads:/downloads \
  --restart unless-stopped \
  ghcr.io/linuxserver/jackett
 
#安装inotifywait
apt install inotify-tools -y

#生成rclone自动上传脚本nasup.sh
echo "生成脚本nasup.sh"
echo "#!/bin/bash
local_dir=/home/nastools/media/storage/
remote_dir=$1" > /home/shh/nasup.sh

echo 'log_dir=/home/log/nasup.log
rclone_config_dir=/home/shh/rclone.conf
rclone_log_dir=/home/log/rclone.log
libraryrefresh_dir=/home/shh/libraryrefresh.py

echo "[$(date "+%Y-%m-%d %H:%M:%S")] 开始运行脚本" >> ${log_dir}

while
inotifywait -r $local_dir -e modify,delete,create,attrib,move;
do  
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 检测到文件异动,休眠3分钟，nfo识别字幕下载" \
    >> ${log_dir}
    sleep 3m					 	
    count=`ps -ef |grep nasup.sh |grep -v "grep" |wc -l`
    if [ $count -le 2 ];then     #crontab开机自启动,会有2行;如自己运行则1行
       echo "[$(date "+%Y-%m-%d %H:%M:%S")] rclone上传开始" \
       >> ${log_dir}
       /usr/bin/rclone move -v ${local_dir} ${remote_dir} \
       --transfers 10 --config ${rclone_config_dir} \
       >> ${rclone_log_dir} 2>&1 &&
       echo "[$(date "+%Y-%m-%d %H:%M:%S")] rclone上传完成" \
       >> ${log_dir}
       while 
       [ ! `/usr/bin/rclone ls ${local_dir} | wc -l` -eq 0 ]
       do
	 echo "[$(date "+%Y-%m-%d %H:%M:%S")] 仍有文件存在，再次上传" \
	 >> ${log_dir}
	 /usr/bin/rclone move -v ${local_dir} ${remote_dir} \
	 --transfers 10 --config ${rclone_config_dir} \
	 >> ${rclone_log_dir} 2>&1 &&
         echo "[$(date "+%Y-%m-%d %H:%M:%S")] rclone再次上传完成" \
	 >> ${log_dir}   
       done
	 echo "[$(date "+%Y-%m-%d %H:%M:%S")] 文件夹已无文件存在" \
	 >> ${log_dir}  
    else
	 echo "[$(date "+%Y-%m-%d %H:%M:%S")] 脚本已在运行，即将退出" \
	 >> ${log_dir}
	 exit
    fi
    echo "[$(date "+%Y-%m-%d %H:%M:%S")]执行扫库命令" >> ${log_dir}
    if /usr/bin/python3 ${libraryrefresh_dir};then
       echo "[$(date "+%Y-%m-%d %H:%M:%S")]自动扫库正常" >> ${log_dir}
    else 
       echo "[$(date "+% Y-%m-%d %H:%M:%S")]自动扫库失败" >> ${log_dir}
    fi	
       echo "[$(date "+%Y-%m-%d %H:%M:%S")] 再次监控文件夹变化" >> ${log_dir}
done' >> /home/shh/nasup.sh

#设置nas.sh脚本开机启动
echo "设置nas.sh脚本开机启动"
crontab -l > crontab_test
echo "@reboot bash /home/shh/nasup.sh" >> crontab_test
crontab crontab_test

#生成emby自动扫库脚本
echo "生成emby自动扫库脚本"

echo "import requests

headers = {
    'accept': '*/*',
    'content-type': 'application/x-www-form-urlencoded',
}

params = {
    'api_key': '${api_key}',
}

response = requests.post('${emby_url}/emby/Library/Refresh', params=params, headers=headers)
" > /home/shh/libraryrefresh.py

#安装qbittorrent
 echo "安装qbittorrent"
 rm -rf "/usr/local/bin/x86_64-qbittorrent-nox"
 wget -qO "/usr/local/bin/x86_64-qbittorrent-nox" https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-4.4.5_v2.0.7/x86_64-qbittorrent-nox &&
 chmod 700 "/usr/local/bin/x86_64-qbittorrent-nox" &&
 echo "[Unit]" > /etc/systemd/system/qbt.service &&
 echo "Description=qBittorrent Service" >> /etc/systemd/system/qbt.service &&
 echo "After=network.target nss-lookup.target" >> /etc/systemd/system/qbt.service &&

 echo "[Service]" >> /etc/systemd/system/qbt.service &&
 echo "UMask=000" >> /etc/systemd/system/qbt.service &&
 echo "ExecStart=/usr/local/bin/x86_64-qbittorrent-nox --profile=/usr/local/etc" >> /etc/systemd/system/qbt.service &&

 echo "[Install]" >> /etc/systemd/system/qbt.service &&

 echo "WantedBy=multi-user.target" >> /etc/systemd/system/qbt.service &&
 systemctl enable qbt &&
 systemctl start qbt
 systemctl status qbt 
 echo "qbit脚本安装完毕"
 
#开启bbr
 echo "开启原版bbr"
 echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
 echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
 sysctl -p
 lsmod | grep bbr 
 echo "若输出【tcp_bbr 20480  1】即表示成功开启bbr"
 echo "qbittorrent默认.用户名：admin 密码：adminadmin"

#赋予脚本执行权限
chmod +x /home/shh/nasup.sh
chmod +x /home/shh/libraryrefresh.py

#重启
echo "安装完成，即将重启"
reboot
 
#https://github.com/ershiyi21/media21.原创个人自用辣鸡脚本.仅适用于ubuntu x86系统.
#一键安装运行nas-tools,jackett,qbittorrent,chinesesubfinder,rclone.配置好nas-tools媒体库等设置.
#复制rclone配置文件到：/home/shh/rclone.conf
#修改qbittorrent用户名,密码.默认用户名：admin 密码：adminadmin
#初始化jackeet,复制api_key
#初始化cnsub字幕工具，打开实验室功能，生成api_key保存，开启进程守护
#申请配置tmdb_api
#运行emby自动扫库命令需要python环境
#配置nas-tools,默认登陆,用户名:admin 密码:password.基础设置,配置移动方式为硬链接或者移动.索引器jackeet,下载器qbittorrent.
