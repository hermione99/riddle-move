#!/bin/sh
# AppLoad entry point for takeover mode. AppLoad runs this inside xochitl's
# world, which is about to be stopped — so detach the real launch into a
# transient systemd unit (PID-1-owned, survives xochitl) and exit immediately.
systemctl is-active --quiet riddle-takeover && exit 0
systemd-run --unit=riddle-takeover --collect /bin/bash /home/root/riddle/riddle-takeover.sh
exit 0
