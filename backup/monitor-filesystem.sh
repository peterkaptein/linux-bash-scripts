#!/bin/bash

monitorFileSystem(){
# Directory to monitor
    MONITORED_DIR="$1"

    # Start monitoring
    echo "Monitoring directory: $MONITORED_DIR"

        # -m enables continuous monitoring
        # -r ensures the monitoring is recursive
        # -e specifies events such as create, modify, delete, and move
        # –format option customizes the format of the output
        # –timefmt formats the timestamp
        # while read loop processes each detected event

    inotifywait -m -r \
        -e create -e modify -e delete -e move \
        --format '%T %w %f %e' \
        --timefmt '%Y-%m-%d %H:%M:%S' \
        "$MONITORED_DIR" | while read DATE TIME DIR FILE EVENT
        do
            echo "[$DATE $TIME] Event detected: $EVENT on $DIR$FILE"
            # Check remote and synchronize with rsync
        done
}

# We can sync servers as things happen.
# Sync will trigger same event remote, but it will find same state as it is changed to.

# It would be nice if we could run this as a batch-process as well. 
# For instance: save a timestamp-file with the changes, to  be picked up by the sync-process,
# Or a batch-file that is renamed when batch-sync starts, so new chsnges can be picked up easily.

# in principle, if no nwe file is created, no changes took place.
# The backup-mechanism can pickup the list and time-stamp it in the archive


curl --url 'smtps://smtp.gmail.com:465' --ssl-reqd \
  --mail-from 'peterkaptein@gmail.com' \
  --mail-rcpt 'peterkapteingmail.com' \
  --user 'peterkaptein@gmail.com:skivetSi234!' \
  -T <(echo -e 'From: peterkaptein@gmail.com\nTo: peterkaptein@gmail.com\nSubject: File watcher restarted\n\nHello')

# FIle state compare, using find and stat
  # https://labex.io/tutorials/linux-how-to-monitor-and-manage-file-changes-in-a-linux-environment-409923

snapshotChanges(){

    #!/bin/bash

## Take an initial snapshot of the /etc directory
find /etc -type f -exec stat -c '%n %Y' {} \; > /tmp/etc_snapshot.txt
while true; do
  ## Compare the current state with the snapshot
  find /etc -type f -exec stat -c '%n %Y' {} \; | diff -u /tmp/etc_snapshot.txt -
  sleep 60 ## Wait for 60 seconds before checking again
done
}

find "$startDir" -printf "%b %c+\t=%p" > "$outputFile"

# Produce a simple file list, to find additions and removals
# Add an = separator-sign to distinguish it from other output
find . -printf "=%p\n" > my-server-filelist.txt
diff -u ./my-server-filelist.txt ./my-ssot-filelist.txt > my-diff.txt
sed -n "/^[-].*=.*/p" <my-diff.txt | sed -e "s/^[+-].*=//" > my-ssot-deletions.txt
# We have a clean list of all deleted files, based on the the SSOT

# Find all modified files, using filesize and change date
# If a file has been changed, it will be marked in the diff 
# as a "removal" and "addition"
find . -printf "%b %c+\t%p\n" > my-server-snapshot.txt
diff -u ./my-server-snapshot.txt ./my-ssot-snapshot.txt > my-diff.txt

# Updates concern both removed and changed files
# Isolate all lines with a + and = sign, and save
sed -n "/^[+].*=.*/p" <my-diff.txt > my-updates.txt

# Remove all irrelevant data for rsync
sed -e "s/^[+-].*=//" <my-updates.txt > my-updated-filesfolders.txt

# Done

# First we delete all files in our backup, 
# that were also absent from the client
cat "my-ssot-deletions.txt"|
    while IFS= read -r fileFolder # Used as input
    do
        # Was this a deletion?
        # Check if file exists on our serer
        if [ -f "$sourceDir/$fileFolder" ] # sourceDir is the backup-location on this server
        then
            echo "- remove file     : $fullPath"
            rm "$fullPath" # remove all content 
        fi
    done

# Then we do a push/pull-backup
cat "my-updated-filesfolders.txt"|
    while IFS= read -r fileFolder  # Used as input
    do
        # Do this bi-directional, as we do not assume to know 
        # who holds the most recent file

        # Push to destinaiton if source-file is newer
        rsync -aruP "$sourceDir/$fileFolder" "$destinationDir/$fileFolder"

        # Pull from destination if destination-file is newer
        rsync -aruP "$destinationDir/$fileFolder" "$sourceDir/$fileFolder"

        # Done
    done


# Update the data-sate fingerprint files

# Precondition: the client has updated one 
# of the servers with its data-state

# Pull from destination if destination-file is newer
rsync -aruP "$destinationDir/.client-datastate" "$sourceDir/.client-datastate"

# If ours is newer, it will not be updated.

# Push to destinaiton if source-file is newer
rsync -aruP "$sourceDir/.client-datastate" "$destinationDir/.client-datastate"


    # Precondition:

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            # - We created a new delta of local changes vesios the previous SSOT-file

    # Assumptions:
    # 1: The most recent SSOT-file from the server reflects present and proper data-state.
    # 2: Our local SSOT-file reflects the local and shared state AFTER syncing with a server

    # - We only need to know local additions and deletions, to prevent them from deletion
    # - Mutations of files are OK, since these files are expected to exist.

    # Steps before synchronizing:
    # 1: Get the current local data state-list of files
    # 2: Compare them with the previous SSOT we got or produced after the previous sync
    # 3: Store the delta in a file.

    # Steps to do next:   
    # "Merge" the local delta with the new SSOT

    cat "delete-list-from-the-new-server-SSOT.txt"|
        while IFS= read -r fileFolder  # Used as input
        do
            # Check if this file/folder is in our delta
            if grep -Fxq "$fileFolder" my-delta-since-last-server-update.txt
            then
                # This is a merge. 
                echo "File has been added or restored by this user and should not be deleted"
            else
                # We dit not add or restore this file since our last sync with the server. 
                # It was deleted somewhere else and should also be deleted here.
                rm "$fileFolder"
            fi
        done

        # Push to destinaiton if source-file is newer
        rsync -aruP "$sourceDir/$fileFolder" "$destinationDir/$fileFolder"

        # Pull from destination if destination-file is newer
        rsync -aruP "$destinationDir/$fileFolder" "$sourceDir/$fileFolder"

        # Done
    done