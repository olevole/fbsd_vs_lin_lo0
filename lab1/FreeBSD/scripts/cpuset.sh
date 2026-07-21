#!/bin/sh

PROCESS_MAP="syslogd:0 cron:0 inetd:0 node_exporter:0 nginx:1"

# Пропускаем заголовок ps через tail или просто проверяем, что _pid числовой
ps ax -o pid,ucomm | while read _pid _ucomm; do
	for map in ${PROCESS_MAP}; do
		ucomm_target="${map%:*}"
		cpu_target="${map#*:}"

		if [ "${ucomm_target}" = "${_ucomm}" ]; then
			# В FreeBSD cpuset требует указания типа объекта (-p для PID)
			cpuset -l "${cpu_target}" -p "${_pid}"
			echo "${_ucomm}[${_pid}] -> CPU ${cpu_target}"
		fi
	done
done
