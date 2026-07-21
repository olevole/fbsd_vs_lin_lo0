#!/bin/sh
# 
# sonewconn: pcb 0xfffff80018c7d540 (127.0.0.1:8080 (proto 6)): Listen queue overflow: 193 already in queue awaiting acceptance (1 occurrences), euid 0, rgid 0, jail 0
# - это не общесистемная метрика а per-port/app
# Current listen queue sizes (qlen/incqlen/maxqlen)
netstat -Lan
