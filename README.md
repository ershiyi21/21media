
## dns修改
```
bash <(curl -L -s https://raw.githubusercontent.com/ershiyi21/21media/main/script/dnschange.sh)
```
待优化：

1.输入ip格式准确性判断;2.ipv6使用shell正则,无需借助ipv6calc,实现ipv6 shell文本处理双向格式转换;3.e2fsprogs包的安装[chattr]

## nas-tool脚本
```
cd /root && apt install wget -y && wget https://raw.githubusercontent.com/ershiyi21/21media/main/nastools/21media.sh && chmod +x 21media.sh && bash 21media.sh
```
## iptv源
[贵州移动
](https://raw.githubusercontent.com/ershiyi21/21media/main/iptv/gzyd.m3u)
