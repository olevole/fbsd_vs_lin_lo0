#!/bin/sh
dtrace -n '
profile-997 /execname == "haproxy"/ {
    @[ustack(100), stack()] = count();
}
tick-30s { exit(0); }' -o /tmp/haproxy_stacks.txt
