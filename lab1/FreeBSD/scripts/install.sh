#!/bin/sh
pgm="${0##*/}"                  # Program basename
progdir="${0%/*}"               # Program directory

# уносим известные системные сервисы на 0 ядро, чтобы не мешались
#service syslogd onestop
#service syslogd disable
#service cron onestop
#service cron disable

[ ! -d /usr/local/etc/nginx -a ! -h /usr/local/etc/nginx ] && ln -s ${rootdir}/etc/nginx /usr/local/etc/nginx
[ ! -h /usr/local/etc/haproxy.conf ] && ln -s ${rootdir}/etc/haproxy.conf /usr/local/etc/haproxy.conf 

cp -a ${rootdir}/etc/inetd.conf /etc/inetd.conf

pkg install -y haproxy nginx toxiproxy-cli toxiproxy-server curl httping gmake libepoll-shim gawk socat node_exporter

service nginx enable
#service haproxy enable

#service toxiproxy-server enable
#service toxiproxy-server start

if [ ! -x /usr/local/bin/h1load ]; then
	gmake SSL_LFLAGS="-lssl -lcrypto -lepoll-shim -L/usr/local/lib" INC_CFLAGS="-I/usr/local/include/libepoll-shim" -C /root/ha-profile-bench/h1load
	install -m 0755 /root/ha-profile-bench/h1load/h1load /usr/local/bin/h1load
	rm -f /root/ha-profile-bench/h1load/h1load /root/ha-profile-bench/h1load/h1load.o
fi

service nginx restart
#service haproxy restart

echo "NGINX"
echo
curl http://127.0.0.1:8080/index.html
echo
#echo "HAPROXY"
#curl http://127.0.0.1/index.html
#echo

#sysrc inetd_enable=YES inetd_cpuset="-l 0" node_exporter_enable=YES node_exporter_cpuset="-l 0"

#service inetd restart
#service node_exporter restart
