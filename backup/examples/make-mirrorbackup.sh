source ../mirror-backup.sh


# Definations
username="peterkaptein"
serverOne="SRV01.local"
serverSideBackupDriveMountPoint="/mnt/Primary"

# Connect-packages
connectPackage_server01ToServer02Sync=("server" "$username" "$serverOne" "$serverSideBackupDriveMountPoint")
connectPackage_clientToServer01Sync=("client" "$username" "$serverOne" "$serverSideBackupDriveMountPoint")

# Bakup locations
remoteBackupDir="MyMirrorbackups" # No spaces allowed
folderToBackup="/home/peterkaptein/Documents/git/bash-scripts/backup/deltas"

echo "start sync"
mirrorSync "${connectPackage_clientToServer01Sync[@]}" "$remoteBackupDir" "$folderToBackup"