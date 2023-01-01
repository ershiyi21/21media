#!/bin/bash
local_dir= #本地路径
remote_dir= #远程路径
rclone_num=4 #rclone上传并行数
log_dir=/home/log/nasup.log #日志文件
rclone_config_dir=/home/shh/rclone.conf #rclone配置文件路径
rclone_log_dir=/home/log/rclone.log #rclone日志存储路径
rclone_temlog_dir=/home/log/rclone.temlog #rclone临时日志存储路径
emby_url=https://xxx.com:443/ #emby服务器地址，务必"/"结尾
api_key= #emby api key
emby_dir=/xxx/ #emby服务器媒体库"主路径"，以"/"结尾
tg_chat_id= #tg发送消息对象id
tg_bot_token= #tg机器人token
rclone_exclude=""  #rclone上传排除的目录.如xxx/

#引入rclone代理
#export http_proxy=http://127.0.0.1:1080
#export http_proxy=socks5://127.0.0.1:1080
#export https_proxy=$http_proxy

#emby扫库
21embyrefresh() {
    a=`cat ${rclone_temlog_dir}|grep Copied|cut -d ":" -f 4|cut -d "/" -f 1-3|cut -b 2-|grep '[[:blank:]]([[:digit:]]\{4\})$'|sort -u|wc -l`
    tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] emby即将扫描文件夹数：${a}."
    
    for((i=1;i<=${a};i++)); 
    do   
        b=`cat ${rclone_temlog_dir}|grep Copied|cut -d ":" -f 4|cut -d "/" -f 1-3|cut -b 2-|grep '[[:blank:]]([[:digit:]]\{4\})$'|sort -u|sed -n "${i}p"`
        tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] emby开始扫库${emby_dir}${b}..."          

        c=`curl -o /dev/null \
		-s -w "%{http_code}\n" \
		-X POST "${emby_url}emby/Library/Media/Updated?api_key=${api_key}" \
		-H  "accept: */*" \
		-H  "Content-Type: application/json" \
		-d "{\"Updates\":[{\"Path\":\"${emby_dir}${b}\",\"UpdateType\":\"Created\"}]}"`
        		
        [[ "${c}" =~ 2[0-9]{2} ]] && tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] ${c},emby扫库成功${emby_dir}${b}！！！" \
        || tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] ${c},emby扫库失败${emby_dir}${b}！！！"
        sleep 1s    
		
    done
       
    cat ${rclone_temlog_dir} >> ${rclone_log_dir}
    echo > ${rclone_temlog_dir}
}

#tg通知与日志输出
tgnotice() {
    curl -s -X POST "https://api.telegram.org/bot${tg_bot_token}/sendMessage" -d chat_id=${tg_chat_id} -d text="${1}"
    echo ${1} >> ${log_dir}
}

#rclone上传
21rcloneup() {
    try_num=$1
    tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] rclone第${try_num}次上传开始."
    /usr/bin/rclone move -v ${local_dir} ${remote_dir} \
    --exclude ${rclone_exclude} \
    --transfers ${rclone_num} --config ${rclone_config_dir} \
    >> ${rclone_temlog_dir} 2>&1 && \
    tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] rclone第${try_num}次上传完成."
}

#rclone配置文件检测
tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] 开始运行脚本"
if [ ! -s "/home/shh/rclone.conf" ] ; then
tgnotice "rclone配置文件未复制到目录/home/shh/ 退出nasup脚本"
exit 2
fi


#脚本主体

while
inotifywait -r $local_dir -e modify,delete,create,attrib,move;

do  
    tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] 检测到文件异动,10s后开始处理..."   
    sleep 10s
 
    [ ! `/usr/bin/rclone ls ${local_dir} --include ${rclone_exclude}| wc -l` -eq 0 ] && \
    tgnotice "已排除目录 ${local_dir}${rclone_exclude} 有新文件移入."
	
    try_num=1  
    
    while 
    [ ! `/usr/bin/rclone ls ${local_dir} --exclude ${rclone_exclude}| wc -l` -eq 0 ]
    
    do	   
        21rcloneup ${try_num}
	21embyrefresh 
        let try_num=${try_num}+1		
    done
   
    tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] 文件已全部上传,继续监控文件夹！"	
	
done
