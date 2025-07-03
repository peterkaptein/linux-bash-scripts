# Mirror-bacup Basis

# Assumptions
# - Both local and remote machines can have mutations
# - After local sync we only need to know what files were added and deleted

# - When local files were deleted, we also want to delete them elsewhere
#   and the other way around. This way, locations update each other

# Possible race conditions
# - File is marked as deleted. The sync hsppens, then memoery is removed
#   - When new sync happens, with servert that still has that file, we wil restore that file
#   Possible solutions:
#   - We need to keep "deleted" list and execute from last sync, 
#     as was the case with original sync/mirror scrpt
#   - OR we sync with all servers 
#   - OR we create a server-size .deleted folder with names and creation date of deleted file 
#     at time of deletion, filesize zero (or minimal)
#     - If a file with the same name is older, it is deleted, and we copy the deleted file. If it is newwe, it has been restored.
#       and needs to be copied.
#     - A deleted file CAN be a symbolic link -- too complex now

# Types of repositories
# 1: Mirrors from local files on computer
# 2: Mirrors from server files, based on network drives


# We will have a local 
# - my-sync-completed-snapshot.txt
# - my-current-snapshot.txt
# - my-newfiles.txt
# - my-deletes.txt

# For the server-directories, we will need to set who is leading
# 1: Client
# 2: Server

# Bash has JSON parser and query
# https://blog.kellybrazil.com/2021/04/12/practical-json-at-the-command-line/
#

#
# =============================================================
# Variables from system
weekNumber=$(date +%U) 
monthName=$(date +%m) 
monthNumber=$(date +%mm) 
year=$(date +%Y)
day=$(date '+%m%d')
hour=$(date '+%Y-%m%d-%H%M%S')

timeslot_hour="$hour" 


__mySyncReportsFolder=".axsync" # Snapshots after sync

# Made each hour / each cycle
__snapshot_dateTimeFileSize="snapshot-date-filesize.txt"
__snapshot_rawFileList_mileStone="snapshot-filelist-milestone.txt" 
__snapshot_rawFileList_mostRecent="snapshot-filelist-mostrecent.txt"
__snapshot_fileList_locallyAbsent="extracted-filelist-locaslly-absent.txt"
__snapshot_fileList_overlapping="extracted-filelist-overlapping.txt"
__snapshot_fileList_locallyAdded="extracted-filelist-locally-added.txt"
__snapshot_fileList_Modified="extracted-filelist-modified.txt"
__deletedFolder=".deleted/"

__prefix_remote="merge-"

__sep="|"

fileExists(){
    file="$1"
    if [ -f "$file" ]
    then     
        echo true
        exit
    fi
    echo false
}

file_A_isOlderThan_B(){
    fileA="$1"
    compareTo="$2"

    if [ "$fileA" -ot "$compareTo" ]
    then
        echo true
        exit
    fi

    echo false
}

fileIsInDeletedFolder(){

    filePath="$1"
    if [[ "$filePath" == *"$__deletedFolder"* ]]
    then
        echo true
        exit
    fi
    echo false
}
fileIsInSyncReportsFolder(){

    if [[ "$myAddedFileName" == *"$__mySyncReportsFolder"* ]]
    then
        echo true
        exit
    fi
    echo false
}

escapePathForRegex(){
    _path="$1"
    echo "$(replace "$_path" "/" "\\/")"
}

createSnapshotFileLocation(){
    _myBackupPath="$1"
    _fileName="$2"

    echo "$_myBackupPath/$__mySyncReportsFolder/$_fileName"
}

createDeletedRefFile()
{
    myDeletedFile="$1"
    echo "Marked as deleted on $hour" > "$myDeletedFile" 
}

ensureDirForFileCopy() {
    # Parameter  based, like Bash-file. $1 is first item in input
    directoryAndFilename="$1" # based on input

    # Ensures a directory is there when needed
    # 1: Get path
    path=$(dirname "$directoryAndFilename") # Standard Bash function to get directory name fron string

    # 2: Create dir if not there yet
    mkdir -p "$path" # Recursive, so if parents are not there, they will be created as well
}

replace(){
    baseString="$1"
    searchFor="$2"
    replaceWith="$3"

    echo "${baseString//"$searchFor"/"$replaceWith"}"
}


getPathTo(){
    myPath="$1"
    echo "${myPath%/*}"
}

get_FileDeletionMarker(){
    myFileLocation="$1"
    path=$(dirname "$myFileLocation")
    fileName=$(basename "$myFileLocation")
    echo "$path/.deleted/$fileName"
}

removeAbsolutePathFromSnapshot(){
    _myBackupPath="$1"
    _snapShotFile="$2"
    echo "removeAbsolutePathFromSnapshot" 
    # Remove absolute path
    escapedBackupPath="$(escapePathForRegex "$_myBackupPath" )"
    sed "s/$escapedBackupPath//" <"$_snapShotFile.abs" > "$_snapShotFile"
}

save_cleanList_diffAdded(){
    _myFile="$1"
    _saveAs="$2"
    
    sed -n "/^[+].*$__sep.*/p" <"$_myFile" | sed -e "s/^[+-].*$__sep//" > "$_saveAs"
}
save_cleanList_diffAbsent(){
    _myFile="$1"
    _saveAs="$2"
    
    sed -n "/^[-].*$__sep.*/p" <"$_myFile" | sed -e "s/^[+-].*$__sep//" > "$_saveAs"
}
save_cleanList_diffOverlapping(){
    _myFile="$1"
    _saveAs="$2"
    
    sed -n "/^[/s].*$__sep.*/p" <"$_myFile" | sed -e "s/^[+-].*$__sep//" > "$_saveAs"
}

# ==============================================================
# SNAPSHOTS
# ==============================================================
make_snapshot_DateTimeSize(){
    _myBackupPath="$1"

    _saveAs="$(createSnapshotFileLocation "$_myBackupPath" "$__snapshot_dateTimeFileSize")"
    ensureDirForFileCopy "$_saveAs"

    # Find all modified files, using filesize and change date
    # If a file has been changed, it will be marked in the diff 
    # as a "removal" and "addition"
    find "$_myBackupPath/" -printf "%s\t%c\t$__sep%P\n" > "$_saveAs.abs"
}


# Generic function: One way to do this
_makeFileListSnapshot(){
    _myBackupPath="$1" # Does not end with /
    _snapshotFileList="$2"

    # Construct name to save file as
    _saveAs="$(createSnapshotFileLocation "$_myBackupPath" "$_snapshotFileList")"
    ensureDirForFileCopy "$_saveAs"

    # Read my local backup path, write to snapshot filelist name / folder
    find "$_myBackupPath/" -printf "$__sep%P\n" > "$_saveAs"

    # We use the | character to separate
}

make_snapshot_fileList_mostRecent(){
     _myBackupPath="$1"

    # Use generc function to make snapshot after sync
     _makeFileListSnapshot "$_myBackupPath" "$__snapshot_rawFileList_mostRecent"
}
make_milestoneSnapshot_fileList(){
     _myBackupPath="$1"

    # Use generc function to make snapshot for current state
     _makeFileListSnapshot "$_myBackupPath" "$__snapshot_rawFileList_mileStone"
}

# We import deleted, and date/time 
# We merge remote-deleted with local deleted, later
# - We use date/time form both local and remote to dertermine what files need to be updated

# ==============================================================
# SNAPSHOT-EXTRACTIONS
# ==============================================================

extract_MyNewAndDeletedFilesFromSnapshot(){
    _myBackupPath="$1"

    # Sources:
    _oldSnapshotFile="$(createSnapshotFileLocation "$_myBackupPath" "$__snapshot_rawFileList_mileStone")" 
    _newSnapshotFile="$(createSnapshotFileLocation "$_myBackupPath" "$__snapshot_rawFileList_mostRecent")"

    # Results: file name
    _saveAsDeleted="$(createSnapshotFileLocation "$_myBackupPath" "$__snapshot_fileList_locallyAbsent")"
    _saveAsAdded="$(createSnapshotFileLocation "$_myBackupPath" "$__snapshot_fileList_locallyAdded")"
   
    ensureDirForFileCopy "$_newSnapshotFile"

    # Find all files and dirs, locally, and list them
    # Produce a simple file list, to find additions and removals
    # Add an = separator-sign to distinguish it from other output
    _myDiffFile="$_newSnapshotFile.diff"
    
    diff -u "$_oldSnapshotFile" "$_newSnapshotFile" > "$_myDiffFile"

    # Code below does the following:
    # 1: Isolate items that start woith a + or - via sed -n
    # 2: Remove any unwatend item using sed -e
    # __sep is the separator we use to make this easier

    # sed -n "/^[-].*$__sep.*/p" <"$_myDiffFile" | sed -e "s/^[+-].*$__sep//" > "$_saveAsDeleted"
    # sed -n "/^[+].*$__sep.*/p" <"$_myDiffFile" | sed -e "s/^[+-].*$__sep//" > "$_saveAsAdded"

    save_cleanList_diffAbsent "$_myDiffFile" "$_saveAsDeleted"
    save_cleanList_diffAdded "$_myDiffFile" "$_saveAsAdded"

    # Result: We have a clean list of all new and deleted files, based on the the SSOT
}

extract_AddedAbsentOverlappingFilesFromTheirSnapshots(){
    _theirBackupPath="$1"
    _myBackupPath="$2"
    
    # Sources:
    _theirSnapshotFile="$(createSnapshotFileLocation "$_theirBackupPath" "$__snapshot_rawFileList_mostRecent")" 
    _mySnapshotFile="$(createSnapshotFileLocation "$_myBackupPath" "$__snapshot_rawFileList_mostRecent")"

    # Results: file name
    _saveAsAbsent="$(createSnapshotFileLocation "$_myBackupPath" "$__prefix_remote$__snapshot_fileList_locallyAbsent")"
    _saveAsAdded="$(createSnapshotFileLocation "$_myBackupPath" "$__prefix_remote$__snapshot_fileList_locallyAdded")"
    _saveAsOverlapping="$(createSnapshotFileLocation "$_myBackupPath" "$__prefix_remote$__snapshot_fileList_overlapping")"
   
    ensureDirForFileCopy "$_newSnapshotFile"

    # Find all files and dirs, locally, and list them
    # Produce a simple file list, to find additions and removals
    # Add an = separator-sign to distinguish it from other output
    _myDiffFile="$_mySnapshotFile.remote-diff"
    
    # We are in the lead. If we have files that they have not, they have been "added"
    # If they have files that we have not, they "must be deleted remotely"
    diff -u "$_theirSnapshotFile" "$_mySnapshotFile" > "$_myDiffFile"

    # We do check in the process, whether "must be deleted" is correct 
    # based on our local records in /.deleted

    # Code below does the following:
    # 1: Isolate items that start woith a + or - via sed -n

    # 2: Remove any unwatend item using sed -e
    # __sep is the separator

    # We derive three lists: absent, added and overlapping (space as prefix)
    # sed -n "/^[-].*$__sep.*/p" <"$_myDiffFile" | sed -e "s/^[+-].*$__sep//" > "$_saveAsAbsent"
    # sed -n "/^[+].*$__sep.*/p" <"$_myDiffFile" | sed -e "s/^[+-].*$__sep//" > "$_saveAsAdded"
    # sed -n "/^[\s].*$__sep.*/p" <"$_myDiffFile" | sed -e "s/^[+-].*$__sep//" > "$_saveAsOverlapping"
    
    save_cleanList_diffAbsent "$_myDiffFile" "$_saveAsAbsent"
    save_cleanList_diffAdded "$_myDiffFile" "$_saveAsAdded"
    save_cleanList_diffOverlapping "$_myDiffFile" "$_saveAsOverlapping"
    # Result: We have a clean list of all new and deleted files, based on the the SSOT
}

extract_ModifiedFilesFromTheirSnapshots(){
    _theirBackupPath="$1"
    _myBackupPath="$2"

    # We want to know what files have changed their fingerprint since last time

    # "Newer" files are marked with a + when "added" in the "new" snapshot
    # However, we want to exclude deleted files on both sides, 
    # as these were probably deliberately removed and should not be introduced again
    _theirDateTimeSnapshotFile="$(createSnapshotFileLocation "$_theirBackupPath" "$__snapshot_dateTimeFileSize")" 
    _myDateTimeSnapshotFile="$(createSnapshotFileLocation "$_myBackupPath" "$__snapshot_dateTimeFileSize")"
    _saveAsModified="$(createSnapshotFileLocation "$_myBackupPath" "$__prefix_remote$__snapshot_fileList_Modified")"
    
    _myOverlappingFilesSnapshot="$(createSnapshotFileLocation "$_myBackupPath" "$__prefix_remote$__snapshot_fileList_overlapping")"
   
    _myDiffOneFile="$_myDateTimeSnapshotFile.remote-diff1.txt"
    _myDiff_addedOrOverlapping="$_myDateTimeSnapshotFile.remote-diff-cleanlist.txt"
    _myDiff_ModifiedFiles="$_myDateTimeSnapshotFile.remote-diff-onlymodified.txt"
    # We want to know what modified and new files we have, compared to their list
    # Any local modification and addition will show up with a +
    diff -u "$_theirDateTimeSnapshotFile" "$_myDateTimeSnapshotFile" > "$_myDiffOneFile"

    # Locally absent files, based on their filelist, is extracted with another method

    # Step 2: Isolate all files marked with a +, as these have been changed or added locally 
    # Also: remove all that we do not need. The reuslt is a clean file.
    # sed -n "/^[+].*$__sep.*/p" <"$_myDiffOneFile" | sed -e "s/^[+-].*$__sep//" > "$_myDiffTwoFile"

    save_cleanList_diffAdded "$_myDiffOneFile" "$_myDiff_addedOrOverlapping"


    # Result from previous step:
    # - We have a clean file-list, containing all items that have been changed or added locally
    
    # Now we isolate those items we have both here and there, 
    # as we handle syncing local additiona elsewhere.
    diff -u "$_myDiff_addedOrOverlapping" "$_myOverlappingFilesSnapshot" > "$_myDiff_ModifiedFiles"

    # sed -n "/^[+].*$__sep.*/p" <"$_myDiffOneFile" | sed -e "s/^[+-].*$__sep//" > "$_saveAsModified"
    save_cleanList_diffOverlapping "$_myDiff_ModifiedFiles" "$_saveAsModified"

}


register_MyNewlyDeletedFiles(){
    _myBackupPath="$1"  


    # Load locally-deleted files list
    # - Remove files remote
    _myDeleted="$(createSnapshotFileLocation "$_myBackupPath" "$__snapshot_fileList_locallyAbsent")" 

    # Load remotely deleted files list
    # - Remove files locally
    cat "$_myDeleted"|
    while IFS= read -r deletedFile
    do

        _deletedFile="$_myBackupPath/$deletedFile"
        if $(fileIsInSyncReportsFolder "$_deletedFile"); then
            # We skip files located in the backup log
            return
        fi
        if $(fileIsInDeletedFolder "$_deletedFile"); then
            # We skip files located in .deleted
            return
        fi

        # Get filename
        fileName=$(basename "$_deletedFile")

        # First handle ourselves
        _myDeletedFileMarker="$(getPathTo "$_deletedFile")/.deleted/$fileName"
        ensureDirForFileCopy "$_myDeletedFileMarker"
        # Concrete file has been delete. But is there a marker?
        if ! $(fileExists "$_myDeletedFileMarker" )
        then
            # Create deleted file-marker, for referecne
            # This functions as our database of deletions, with time/date
            echo -n > "$_myDeletedFileMarker"
        fi
    done
}

sync_FilesLocallyAbsent(){
    _theirBackupPath="$1"  
    _myBackupPath="$2"

    # Load locally-deleted files list
    # - Remove files remote
    _myAbsentFiles="$(createSnapshotFileLocation "$_myBackupPath" "$__prefix_remote$__snapshot_fileList_locallyAbsent")" 

    # Load remotely deleted files list
    # - Remove files locally
    cat "$_myAbsentFiles"|
    while IFS= read -r absentFile
    do
        if $(fileIsInSyncReportsFolder "$myAddedFileName"); then
            # We skip files located in the backup log
            return
        fi
        if $(fileIsInDeletedFolder "$absentFile"); then
            # We skip files located in .deleted
            return
        fi

        # Get filename
        fileName=$(basename "$absentFile")

        # First handle ourselves
        myAbsentFile="$_myBackupPath/$absentFile"
        myDeletedFileMarker="$(get_FileDeletionMarker "$myAbsentFile")"
        
        theirFile="$_theirBackupPath/$absentFile"
        theirDeletedFile="$(get_FileDeletionMarker "$theirFile")"

        # Check 1: Is this a new file? 
        # - Do we have a local "deleted"-marker?
        if ! $(fileExists "$myDeletedFileMarker" )
        then 
            # No delete record. Remote file is a new file.
            rsync "$theirFile" "$myAbsentFile"

            # Done with this file
            return
        fi

        # Conclusions: 
        # - We have a deleted-marker (check 1)
        # - File was deleted locally.

        # Check 2: is the remote file newer than our local delete?
        if $(file_A_isOlderThan_B "$myDeletedFileMarker" "$theirFile")
        then
            # Remote is newer than delete. Restore local file
            rsync "$theirFile" "$myAbsentFile"

            # Done with this file
            return
        fi

        # Conclusions:
        # - File was not new, but deleted locally. (check 1)
        # - Remote copy of the file is older than local delete (check 2)
        # Actions:
        # - Delete remote file.
        # - Make a remore market for our deletion
        if $(fileExists "$theirFile" )
        then
            # Remove remote.
            rm "$theirFile"

            # Create deleted file, for date/time referecne
            echo -n > "$theirDeletedFile"
        fi

    done
}
sync_localAdditions(){
    _theirBackupPath="$1"  
    _myBackupPath="$2"
    # In this case, we will handle all files marked as added or modified
    # in the compare between us and our remote location. 

    # Baserd on specific checks, we will determine what to do.
   
   _myLocallyAddedAndModifiedFiles="$(createSnapshotFileLocation "$_myBackupPath" "$__prefix_remote$__snapshot_fileList_locallyAdded")"

    # Get the list of files locally added or modified, either remote or local
    cat "$_myLocallyAddedAndModifiedFiles"|
    while IFS= read -r myAddedOrModifiedFile
    do


        # Files in .axsync are mine and should not be compared
        if $(fileIsInSyncReportsFolder "$myAddedOrModifiedFile"); then
            return
        fi

        # Files in .deleted are mine and should not be compared
        if $(fileIsInDeletedFolder "$myAddedOrModifiedFile"); then
            # We skip files located in .deleted
            return
        fi

        _myAddedOrModifiedFile="$_myBackupPath/$myAddedOrModifiedFile"
        _theirAddedOrModifiedFile="$_theirBackupPath/$myAddedOrModifiedFile"

        _theirDeletedFileMarker="$(get_FileDeletionMarker "$_theirAddedOrModifiedFile")"
        _myDeletedFileMarker="$(get_FileDeletionMarker "$_myAddedOrModifiedFile")"


        # We have files locally, that either
        # - Are of a different version
        # - Are absent on the remote location

        # Sync-case 1: File is absent on remote

        # Was it deleted there?
        if $(fileExists "$_theirDeletedFileMarker" )
        then
            # It was deleted there.

            # Is the local file newer than the remote deletion?
            if $(file_A_isOlderThan_B "$_theirDeletedFileMarker" "$_myAddedOrModifiedFile")
            then
                # Yes: Local file is newer than remote delete. 
    
                # Restore remote file with local (newer) version.
                rsync "$_myAddedOrModifiedFile" "$_theirAddedOrModifiedFile"

                # Remove remote "Deleted"-record, as it is no longer valid
                rm "$_theirDeletedFileMarker"
                # Done with this file
                return
            fi  

            # Our local file was neot newer than remote.
            # Is it older than the remote delete?
            if $(file_A_isOlderThan_B "$_myAddedOrModifiedFile" "$_theirDeletedFileMarker")
            then
                # Yes. Local file is older than remote delete.
                # Delete local file so we are in sync with remote
                rm "$_myAddedOrModifiedFile"

                # Create deleted file marker, for date/time referecne
                echo -n > "$_myDeletedFileMarker"
                # Done with this file
                return
            fi       
        fi

        # Conclusions:
        # - File was not deleted remotely. 
        # - So it is either
        #   - Modified
        #   - Not present yet on remote

        # Sync-case 2: Remote file does not  exists.
        if ! $(fileExists "$_theirAddedOrModifiedFile" )
        then
            # Copy local to remote
            rsync "$_myAddedOrModifiedFile" "$_theirAddedOrModifiedFile"
            # Done.
            return
        fi
    
    done
}
sync_allModifiedFiles(){
    _theirBackupPath="$1"  
    _myBackupPath="$2"
    # In this case, we will handle all files marked as added or modified
    # in the compare between us and our remote location. 

    # Baserd on specific checks, we will determine what to do.
   
   _myLocallyAddedAndModifiedFiles="$(createSnapshotFileLocation "$_myBackupPath" "$__prefix_remote$__snapshot_fileList_Modified")"

    # Get the list of files locally added or modified, either remote or local
    cat "$_myLocallyAddedAndModifiedFiles"|
    while IFS= read -r myAddedOrModifiedFile
    do


        # Files in .axsync are mine and should not be compared
        if $(fileIsInSyncReportsFolder "$myAddedOrModifiedFile"); then
            return
        fi

        # Files in .deleted are mine and should not be compared
        if $(fileIsInDeletedFolder "$myAddedOrModifiedFile"); then
            # We skip files located in .deleted
            return
        fi

        _myAddedOrModifiedFile="$_myBackupPath/$myAddedOrModifiedFile"
        _theirAddedOrModifiedFile="$_theirBackupPath/$myAddedOrModifiedFile"

        _theirDeletedFileMarker="$(get_FileDeletionMarker "$_theirAddedOrModifiedFile")"
        _myDeletedFileMarker="$(get_FileDeletionMarker "$_myAddedOrModifiedFile")"


        # We have files locally, that
        # - Are of a different version

        # Sync-case: File was modified either here or there.

        # Is the local file older than remote?
        if $(file_A_isOlderThan_B "$_myAddedOrModifiedFile" "$_theirAddedOrModifiedFile")
        then
            # Remote is newer than delete. Restore local file with remote
            rsync "$_theirAddedOrModifiedFile" "$_myAddedOrModifiedFile"

            # Done.
            return
        fi

        # Is the remote file older than local?
        if $(file_A_isOlderThan_B "$_theirAddedOrModifiedFile" "$_myAddedOrModifiedFile")
        then
            # Remote is newer than delete. Restore local file with remote
            rsync "$_myAddedOrModifiedFile" "$_theirAddedOrModifiedFile"

            # Done.
            return
        fi
    
    done
}

handleMyAddedDeletedFiles(){
    _theirBackupPath="$1"  
    _myBackupPath="$2" 

    _handleAddedDeletedFiles "$_theirBackupPath" "$_myBackupPath" "" # local = no prefix
}

syncMyAndTheirFileDifferences(){
    _theirBackupPath="$1"  
    _myBackupPath="$2" 

    # We are the pusher of the new state.
    # When we have a file, and they do not, it will be marked as "added" and needs to be added there
    # If they have a file and we do not, it will be marked as "deleted" 
    # - and it needs to be deleted here, or deleted there


    # We use the same code to update our local repository
    _handleNewlyDeletedFiles "$_theirBackupPath" "$_myBackupPath" "$__prefix_remote"
    _handleNewlyAddedDeleteFiles "$_theirBackupPath" "$_myBackupPath" "$__prefix_remote"
}

createRemoteFileListSnapshot(){
    serverName="$1"

    ssh "$serverName" "createSnapshots.sh"

}


makeLocalSnapshots(){
    myBackupPath="$2"  

    # Step 1: Get snapshots
    make_snapshot_fileList_mostRecent "$myBackupPath" 

    # Step 2: Get differences
    extract_MyNewAndDeletedFilesFromSnapshot "$myBackupPath"

    # MAke sure we have these deleted files registered, 
    # so we can do compares on the approximate date/time of these deletes
    register_MyNewlyDeletedFiles "$myBackupPath"

    # Note that the frequency of running this script will determine 

mirrorSync(){
    theirBackupPath="$1"  
    myBackupPath="$2" 

    # Step 1: Make snapshots, so we have the current state to properly synchronize
    makeLocalSnapshots "$myBackupPath"

    # Start working with the remote machine

    # Step 2: Extract the differences between us and them
    extract_AddedAbsentOverlappingFilesFromTheirSnapshots "$theirBackupPath" "$myBackupPath"
    extract_ModifiedFilesFromTheirSnapshots "$theirBackupPath" "$myBackupPath"

    # Step 3: use the extracted data to sync the list below.
    sync_FilesLocallyAbsent "$theirBackupPath" "$myBackupPath"
    sync_localAdditions "$theirBackupPath" "$myBackupPath"
    sync_allModifiedFiles "$theirBackupPath" "$myBackupPath"

    # Step 4: Assure we can compare our local state in the next round.
    make_milestoneSnapshot_fileList "$myBackupPath"

    # We don not need a milestone snapshot with date/time/filesiuze, 
    # as we only need the most recent snapshot to compate oruself with remote.

    # Step 5: Make new local snapshots, so our other friends can see the most recent state now.
    makeLocalSnapshots "$myBackupPath"

}

# make_snapshot_DateTimeSize "/home/peterkaptein/Documents/git/bash-scripts/backup/deltas_copy"
# make_milestoneSnapshot_fileList "/home/peterkaptein/Documents/git/bash-scripts/backup/deltas_copy"
# make_snapshot_fileList_mostRecent "/home/peterkaptein/Documents/git/bash-scripts/backup/deltas_copy"

# extract_MyNewAndDeletedFilesFromSnapshot "/home/peterkaptein/Documents/git/bash-scripts/backup/deltas"

