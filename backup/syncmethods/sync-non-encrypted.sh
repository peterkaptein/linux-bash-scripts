

collectListOfDeletedFiles(){
    sourceDir="$1"
    destinationDir="$2"
    deletedLogFile="$3"
    rsync --dry-run --delete -ar --info=DEL  "$sourceDir" "$destinationDir" >> "$deletedLogFile" 
}

doInitialDownload(){
    destinationDir="$1" 
    sourceDir="$2"
    # Copy from server to client.
    rsync -aruvP "$destinationDir" "$sourceDir"
    # We do NOT delete local files that are not present on server 
}

mirrorLocalToRemote(){
    sourceDir="$1"
    destinationDir="$2"
    outgoingLogFile="$3"
    rsync --delete -aruvP --info=BACKUP "$sourceDir" "$destinationDir" >> "$outgoingLogFile"
}
mirrorRemoteToLocal(){
    sourceDir="$1"
    destinationDir="$2"
    incomingLogFile="$3"

    rsync --delete -aruvP --info=BACKUP "$destinationDir" "$sourceDir" >> "$incomingLogFile"
    
}
