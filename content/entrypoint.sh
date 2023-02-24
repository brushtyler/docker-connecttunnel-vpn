#!/bin/bash

if [ -z "$VPN_SERVER" ] || [ -z "$VPN_REALM" ] || [ -z "$VPN_USER" ] || [ -z "$VPN_PASS" ] || [ -z "$VPN_FINGERPRINT" ] ; then
	echo "Provide VPN_SERVER, VPN_REALM, VPN_USER, VPN_PASS and VPN_FINGERPRINT using config.env env file" >&2
	exit 1
fi

# debug mode
if [ -n "$VPN_DEBUG" ] ; then
	VPN_OPTIONS="$VPN_OPTIONS --debug"
fi

# no option to configure logfile path
VPN_LOGFILE=/root/.sonicwall/AventailConnect/library/logs/AventailConnect.log
rm -f "$VPN_LOGFILE"

trap 'echo; [ ! -z $VPN_PID ] && kill $VPN_PID 2>/dev/null' exit

# be sure to catch expect failure code
set -o pipefail

/usr/bin/expect <<EOF | tee "$SCRIPTDIR/.out"
spawn -ignore HUP startct --mode console --server $VPN_SERVER --realm $VPN_REALM --username $VPN_USER --password ${VPN_PASS/$/\\\$} $VPN_OPTIONS
# print spawned process PID
set pid [exp_pid]
puts "PID: \$pid"
set timeout 10
# Root CA check
expect -re {Fingerprint: SHA1\[([A-Z0-9:]+)\]} {
  if {![string match "${VPN_FINGERPRINT}" \$expect_out(1,string)]} {
    exit 10 # root CA match failed
  }
  expect "Do you want to accept this certificate*" {
    send -- "YES"
    send -- "\r"
  }
}
# Validate fingerprint (step 2)
expect -re {Fingerprint: SHA1\[([A-Z0-9:]+)\]} {
  if {![string match "${VPN_FINGERPRINT2}" \$expect_out(1,string)]} {
    exit 10 # root CA match failed
  }
  expect "Do you want to accept this certificate*" {
    send -- "YES"
    send -- "\r"
  }
}

# otp
expect "Enter the code:" {
  send -- "$VPN_OTP"
  send -- "\r"
  expect "Enter your choice *" {
    send -- "1"
    send -- "\r"
  }
}

# wait for connected
expect {
  timeout { exit 2 }
  "Disconnected" { exit 3 }
  "Connected"
}
# background vpn process
expect_background
exit 0
EOF

RET=$?
VPN_PID="$(cat "$SCRIPTDIR/.out" | grep -E '^PID: [0-9]+$' | cut -d' ' -f2)"
rm -f "$SCRIPTDIR/.out"

if [ ! -d /proc/$VPN_PID ] ; then
    # vpn process not found, check if process forked and now runs with a different PID
    VPN_PID=$(pidof startct)
fi

if [ -n "$VPN_DEBUG" ] && [ -e "$VPN_LOGFILE" ] ; then
        # debug mode enabled, tail logfile
        echo && tail -n+1 -f "$VPN_LOGFILE" &
fi

echo

if [ $RET -eq 10 ] ; then
	# Root CA fingerprint doesn't match
	echo "Root CA fingerprint doesn't match!" >&2
	exit 1
elif [ $RET -ne 0 ] ; then
	# connection error, expect script failed
	echo "Connection error" >&2
	exit 2
elif [ -z "$VPN_PID" ] ; then
	# process failed
	echo "VPN process failed" >&2
	exit 3
fi

echo "The VPN connection is stable (PID: $VPN_PID)"

# process running, wait until finished
tail -f --pid=$VPN_PID /dev/null
