
# Mount drive to dir on remote server via SFTP
sshfs peterkaptein@srv01.local:/mnt/backup/peter ~/sftp_backup -o allow_other
# Context:
# - sshfs is a plugin installed to mount sftp as a drive


# Create SSH port forwarding to remote desktop
ssh -L 5012:localhost:3389 peterkaptein@srv01.local
# 
# - port 5012 is local port, forwarded to 3389 (RDP port)


# CLIENT SIDE INSTALLS
# ========================================================================
# Installing SSHFS
sudo dnf install fuse-sshfs
# Context: 
# - project has stopped. There might be built-in solutions in Linux


# Setting up RDP (remote desktop)
# - Use system default


# SERVER SIDE INSTALLS
# 
