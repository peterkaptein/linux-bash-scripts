# We use Gnupg to encrypt files befofe we send them to the server.
# How it works:
# 1: The server does a dry-run to the destination, looking at change-date onely
#    - Thus we know which local files are newer
# 2: We encrypt the updated file locally to filename.suffix.enc
# 3: We copy the encrypted, hidden file to the server. 
# 4: We copy a dummy of the 
# To check which files require encryption, we first check if the source is outdated or not. by running a dry-run to the server

copyAsEncrypted(){
    source="$1"      # Our unencrypted local file
    destination="$2" # Our encrypted dest file

    # From version 2 of GPG, the option --batch is needed to ensure no prompt..
    gpg --symmetric --batch --passphrase "$gl_certificateFile" --cipher-algo AES256 -o "$backup_file" "$local_file"
    # gpg --batch --passphrase "your_passphrase" -c --cipher-algo AES256 your_file.txt
}

copyAsDecrypted(){
    source="$1"       # Our encrypted remote file
    destination="$2"  # Our unencrypted local destination file

    gpg -d  --symmetric  --batch --passphrase "$gl_certificateFile" --cipher-algo AES256 -o "$local_file" "$backup_file"
    # gpg --symmetric --cipher-algo AES256 -o "$backup_file" "$local_file"
}



collectListOfDeletedFiles(){
    localDir=$1
    remoteDir=$2
    resultFile=$3
    # This is the same as a dry-run by rsync, but knowing that remote files 
    # Have the .e suffix

    find "$remoteDir" |
    while
    do
    # Append result to resultFile 

        
        if [[ ! "$local_file" ]]
        then
            # Output that can be collected
            # Same as rsync so we can use same code to process this
            echo "deleted $local_file"
        fi
    done
}

handleDeletedFiles(){
    fromDir="$1" 
    toDir="$2" 

   
    # Recursively go through destination files
    find "$toDir" |
    for  fileName
    do
        if [ ! "$from_file" ] # "from" file was deleted|
        then 
            # We are mirroring "from"
            # So delete this file from "to" as well
            rm "$to_file"
            # Done
        fi
    done    
}
syncSourceToDestiny(){

    sourceDir=$1
    remoteDir=$2

    handleDeletedFiles "$sourceDir" "$remoteDir"

    # Recursively go through local files
    find "$sourceDir" |
    for  fileName
    do     

        # Added?
        if [ ! "$backup_file" ] # Remote Backup file does not exist
        then
            # Encrypt the local file and save it to remote
            echo ""
            copyAsEncrypted "$local_file" "$backup_file"

            # Done
            return
        fi

        # Changed?
        # Target has ".e" suffix to indicate it is encrypted
        # And to avoid acidental overwrites of non-encrtyptred files
        if [ "$local_file" -nt "$backup_file" ]
        then # Local file is newer
            echto ""
            copyAsEncrypted "$local_file" "$backup_file"
            # Encrypt the local file and copy it to destination
        fi

    done
}

mirrorLocalToRemote(){

    sourceDir=$1
    remoteDir=$2

    handleDeletedFiles "$sourceDir" "$remoteDir"

    syncSourceToDestiny "$sourceDir" "$remoteDir"

}

mirrorRemoteToLocal(){
    remoteDir="$1"
    sourceDir="$2"

    # Remove all encrypted files from local

    # Remove all non-encrypted files from remote


    # Delete all files from source that were deleted on remote
    handleDeletedFiles "$remoteDir" "$sourceDir"

    # Then sync remote to source
    syncSourceToDestiny "$remoteDir" "$sourceDir"

}

doInitialDownload(){
    destinationDir="$1" 
    sourceDir="$2"

    # Decrypt all files from remote
    syncSourceToDestiny "$remoteDir" "$sourceDir"
   
}