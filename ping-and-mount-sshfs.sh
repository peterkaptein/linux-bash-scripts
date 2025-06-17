# This script will ping a remote locaton, and mount it, if it is available.

# If the ping fails, the remote location will be unmounted, as it is useless.

# laptop external drive
# UUID=808e660f-c073-4ada-99f8-b69ee6f2bcfb	/media/external	ext4	noatime,nofail,x-systemd.device-timeout=10	0	2

# and this is a network drive -

# server
# 192.168.1.100:/	/media/server	nfs	_netdev,x-systemd.automount,x-systemd.mount-timeout=10	0	0