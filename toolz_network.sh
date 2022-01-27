#!/bin/bash

# Waiting for destination host on port number;
# WaitForHost [ip/hostname(default:localhost)] [port(default:80/http)] [protocol(default:tcp)] [prefixstring]
WaitForHost() {
    HOST="${1:-localhost}"
    PORT="${2:-80}"
    PROTO="${3:-tcp}"
    PREFIX="$4"
    while ! echo -n > /dev/$PROTO/$HOST/$PORT; do
        echo "Waiting for $PREFIX$HOST:$PORT proto $PROTO"
        sleep 10
    done
} 2>/dev/null

# for internal use: convert ip to int
ip2int()
{
    local a b c d
    { IFS=. read a b c d; } <<< $1
    echo $(((((((a << 8) | b) << 8) | c) << 8) | d))
}

# for internal use: convert int to ip
int2ip()
{
    local ui32=$1
    local ip n
    for n in 1 2 3 4; do
        ip=$((ui32 & 0xff))${ip:+.}$ip
        ui32=$((ui32 >> 8))
    done
    echo $ip
}

# Get GetNetmask from CDIR prefix;
# GetNetmask [CDIR-prefix] 
GetNetmask() {
    local mask=$((0xffffffff << (32 - $1)))
    int2ip $mask
}

# Get broadcast address of given IP and CDIR prefix;
# GetBroadcast [ip] [CDIR-prefix]
GetBroadcast() {
    local addr=$(ip2int $1)
    local mask=$((0xffffffff << (32 -$2)))
    int2ip $((addr | ~mask))
}

# Get network address of given IP and CDIR prefix;
# GetNetwork [ip] [CDIR-prefix]
GetNetwork() {
    local addr=$(ip2int $1)
    local mask=$((0xffffffff << (32 -$2)))
    int2ip $((addr & mask))
}