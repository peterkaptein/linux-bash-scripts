checkIfRemoteFolderExists(){
    _remoteHost="$1"
    _remoteFolder="$2"

    if ssh $_remoteHost test -d "$_remoteFolder"
    then 
        echo true
        return
    fi
    echo false
}

ensureRemoteFolder(){
    _remoteHost="$1"
    _remoteFolder="$2"

    if ssh $_remoteHost mkdir -p "$_remoteFolder" && true
    then 
        echo true
        return 
    fi
    echo false
}

mountSSHFS(){
    _username="$1"
    
    _server="$2"
    _remoteUserFolder="$3"
    _subdirectory="$4"
    _localMountpoint="$5"

    _serverConnectName="$_username@$_server"

    # Check
    if $(checkIfRemoteFolderExists "$_serverConnectName" "$_remoteUserFolder")
    then 
        echo "Check: Remote user folder exists. We can continue mounting"
    else
        echo "Exit: Remote user folder $_remoteUserFolder does not exist on server $_server.
Unable to connect"
        return
    fi

    # Determine what to mount/connect to remotely
    _remoteMountFolder="$_remoteUserFolder/$_subdirectory"
    _remote="$_serverConnectName:$_remoteMountFolder"

    echo "Ensuring mountpoint '$_localMountpoint'"
    mkdir -p "$_localMountpoint"

    if ping -c 1 "$_server" &> /dev/null
    then
        echo "Connecting..."
    else
        echo "Server $_server not found via ping. Exit,"
        echo false
        return 
    fi

    # Ensure remote
    echo "Ensuring remote-folder exists: $_remoteMountFolder" 
    ensureRemoteFolder "$_serverConnectName" "$_remoteMountFolder"

    if mountpoint -q "$_localMountpoint"; then
        echo "OK. Mountpoint: '$_localMountpoint' already mounted"
    else
        echo "Mounting $_remote  to: '$_localMountpoint'"
        # cachin, timeout  86000 = 24 hrs. large_read 700.000 = 7 days
        timeout=(60 * 5) # 5 minutes
        sshfs -o cache=yes,kernel_cache,Compression=no,allow_other,cache_timeout=$timeout "$_remote" "$_localMountpoint"
    fi
    echo "Done connecting"
}

disconnect(){
    _mountpoint="$1"
    fusermount3 -u "$_mountpoint"
}


# SSHFS auto mount
# https://askubuntu.com/questions/412477/mount-remote-directory-using-ssh