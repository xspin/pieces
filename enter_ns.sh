#!/bin/bash
TAG=`curl ip.sb 2>/dev/null| awk -F. '{print "POP"$4}'`
NSID=506350
ip netns exec $NSID /bin/bash --rcfile <(echo "alias timestamp_history='echo -n';PS1='\e[0;31mNS${NSID}@${TAG}\e[m:\w\$ '")
