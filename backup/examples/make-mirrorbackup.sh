myDir="$(dirname $(readlink -f $BASH_SOURCE))"

source $myDir/../mirror-backup.sh


# Definations
_username="peterkaptein"
_usersRemoteRootDir="/mnt/Primary" # Location of backup-drive on server

# Bakup container
_myRemoteBackupContainer="test" # No spaces or subfolders allowed.

# Backup locations
servers=( "SRV01.local" )  
myLocalFolders=( "/home/peterkaptein/Documents/git/bash-scripts/backup/deltas" \
                "/home/peterkaptein/Documents/git/bash-scripts/backup/deltas")


# Backup will go into: server:/mnt/primary/<username>/mirrorbackups/<containername>/<sourcefoldername>"

# Loop through servers
for server in "${servers[@]}"
do
    # Connect-packages
    connectPackage_S01ToS02=("server" "$_usersRemoteRootDir" "$server"  "$_username" "$_myRemoteBackupContainer")
    connectPackage_clientToS01=("client" "$_usersRemoteRootDir" "$server" "$_username" "$_myRemoteBackupContainer")

    echo "start sync"
    for myFileLocation in "${myLocalFolders[@]}"
    do
        mirrorSync "${connectPackage_clientToS01[@]}" "$myFileLocation"
    done
done