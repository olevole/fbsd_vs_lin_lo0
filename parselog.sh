#!/bin/sh
progdir="${0%/*}"
[ "$progdir" = "$0" ] && progdir="."
progdir=$(cd "$progdir" && pwd -P)

set -e
. ${progdir}/bench.subr
set +e

# Проверяем, что передан файл лога
if [ -z "$1" ] || [ ! -f "$1" ]; then
    echo "Usage: $0 <path-to-log>"
    exit 1
fi

LOGFILE="$1"
SUMMARY_FILE="${LOGFILE%.log}.summary"

# Функция для конвертации человекочитаемого RPS (например, 271k) в чистые числа для расчетов
# (h1load выводит '271k', ${AWK_CMD} переведет это в 271000)
${AWK_CMD} '
BEGIN {
    peak_rps = 0;
    sum_rps = 0;
    count_rps = 0;
    p50 = "-";
    p999 = "-";
}

# 1. Парсим блок посекундного лога (строки, начинающиеся с таймстампа из 10 цифр)
$1 ~ /^[0-9]{10}$/ {
    raw_rps = $8;
    # Если h1load сократил до "k", превращаем в честное число
    if (raw_rps ~ /k$/) {
        sub(/k$/, "", raw_rps);
        current_rps = raw_rps * 1000;
    } else {
        current_rps = raw_rps + 0;
    }
    
    # Игнорируем последние секунды теста, где нагрузка падает до нуля
    if (current_rps > 1000) {
        if (current_rps > peak_rps) { peak_rps = current_rps; }
        sum_rps += current_rps;
        count_rps++;
    }
}

# 2. Парсим блок перцентилей (ищем строки p50 и p99.9)
# $1 - процент, $5 - ttfb(ms), $7 - ttlb(ms)
$1 == "50"     { p50 = $7 " ms"; }
$1 == "99.9"   { p999 = $7 " ms"; }

END {
    avg_rps = (count_rps > 0) ? int(sum_rps / count_rps) : 0;
    
    # Выводим компактный отчет в консоль и файл
    printf "========================================\n"
    printf "  SUMMARY FOR: %s\n", LOGNAME
    printf "========================================\n"
    printf "Peak RPS:    %d req/sec\n", peak_rps
    printf "Average RPS: %d req/sec\n", avg_rps
    printf "Latency p50: %s\n", p50
    printf "Latency p99.9: %s\n", p999
    printf "========================================\n"
}
' LOGNAME="$(basename "$LOGFILE")" "$LOGFILE" | tee "$SUMMARY_FILE"

echo "Summary saved to: $SUMMARY_FILE"

