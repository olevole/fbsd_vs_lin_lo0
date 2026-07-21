#!/bin/sh

doit()
{
# Список зон, которые мониторит netstat -m
ZONES="mbuf mbuf_cluster mbuf_jumbo_page mbuf_jumbo_9k mbuf_jumbo_16k"

echo "# HELP freebsd_mbuf_items_current Current number of items in use"
echo "# TYPE freebsd_mbuf_items_current gauge"
echo "# HELP freebsd_mbuf_items_total Total items allocated (current + cache)"
echo "# TYPE freebsd_mbuf_items_total gauge"
echo "# HELP freebsd_mbuf_items_max Maximum allowed items"
echo "# TYPE freebsd_mbuf_items_max gauge"
echo "# HELP freebsd_mbuf_bytes_total Total memory allocated for this zone in bytes"
echo "# TYPE freebsd_mbuf_bytes_total gauge"

for zone in $ZONES; do
    # Проверяем существование зоны в sysctl
    if ! sysctl "vm.uma.$zone.size" >/dev/null 2>&1; then
        continue
    fi

    # Извлекаем значения
    current=$(sysctl -n "vm.uma.$zone.stats.current")
    total=$(sysctl -n "vm.uma.$zone.limit.items")
    max=$(sysctl -n "vm.uma.$zone.limit.max_items")
    size=$(sysctl -n "vm.uma.$zone.size")

    # Считаем байты (total * size)
    bytes_total=$((total * size))

    # Вывод метрик с лейблом зоны
    echo "freebsd_mbuf_items_current{zone=\"$zone\"} $current"
    echo "freebsd_mbuf_items_total{zone=\"$zone\"} $total"
    echo "freebsd_mbuf_items_max{zone=\"$zone\"} $max"
    echo "freebsd_mbuf_bytes_total{zone=\"$zone\"} $bytes_total"
done

}

while [ true ]; do
	doit > /var/tmp/node_exporter/mbuf_stats.prom
	sleep 10
done
