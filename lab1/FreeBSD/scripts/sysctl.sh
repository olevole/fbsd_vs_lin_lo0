
# Увеличиваем количество портов и лимиты соединений
sysctl -w net.inet.ip.portrange.first=1024
sysctl -w net.inet.ip.portrange.last=65535
sysctl -w kern.ipc.somaxconn=10240

# Оптимизация TCP стека
sysctl -w net.inet.tcp.fastopen.server_enable=1
sysctl -w net.inet.tcp.fastopen.client_enable=1
sysctl -w net.inet.tcp.sendspace=65536
sysctl -w net.inet.tcp.recvspace=65536
sysctl -w net.inet.tcp.mssdflt=1460


sysctl -w net.inet.tcp.msl=60000

# Отключаем ожидание завершения (TIME_WAIT) для быстрых тестов
#net.inet.tcp.nolinger=1
#net.inet.tcp.blackhole=2
#net.inet.udp.blackhole=1

# Увеличиваем число файловых дескрипторов
#kern.maxfiles=204800
#kern.maxfilesperproc=200000

# Для высокоскоростных сетей (10Gbps+) - /boot/loader.conf
#sysctl -w net.inet.tcp.soreceive_stream=1

#На lo0 узким местом станет блокировка (lock) в сетевом стеке и планировщик задач.
#
#    net.inet.tcp.delayed_ack=0: Для мелких ответов (один пакет) задержка подтверждения (ACK) — это смерть для RPS. Выключайте не задумываясь.
sysctl -w net.inet.tcp.delayed_ack=1

# так в 0 или 1?!
# (Вы его уже могли ставить, но убедитесь, что он в 0 — это критично для RPS).

# Если вы контролируете нагрузку, выключите защиту от SYN-флуда, чтобы ядро не тратило циклы CPU на генерацию кук.
sysctl -w net.inet.tcp.syncookies=0

# Позволяет планировщику (ULE) более агрессивно переключать потоки, что полезно для конкурентных запросов.
#sysctl -w kern.sched.preempt_thresh=0

#  Тюнинг lo0 (Loopback)
# Интерфейс lo0 во FreeBSD — это не просто виртуальная железка, он проходит через весь сетевой стек.
#net.inet.ip.intr_queue_maxlen=4096: Увеличьте размер очереди входящих IP-пакетов, чтобы ядро не дропало пакеты при лавинообразном RPS
sysctl -w net.inet.ip.intr_queue_maxlen=4096


#net.isr.dispatch=direct: Для lo0 прямой диспатчинг (в контексте текущего CPU) обычно быстрее, чем deferred. Это экономит время на перекладывание пакета в очередь другого потока.
#
sysctl -w net.isr.dispatch=direct

# Поможет быстрее вычищать структуры в памяти.
sysctl -w net.inet.tcp.fast_finwait2_recycle

#Поскольку файл мелкий и вы на lo0, автотюнинг буферов только тратит CPU. Установите фиксированные значения (например, 64к).
sysctl -w net.inet.tcp.recvbuf_auto=0
sysctl -w net.inet.tcp.sendbuf_auto=0

# Использование менее точного, но более быстрого источника времени
#sysctl kern.timecounter.choice
# И установите лучший (обычно TSC-low, если он есть)
sysctl -w kern.timecounter.hardware=TSC-low

# Включает ABC (Appropriate Byte Counting), помогает более эффективно управлять окном на высоких скоростях.
sysctl -w net.inet.tcp.cc.abe=1

# 
# Если вы уверены в надежности памяти, отключаем проверку контрольных сумм на lo0
# На loopback ядро и так часто это пропускает, но стоит форсировать:
ifconfig lo0 -txcsum -rxcsum -txcsum6 -rxcsum6


# Запрещаем ядру уходить в глубокие C-states (экономия энергии), что снижает задержки пробуждения
sysctl -w dev.cpu.0.cx_lowest=C1
sysctl -w dev.cpu.1.cx_lowest=C1

# Параметр net.inet.tcp.per_cpu_timers=1 меняет архитектуру работы таймеров TCP в ядре.
#Что это дает на самом деле:
#По умолчанию во FreeBSD (значение 0) используется классическая модель, где таймеры TCP (например, для отслеживания retransmit или keep-alive) обрабатываются централизованно. Это может приводить к блокировкам (contention) на больших RPS, даже если процесс привязан к ядру.
#Установка в 1:
#
#    Локализация прерываний: Ядро распределяет обработку таймеров по всем ядрам CPU.
#    Снижение блокировок: Таймеры для конкретного соединения обрабатываются на том же ядре, где «живет» это соединение.
#    Эффект для бенчмарка: В вашем сценарии (много соединений на одном ядре) это снижает накладные расходы на переключение контекста и обращения к глобальным структурам ядра. Это «ускорение» за счет более эффективной параллельной работы, а не прямого отключения функций.

sysctl -w net.inet.tcp.per_cpu_timers=1


# засинхрить с backlog nginx ?
sysctl -w kern.ipc.soacceptqueue=16384

sysctl -w net.inet.icmp.icmplim=0

# пересборка nginx:
#На 16-CURRENT и одном ядре огромную роль играет кэш-попадание (L1/L2). Если nginx из бинарного пакета, он собран под «generic» x86-64.
#Пересоберите его из портов:
# Это позволит компилятору использовать инструкции AVX/BMI2 и инлайнить функции, что на 700k+ RPS может дать те самые заветные 5-10% прироста.
#make -C /usr/ports/www/nginx-devel CFLAGS="-O3 -march=native -flto" install
#

# upd: olevole: реально дало +4.55% ^
# 931566 - 891050 = 40516
# 40516 / 891050 = 4.55
#


kldload accf_http
kldload accf_data
