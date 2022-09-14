#!/bin/bash
local_dir=$1
remote_dir=$2
log_dir=
rclone_config_dir=
libraryrefresh_dir=

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始运行脚本" >> ${log_dir}

while
inotifywait -r $local_dir -e modify,delete,create,attrib,move;
do  
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 检测到文件异动,休眠10分钟，等待字幕下载" \
    >> ${log_dir}
    sleep 10m					 	
    count=`ps -ef |grep rclone |grep -v "grep" |wc -l`
    if [ 0 == $count ];then
       echo "[$(date '+%Y-%m-%d %H:%M:%S')] rclone上传开始" >> ${log_dir}
       /usr/bin/rclone move -v ${local_dir} ${remote_dir} \
       --config ${rclone_config_dir} >> ${log_dir} 2>&1 &&
       echo "[$(date '+%Y-%m-%d %H:%M:%S')] rclone上传完成" \
       >> ${log_dir}
       while 
       [ ! `/usr/bin/rclone ls ${local_dir} | wc -l` -eq 0 ]
       do
	 echo "[$(date '+%Y-%m-%d %H:%M:%S')] 仍有文件存在，再次上传" \
	 >> ${log_dir}
	 /usr/bin/rclone move -v ${local_dir} ${remote_dir} --config ${rclone_config_dir} \
	 >> ${log_dir} 2>&1 &&
         echo "[$(date '+%Y-%m-%d %H:%M:%S')] rclone再次上传完成" \
	 >> ${log_dir}   
       done
	 echo "[$(date '+%Y-%m-%d %H:%M:%S')] 文件夹已无文件存在" \
	 >> ${log_dir}  
    else
	 echo "[$(date '+%Y-%m-%d %H:%M:%S')] rclone已在运行，避免死机，退出脚本" \
	 >> ${log_dir}
	 exit
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]执行扫库命令" >> ${log_dir}
    if /usr/bin/python3 ${libraryrefresh_dir};then
       echo "[$(date '+%Y-%m-%d %H:%M:%S')]自动扫库正常" >> ${log_dir}
    else 
       echo "[$(date '+% Y-%m-%d %H:%M:%S')]自动扫库失败" >> ${log_dir}
    fi	
       echo "[$(date '+%Y-%m-%d %H:%M:%S')] 再次监控文件夹变化" >> ${log_dir}
done
