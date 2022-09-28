#!/bin/bash
echo "作者:ershiyi21"
echo "Github:https://github.com/ershiyi21/media21"
echo "描述:在线媒体下载&管理一键安装脚本"
echo "==============脚本管理================"
echo "1.安装"
echo "2.卸载脚本"
echo "3.nasup脚本运行日志"
echo "4.rclone上传日志"
echo "====================================="
read -r -p "请选择:" selectnum

case $selectnum in
1) 
  21install
  ;;
2) 
  21uninstall
  ;;
3)
  21nasuplog
  ;;
4)
  21rclonelog
  ;;
esac

21install() {
#系统升级
echo "ubuntu系统升级"
sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get clean
sudo apt-get autoremove

#设置北京时区
sudo apt install ntp -y
sudo apt install ntpdate -y
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate us.pool.ntp.org

#安装docker
echo "检查Docker是否已安装……"
docker -v
if [ $? -eq  0 ]; then
echo "检测到docker已安装，跳过"
else
echo "检测到docker未安装，开始安装"
wget -qO- get.docker.com | bash
echo "docker安装完成“
fi

#安装rclone
echo "检查rclone是否已安装..."
rclone --version
if [ $? -eq  0 ]; then
echo "检测到rclone已安装，跳过"
else
echo "检测到rclone未安装，开始安装..."
curl https://rclone.org/install.sh | bash
fi

#安装rclone挂载fuse
echo "安装fuse"
apt-get install fuse

#创建需要的目录


mkdir -p /home/jackett1/config
mkdir -p /home/jackett1/downloads

mkdir -p /home/cnsub/config
mkdir -p /home/cnsub/browser

mkdir /home/shh
mkdir /home/log
touch /home/shh/rclone.conf

#安装nas-tools
echo "开始安装nas-tools"
#创建目录
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
read -r -p "nas-tools没有内置字幕下载功能，需借助第三方软件，是否安装字幕下载器chinesesubfinder？ (y/n，默认安装) cnsubinstall
case $cnsubinstall in
  [yY])   
    echo "开始安装字幕下载器chinesesubfinder"
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
    echo "字幕下载器chinesesubfinder已安装完成"
    ;;
  *)
    echo "不安装字幕下载器chinesesubfinder"
    ;;
esac

#安装种子索引器jacketta
read -r -p "nas-tools已经内置种子索引器，是否额外安装种子索引器jackett？(y/n，默认不安装): " jackettinstall
case $jackettinstall in
  [yY]) 
     echo "开始安装jackett..."
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
     echo "jackett安装完成"
     ;;
  *)
     echo "不安装jackett"
     ;;
esac

#安装inotifywait
apt install inotify-tools -y

#生成rclone自动上传脚本nasup.sh
echo "生成脚本nasup.sh"
read -r -p "rclone远端地址[格式,盘符:路径]: " remote_dir
read -r -p "rclone上传线程数[默认为4]: " rclone_num
if [ -z $rclone_num ]; then
rclone_num=4
else
fi
echo "#!/bin/bash
local_dir=/home/nastools/media/storage/
remote_dir=${remote_dir}
rclone_num=${rclone_num}" > /home/shh/nasup.sh

echo 'log_dir=/home/log/nasup.log
rclone_config_dir=/home/shh/rclone.conf
rclone_log_dir=/home/log/rclone.log
libraryrefresh_dir=/home/shh/libraryrefresh.py

echo "[$(date "+%Y-%m-%d %H:%M:%S")] 开始运行脚本" >> ${log_dir}

while
inotifywait -r $local_dir -e modify,delete,create,attrib,move;

do  
echo "[$(date "+%Y-%m-%d %H:%M:%S")] 检测到文件异动,休眠1分钟，nfo识别字幕下载" \
>> ${log_dir}
sleep 2m

echo "[$(date "+%Y-%m-%d %H:%M:%S")] rclone上传开始" >> ${log_dir}
/usr/bin/rclone move -v ${local_dir} ${remote_dir} \
--transfers ${rclone_num} --config ${rclone_config_dir} >> ${rclone_log_dir} 2>&1 &&
echo "[$(date "+%Y-%m-%d %H:%M:%S")] rclone上传完成" >> ${log_dir}
   
   while 
   [ ! `/usr/bin/rclone ls ${local_dir} | wc -l` -eq 0 ]
   
   do
   echo "[$(date "+%Y-%m-%d %H:%M:%S")] 仍有文件存在，再次上传" \
   >> ${log_dir}
   /usr/bin/rclone move -v ${local_dir} ${remote_dir} \
   --transfers ${rclone_num} --config ${rclone_config_dir} \
   >> ${rclone_log_dir} 2>&1 &&
   echo "[$(date "+%Y-%m-%d %H:%M:%S")] rclone再次上传完成" \
   >> ${log_dir}   
   
   done
   
   echo "[$(date "+%Y-%m-%d %H:%M:%S")] 文件夹已无文件存在" \
   echo "[$(date "+%Y-%m-%d %H:%M:%S")]执行扫库命令" >> ${log_dir}
   
   if /usr/bin/python3 ${libraryrefresh_dir};then
      echo "[$(date "+%Y-%m-%d %H:%M:%S")]自动扫库正常" >> ${log_dir}
   else 
      echo "[$(date "+% Y-%m-%d %H:%M:%S")]自动扫库失败" >> ${log_dir}
   fi	
      echo "[$(date "+%Y-%m-%d %H:%M:%S")] 再次监控文件夹变化" >> ${log_dir}

done' >> /home/shh/nasup.sh
#赋予脚本执行权限
chmod +x /home/shh/nasup.sh
#设置nas.sh脚本开机启动
echo "设置nas.sh脚本开机启动"
crontab -l > crontab_test
echo "@reboot bash /home/shh/nasup.sh
0 0 * * * rm -rf /home/log" >> crontab_test
crontab crontab_test

#生成emby自动扫库脚本
pip --version
if [ $? -eq  0 ]; then
   pip3 --version
   if [ $? -eq  0 ]; then
   curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
   sudo python get-pip.py
   fi
fi

echo "生成emby自动扫库脚本"
read -r -p "emby地址[格式http://1.1.1.1:8896,https://emby.com:8896]: " emby_url
read -r -p "emby_apikey: " api_key
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
 read -r -p "是否安装qbittorrent？ (y/n,默认安装) qbitinstall
 case $qbittorrent in
 [Yy])
   qbtcount=`ps -ef |grep qbittorrent |grep -v "grep" |wc -l` 
   if [ 0==$qbtcount ]; then 
   echo "开始安装qbittorrent"
   wget -qO "/usr/local/bin/x86_64-qbittorrent-nox" https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-4.4.5_v2.0.7/x86_64-qbittorrent-nox &&
   chmod 700 "/usr/local/bin/x86_64-qbittorrent-nox" &&
   echo "[Unit]" > /etc/systemd/system/qbit.service &&
   echo "Description=qBittorrent Service" >> /etc/systemd/system/qbit.service &&
   echo "After=network.target nss-lookup.target" >> /etc/systemd/system/qbit.service &&
   echo "[Service]" >> /etc/systemd/system/qbit.service &&
   echo "UMask=000" >> /etc/systemd/system/qbit.service &&
   echo "ExecStart=/usr/local/bin/x86_64-qbittorrent-nox --profile=/usr/local/etc" >> /etc/systemd/system/qbit.service &&
   echo "[Install]" >> /etc/systemd/system/qbit.service &&
   echo "WantedBy=multi-user.target" >> /etc/systemd/system/qbit.service &&
   systemctl enable qbit &&
   systemctl start qbit
   systemctl status qbit 
   echo "qbittorrent脚本安装完毕
   qbittorrent运行: systemctl start qbit
   qbittorrent停止: systemctl stop qbit
   qbittorrent重启: systemctl restart qbit"
   echo "qbittorrent用户名：admin"
   echo "qbittorrent密码：adminadmin"
   else
   echo "检测到qbittorrent已安装，跳过"
   fi
 *)
   echo "不安装qbittorrent"
   ;;
esac

#开启bbr
lsmod | grep bbr 
if [ $? -eq 1 ]; then
 echo "开始开启原版bbr"
 echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
 echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
 sysctl -p
 lsmod | grep bbr 
 echo "若输出【tcp_bbr 20480  1】即表示成功开启bbr"
else 
fi
 
#重启
echo "alias 21mediastop/start="sh /root/21media.sh" >> /etc/profile
echo "安装完成，5秒后重启
后续可通过输入 21media 打开脚本启动界面

后续操作：
1、复制rclone配置文件到目录下：/home/shh/
2、修改qbittorrent用户名,密码
  登录地址：http://ip:8080
  用户名：admin 
  密码：dminadmin
3、初始化jackeet,复制api_key[未安装则跳过]
  登录地址：http://ip:47555
4、申请tmdb_apikey，在nas-tools中配置
5、置nas-tools,默认登陆,用户名:admin 密码:password.基础设置,配置移动方式为硬链接或者移动.索引器为内置或者jackeet,下载器qbittorrent.
  登录地址：http://ip:3000
6、初始化字幕下载工具，打开实验室功能，生成api_key保存，开启进程守护"
  登录地址：http://ip:19035
sleep 5s
reboot
}

21unstall() {
mkdir /home/21backup
cp /home/nastools/config/config.yaml /home/21backup
cp /home/nastools/config/default-category.yaml /home/21backup
echo "nas-tools配置文件已备份到 /home/21backup"
cp /home/shh/rclone.conf /home/21backup
echo "rclone配置文件已备份到 /home/shh" 
docker stop nas-tools | docker rm nas-tools
docker stop jackeet | docker rm jackett
docker stop cnsub | docker rm cnsub
docker rmi nas-tooks jackett cnsub
rm -rf /home/cnsub /home/jackett /home/log /home/nastools /home/shh
systemctl stop qbit
systemctl disable qbit
read -r -p "是否卸载rclone？(y/n,默认卸载) rcloneuninstall
case $rcloneunstall in 
  [yY])
      rm -rf /root/.config/rclone/rclone.conf /usr/bin/rclone /usr/local/share/man/man1/rclone.1 /etc/systemd/system/rclone.service
      ;;
    *)
      echo "不卸载rclone"
      ;;
  esac
read -r -p "是否卸载qbittorrent？(y/n,默认卸载) qbituninstall
case $qbituninstall in 
  [yY])
      rm -rf /usr/local/bin/x86_64-qbittorrent-nox /usr/local/etc/qBittorrent
      ;;
    *)
      echo "不卸载rclone"
      ;;
esac
echo "脚本卸载完毕，有缘江湖再见"
}

21nasuplog() {
cat /home/log/nasup.log
}

21rclonelog() {
cat /home/log/rclone.log
}



#https://github.com/ershiyi21/media21.原创个人自用脚本.目前仅适用于debian&ubuntu x86系统.
#一键安装运行nas-tools,jackett,qbittorrent,chinesesubfinder,rclone.配置好nas-tools媒体库等设置.
#后续可通过输入 21media 打开脚本启动界面
