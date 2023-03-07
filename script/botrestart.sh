#!/bin/bash

open_sign() {
sudo supervisorctl stop bot
rm /home/shh/bot.py
cp /home/shh/bot.py.1 /home/shh/bot.py
sudo supervisorctl start bot
echo "1"
}

close_sign() {
sudo supervisorctl stop bot
rm /home/shh/bot.py
cp /home/shh/bot.py.2 /home/shh/bot.py
sudo supervisorctl start bot
echo "2"
}

menu() {
    
	echo "1.1"
	echo "2.2"
	
	echo -n "请输入数字："
     read num
     case $num in 
        1)
	    open_sign	    
	    ;;
	    2)
	    close_sign
	    ;;
	    *)
	    echo "输入错误"
	    menu
	    ;;
    esac
}

case $1 in
    1)
    open_sign
    ;;
    2)
    close_sign
    ;;
    *)
    menu
    ;;
esac

