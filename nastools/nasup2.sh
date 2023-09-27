#!/bin/bash
local_dir=/home/nastools/media/storage/
remote_dir=trgd:/emby
rclone_num=10 #rclone上传并行数
log_dir=/home/log/nasup.log
rclone_config_dir=/home/shh/rclone.conf
rclone_log_dir=/home/log/rclone.log
rclone_temlog_dir=/home/log/rclone.temlog
tg_chat_id=""
tg_bot_token=""
rclone_exclude="其它/"  #rclone上传排除的目录
remote_username=""
remote_password=""
remote_ip=""
remote_port=""


#emby扫库
21embyrefresh() {
    a=`cat ${rclone_temlog_dir}|grep Copied|cut -d ":" -f 4|cut -d "/" -f 1-3|cut -b 2-|grep '[[:blank:]]([[:digit:]]\{4\})$'|sort -u|wc -l`
    tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] emby即将扫描文件夹数：${a}."
	  for((i=1;i<=${a};i++)); 
    do   
        b=`cat ${rclone_temlog_dir}|grep Copied|cut -d ":" -f 4|cut -d "/" -f 1-3|cut -b 2-|grep '[[:blank:]]([[:digit:]]\{4\})$'|sort -u|sed -n "${i}p"`
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] emby开始扫库${emby_dir}${b}..." >> ${log_dir} 

        encoded_param=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$b'))")
        c=`curl -u ${remote_username}:${remote_password} =I "http://${remote_ip}:${remote_port}/execute-script?code_path=/home/remote/link.py&param=${encoded_param}" | grep -Fi HTTP | awk '{print $2}'`

        [[ "${c}" =~ 200 ]] && echo "[$(date "+%Y-%m-%d %H:%M:%S")] ${c},emby扫库成功${b}！！！" >> ${log_dir} \
        || echo "[$(date "+%Y-%m-%d %H:%M:%S")] ${c},emby扫库失败${b}！！！"  >> ${log_dir}  
        sleep 1s    
    done
}

#tg通知与日志输出
tgnotice() {
    curl -s -X POST "https://api.telegram.org/bot${tg_bot_token}/sendMessage" -d chat_id=${tg_chat_id} -d text="${1}"
	  echo ${1} >> ${log_dir}
}

#rclone上传
21rcloneup() {
    try_num=$1

    [ ! `/usr/bin/rclone ls "${local_dir}/剧集" --exclude ${rclone_exclude}| wc -l` -eq 0 ] \
    && tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] 第${try_num}次上传开始.剧集."
    /usr/bin/rclone move -v ${local_dir} 1e5:/emby \
    --include "/剧集/**" \
	--transfers ${rclone_num} --config ${rclone_config_dir} \
	>> ${rclone_temlog_dir} 2>&1 

    [ ! `/usr/bin/rclone ls "${local_dir}/动漫" --exclude ${rclone_exclude}| wc -l` -eq 0 ] \
    && tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] 第${try_num}次上传开始.动漫."
    /usr/bin/rclone move -v ${local_dir} 2e5:/emby \
    --include "/动漫/**" \
	--transfers ${rclone_num} --config ${rclone_config_dir} \
	>> ${rclone_temlog_dir} 2>&1

    [ ! `/usr/bin/rclone ls "${local_dir}/电影" --exclude ${rclone_exclude}| wc -l` -eq 0 ] \
    && tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] 第${try_num}次上传开始.电影."
    /usr/bin/rclone move -v ${local_dir} 3e5:/emby \
    --include "/电影/**" \
	--transfers ${rclone_num} --config ${rclone_config_dir} \
	>> ${rclone_temlog_dir} 2>&1
    
    
    tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] 第${try_num}次上传完成."
}

#rclone配置文件检测
tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] 开始运行脚本"
if [ ! -s "/home/shh/rclone.conf" ] ; then
tgnotice "rclone配置文件未复制到目录/home/shh/ 退出nasup脚本"
exit 1s
fi


#脚本主体

while
inotifywait -r $local_dir -e modify,delete,create,attrib,move;

do  
    tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] 检测到文件异动,等待100秒"   
    sleep 100s
 
    [ ! `/usr/bin/rclone ls ${local_dir} --include ${rclone_exclude}| wc -l` -eq 0 ] \
    && tgnotice "已排除目录 ${local_dir}${rclone_exclude} 有新文件移入."
	
     try_num=1  
     while 
     [ ! `/usr/bin/rclone ls ${local_dir} --exclude ${rclone_exclude}| wc -l` -eq 0 ]
     do	   
         21rcloneup ${try_num}
         21embyrefresh
         cat ${rclone_temlog_dir} >> ${rclone_log_dir}
         echo > ${rclone_temlog_dir}
         let try_num=${try_num}+1		
    done
    
    tgnotice "[$(date "+%Y-%m-%d %H:%M:%S")] 文件已全部上传,继续监控文件夹！"	
    
done
