# RSYNC
# https://download.samba.org/pub/rsync/rsync.1
# COPY 
# https://man7.org/linux/man-pages/man1/cp.1.html
# FIND
# https://man7.org/linux/man-pages/man1/find.1.html
# https://snapshooter.com/learn/linux/find



# Using symbolic links for this purpose 
# - is not new or revolutionary.

# - Saves an immense amount of space, while creating a "Time machine" for all your data in the backup, 
# Using symbolic links assures that each time-based backup acts like it is the real thing.
# Assure to:
# 1: make a full backup from time to time.
# 2: NOT delete any of the backups in the "timemachine" folder.
# Here is why: If you delete a folder that contains the concrete file, 
# then the symbolic link will be broken, and your backup of that file is broken as well


# RUNNING THE TIME MACHINE
# ============================================================
# We run: makeTimeMachineBackup at the end of this file, 
# - using sourceDirDirNames as input

gl_timeMachineInfo="
ABOUT:
======
makeTimeMachineBackup creates a Time Machine like backup of all files in the given directories.

=======
PART 1: THE BASICS
==================

Time slots:
===========
You use time slots to store the data. 
A time slot can look like this:
- timemachine/week/2025/week_03/        - timeslot_week
- timemachine/day/2025/07-july/july-21/ - timeslot_day
- timemachine/year/2025/                - timeslot_year
- timemachine/month/2025/07-july/       - timeslot_month

Each time slot is updated, until that time slot expires.
For instance, if you use timeslot_day:
- On july 12, it will continue to update that timeslot, 
  until it is no longer july 12.

Multiple timeslots possible for backup:
=======================================
Based on the timeslots you define, backups can be 
dayly, weekly, hourly and so on.
Since the backups are based on symbolic links 
to concrete files in time slots, you can be generous 
in the number of backups you make.

Example code on how to implement this, can be found ...

Each file is only stored once, unless modified:
===============================================
Regardless how many backups you create, the actual files 
are only stored once, unless you mpodify them.
In that case, a new copy is stored in the first 
time-slot you use for the new backup.

Symbolic links:
===============
Symbolic links are widely used and a time-tested solution, 
within controlled enuironments, provided by the file-system.

Instead of a concrete file, they store a link-reference 
to that concrete file. This means that you can make a lot 
of 'copies' of that file, via reference, without
clogging up your harddrive.

Vulnerable:
===========
These symbolic linka are vulnerable and they will break when you move- 
or remove the real file these links point to.

Currently (2025) there are no proper alternatives available.

No fancy tricks or software lock-ins
====================================
This Time Machine backup uses Linux native rsync and copy 
to make your bakcups. 

Files are stored as files in regular folders and 
the symbolic links to files are Linux standard.

Open source:
============
You can see all the code this command uses to create the backups.


=======
PART 2: ABOUT YOUR BACKUPS:
===========================

Time slots determine how many versions:
=======================================
Even if it can be used this way, this time machine backup 
is not a system for version control.

If you run the monthly timeslot first, only one version 
(the most recent one) of tha file is preserved in that time slot,
as the system works from that first slot to do all other backups.

It is recommended to start from the smallest interval.

Days are the smallest time frame:
=================================
It is not possible to store versions in smaller time frames than a day.

    However:
    ========
    Time Machine keeps a roulating backup of new files 
    in a 24 hour time box.

    This 24 hour time box has timeslots of 1 hour each.
    Each new copy will expire in 24 hours, and will be erased
    once those 24 hours are over. 

Time and date are preserved on the files:
=========================================
The time and date of creation/modification are preserved.

Concrete Backups:
=================
If you want to make a concrete backup of one of your time machine slots, 
you can run the 'concreteBakcup' command we provide.
This assures you are actually and that you indeed are making 
a concrete backup and not a baclup of only the links.

concreteBackup uses the cp conmand, with the -a -u and -P  parameters.
If the backup is interrupted, it wiil proceed where you were once started again.

You can use concreteBackup also to update previous concrete backups. 
As only newer file versions are copied, this can be quite fast.

=======
PART 3: WARNINGS 
================

WARRENTIES AND HELP
===================
WE do not offer any warrenties or help in case your 
Time Machine backup gets corrupted. 

DO NOT MOVE THE TIME MACHINE FOLDERS ONCE THEY ARE MADE:
=======================================================
TimeMachine makes use of symbolic links to concrete files.
This preserves a lot of space.

Symbolic links are also vulnerable, because they are based 
on absolute path references, instead of file-ID's 

So if the concrete file is stored at:

    '/backup/timemachine/mybackup/semefolder/'

That link --and that part of your timemachine backup -- 
will be broken if you move that concrete file somewhere else

To assure that you can recover the link-structure, 
we store a file stating where TimeMachine started,
so that you have some chances to repair the links. 

=======
PART 4: RECOMMENDATIONS
=======================

START FROM THE SMALLEST INTERVAL
================================
This Time Machine backup is very simple in its purpose and setup:
- It needs to make regular backups
- Using user-defined timeslots to store files and references in
.
It will use the first interval to stora all files.
All other intervals use references to the files in that first interval.

myTimeSlots=('\$timeslot_day' '\$timeslot_week' '\$timeslot_month' "\$timeslot_year") 

Starts with a daily interval and ill keep daily bakcups.

myTimeSlots=( "\$timeslot_year" '\$timeslot_day' '\$timeslot_week' '\$timeslot_month' ) 

Starts with a yealy interval, and will keep only one version of your file in each year.

MAKE REGULAR NORMAL BACKUPS:
============================
A Time MAchine backup is nice, but vulnerable.
Assure you make regular backups from time to time, 
and make sure to properly test those backups.

To he[p you in this, we offer a regular bakcup option 
from your time machine backups,
using the Linux native rsync command.

MAKE YOUR TIME MACHINE FOLDERS READ-ONLY:
=========================================

How: 
1: Assign the folder to a 'backup-maker'-useraccount.
2: Execute TimeMachine only from that account
3: Deny any other user anything else but read-rights

Why:
1: It reduces the chances of human error. 
2: It protects your data from tampering by
   - Yourself
   - 3rd parties (including friends and family) 
   - Ransomware

To find out how, run:

makeTimeMachineBackup 'help-readonly'

ASSURE YOU HAVE ENOUGH STORAGE SPACE:
=====================================
1 TereByte is a good starting point.

Even though the time machine becakups are as space-efficient as we can make it
they will still use storage-space.

=======
PART 5: WHAT WE HAVE TESTED:
============================

Mount / unmount / remount:
==========================

- Removable drives
- Network drives

You can safely 
- mount / unmont / remount remeovable and network drives.
- rename and move your mounting points.
- mount your drive to other mounting posts.
- use your Time Machine backup on another computer. 

Rename, move and remove files and folders:
====================================

You can NOT safely:
- Rename, move and remove files and folders in and from 
  your Time Machine backup without risking 
  to corrupt your Time Machine backup

If you run out of space, best is to start a new 
Time Machine session on a new and clean drie,

"

# =============================================================
# Variables from system
weekNumber=$(date +%U) 
monthName=$(date +%m) 
year=$(date +%Y)
day=$(date '+%m%d')
hour=$(date '+%Y-%m%d-%H%M%S')


# SECONDARY DEFINITIONS
# ==============================================================
# You can leave this as is, to run the Time Machine.


# Definition of time slots. One option for now. 
# Arrays make it possible to do dayly, weekly and monthly. Not implemented yet
# We use the directory this script is in as a base,
# so you can create multiple time machines by copying this file into other directories 


timeslot_day="01-dayly/$year/$monthName/$monthName-$day" 
timeslot_week="02-weekly/$year/week_$weekNumber"
timeslot_month="03-monthly/$year/$monthName"
timeslot_year="04-yearly/$year"

# Current Snapshot contains the most recent backup state. 
# This simplifies the code, as we do not need to keep track 
# of what is the most recent backup.

# Current Snapshot assures that we can make multiple backups
# Of the same data (daily, weekly, etc), using symbolic links only

# How it works:
# Each new timeslot first gets a copy of all the links in the current snapshot
# Then we update the timeslot, and copy the symbolic links from the new state 
# into Current Snapshot

# Each symbolic link links directly to the actual file. No link-chaining.

# CODE
# ==============================================================
ensureDirForFileCopy() {
    # Parameter  based, like Bash-file. $1 is first item in input
    directoryAndFilename="$1" # based on input

    # Ensures a directory is there when needed
    # 1: Get path
    path=$(dirname "$directoryAndFilename") # Standard Bash function to get directory name fron string

    # 2: Create dir if not there yet
    mkdir -p "$path" # Recursive, so if parents are not there, they will be created as well
}

deleteEmptyFolders(){
    startDir="$1"

    # Find empty directories and delete them
    find "$startDir" -type d -empty -print # -delete
}

# Our time machine!
makeTimeMachineBackup(){

    timeMachineFolder="timemachine"

    timeslot="$1" 
    sourceDir="$2"
    destinationDir="$3"
    destinationFolder="$4"

    # Dir to save the snapshots in
    snapshotDir="$timeMachineFolder/$destinationFolder/"

    # Test if the remote-location can be reached / exists. 
    # If not: announce and exit

    # Here we are not interested if a location is remote or not. 
    # That is the job of ping-and-mount.sh that will run first.
    # A dir either exists, or not.

    # Start of process
    echo "
==================================================
Copy from         : $sourceDir
Copy to           : $destinationDir
In the folder     : '$snapshotDir'
To timeslot       : '$timeslot'
Using snapshot in : $myCurrentSnapshotDir
"

    # Add destination folder
    snapshot_BaseDir="$destinationDir$snapshotDir"

    myCurrentSnapshot_Dir="$snapshot_BaseDir.currentsnapshot/" # Contains the latest state
    myTimeslot_Dir="$snapshot_BaseDir$timeslot/"


    # If it does not exist, make it
    mkdir -p $destinationDir

    echo "
Starting backup
=====================
Step
1: Make snapshot into: $destinationDir
1.1: Check if snapshot dir exists
"
    if test -d "$myCurrentSnapshot_Dir" # Points to dest dir and folder
    then # We have done this before
        # 1: Copy snapshot
        echo "- Snapshot dir exists: copy snapshot to $snapshot_BaseDir" and timeslot $timeslot

        # Use last snapshot to fill the initial structure
        # This might include deleted files.

        # First time?
        # Create new dir and copy current snapshot
        if ! test -d "$destination_Dir/$timeslot"
        then
            echo "- First time, full snapshot copy"
            rsync -aruvP -lHk "$myCurrentSnapshot_Dir" "$myTimeslot_Dir"
        else
            echo "- Full snapshot copy already there, just update"
        fi

        echo "==================================================="
        # Step 2: Only copy newer files from source
        echo "
Step 2: Copy new and updated files:
===================================
from : $sourceDir 
into : $myTimeslot_Dir
"
        # rsync will overwrite symbolic links as it checks filesize as well. 
        # CP will only look at date/time
        cp -aruv "$sourceDir" "$myTimeslot_Dir"

        # TODO: use find, compate file dates, if destination is file and / or older
        #       - use rsync to assute file is copied properly

        echo "
Backup done of new and updated files."

        #2.1 Remove links to all deleted files from current backup folder
        echo "
Step 3: Do cleanup:
===================
remove deleted files from $myTimeslot_Dir
"
        
        # We do not have records, so we need to check per file
        
        timeslotDirLen=${#myTimeslot_Dir}+1

        # Get all links in backup. New files we leave intact, as a safety measure
        # We do not yet clean up empty folders
        find $myTimeslot_Dir -type l -print0 |
        while IFS= read -r -d '' fileInTimeslot
        do
            # Cut containing folder from string 
            fileName=${fileInTimeslot:timeslotDirLen}

            source_File="$sourceDir$fileName"
            # Check if it exists in source
            if [ ! -f "$ssource_File" ]; then
                echo "$source_File does not exist"
                echo "Remove link: $fileName from backup"
                rm "$fileInTimeslot"
            fi

        done   

        echo "
Done with cleanup."

        # PART 3: UPDATE SNAPSHOT
        # What it covers:
        # 1: The new snapshot can contain both links to files backed up a while ago
        #    and concrete files the used created or updated recently
        # 2: The user might have deleted files and directories
        # 3: Folders in our current snapshot might be empty due to file-deletions

        # The current snapshot in our time machine 
        # is a MIRROR of  the current state of the directories we backup.

        # So we need to take 4 steps:
        # 1: Remove all deleted files from our current snapshot
        # 2: Copy all the existing symbolic links from the snapshot we made now
        # 3: Create new symbolic links from the concrete files we added to this snapshot
        # 4: Remove all the empty folders from our snapshot

        # But first we delete the old 00 snapshot data, so we have clean start

        echo "
Step 4: Update 00 snapshot:
===========================
4.1   : Delete old snapshot in 00" # STep 1
        rm -r "$myCurrentSnapshot_Dir"

        mkdir "$myCurrentSnapshot_Dir"
        
        echo "4.2   : Create new snapshot from $myTimeslot_Dir"

        timeslotDirLen=${#myTimeslot_Dir}+1
        
        echo "4.2.a : Copy all symbolic links to 00 snapshot" # Step 2
        # Copy all links verbatim, using rsync, so that we do not create new files
        # Or create symbolic links to symbolic links

        find "$myTimeslot_Dir"  -type l -print0 |
        while IFS= read -r -d '' file
        do
            #Use %P instead of %f. This just cut off the path given in the command line. 
            # Cut containing folder from string 
            file_Name=${file:timeslotDirLen}
            echo "- copy link  : $file_Name"

            # rsync will properly copy symbolic link 
            # --mkpath will ensure paths will be created when not there
            rsync -aruP -s --mkpath "$file" "$myCurrentSnapshot_Dir$file_Name"
        done    
        
        echo "4.2.b : Copy new and updated files as new links to 00 snapshot" # Step 3

        # Copy all new files as a link to snapshot, 
        # so that our snapshot is clean from real files
        find "$myTimeslot_Dir"  -type f -print0 | # -tyoe f will not find symbolic links
        while IFS= read -r -d '' realFile
        do
            # Work relative from startposition,  
            file_Name=${realFile:timeslotDirLen} # takes substring from given postion :timeslotDirLen
            echo "- create link: $file_Name"

            realFile_Link="$myCurrentSnapshot_Dir$file_Name"
            # Individual file copy is stupid and needs you to create the containing folder
            ensureDirForFileCopy "$realFile_Link"
            # Create new symbolic link
            cp -ar -s "$realFile" "$realFile_Link" 
            # It would be nice if cp had a -mkpath flag like rsync has

        done   

        echo "4.2.c: Remove empty folders from snapshot, so next backup in new timeslot is cleaner" # Step 4
        deleteEmptyFolders "$myCurrentSnapshot_Dir"
        # We can do this for the current backup, but the risk is that folders are removed that contain data
        # Now we will have empty folders in the previous backup, and a clean stucture in the next.
        # Better some empty directory dirt than accidental folder removal.

    else # First time ever!
        # Make first snapshot

        # Step 1: Make dir
        echo "First time: 
Step 1: create dir for snapshot"
        mkdir -p "$myCurrentSnapshot_Dir" # -p is recursive. 

        # Step 2: Make first backup
        # No symbolic links!
        echo "Step 2: Copy files to $myTimeslot_Dir"
        cp -ar "$sourceDir" "$myTimeslot_Dir" # -ar = archive / keep date/time, and do copy recursive


        # Step 3: Make our first snapshot
        echo "Step 3: Create 00-snapshot"
        cp -ar -s "$myTimeslot_Dir" "$myCurrentSnapshot_Dir"
        # All symbolic links. Since we have no other data yet, this can be kept simple.

    fi

}


# Default time slots: timeslot_day, timeslot_week, timeslot_month, timeslot_year

myTimeSlots=("$timeslot_day" "$timeslot_week" "$timeslot_month" "$timeslot_year") 

# Where do we start from?
myBaseDirectory="$(pwd)" # pwd is the path that this file is in.

sourcedir="" # Paths need to be absolute, for symbolic links to be created
backupLocation=""
backupFolder=""


for timeSlot in ${myTimeSlots[@]}
do
     echo  "Timeslot: $timeSlot"
     makeTimeMachineBackup "$timeSlot" "$sourcedir" "$backupLocation" "$backupFolder"
done




# You can use openssl to encrypt and decrypt using key based symmetric ciphers. For example:

# openssl enc -in foo.bar \
#     -aes-256-cbc \
#     -pass stdin > foo.bar.enc

# This encrypts foo.bar to foo.bar.enc (you can use the -out switch to specify the output file, instead of redirecting stdout as above) using a 256 bit AES cipher in CBC mode. There are various other ciphers available (see man enc). The command will then wait for you to enter a password and use that to generate an appropriate key. You can see the key with -p or use your own in place of a password with -K (actually it is slightly more complicated than that since an initialization vector or source is needed, see man enc again). If you use a password, you can use the same password to decrypt, you do not need to look at or keep the generated key.

# To decrypt this:

# openssl enc -in foo.bar.enc \
#     -d -aes-256-cbc \
#     -pass stdin > foo.bar

# Notice the -d. See also man openssl


#cp -ar -s ./source/ $destinationDir

#/mnt/backup/peter/www/novascriber/novaeditor

# https://download.samba.org/pub/rsync/rsync.1

# BASIC BACKUP
# rsync -aruvP
# -a - Archive - keep dates of source file
# -r - recurse into directories (default)
# -u - Update only when source is newer
# -v - Verbose, show what you are doing
# -P - show --partial --progress


# MIRROR BACKUP
# A mirror backup reflects the source exactly. 
# - Files removed from source will also be removed from dest
#
# rsync -aruvP --delete
# -auvP - See basic backup for what it does
# --delete - delete extraneous files (files that do not exist on source) from dest dirs

# EXCLUDE FILES
# rsync --exclude

# Example: --exclude={'some/subdir/linuxconfig','some/other/dir','somedirname', '*.suffix'}

# CREATE TIME MACHINE LIKE BACKUP WITH SYMLINKS AND HARD LINKS
# cp --archive --recursive --symbolic-link
# OR: 
# cp -ar -s 

# -a - Archive - preserve all / preserve links as well
# -r - Recursive
# -s - Make symbolic link

# --keep-directory-symlink - follow existing symlinks to directories
# --preserve=links - included in -a

# rsync -lHk 
# -l    copy symlinks as symlinks
# -H    preserve hard links
# -k    causes the sending side to treat a symlink to a directory as though it were a real directory

# EXTRAS
# -n  - Dry run: perform a trial run with no changes made
# -q  - Run quietly, suppress non-error messages

# SSH KEY
# rsync -auvP --delete -e "ssh"
# -e "ssh" - Use SSH + key to authenticate
#
# How to generate SSH key (from local machine)
#  ssh-keygen -t ecdsa 
#  - ecdsa is identifier name of key file, 
#  - create several if you want to keep things separated (different parties)
#  - (enter enter) accept all defaults
#  - Key will contain name of local machine, and username

# Copy public key to server
#   scp ~/.ssh/id_ecdsa.pub yourname@yourserver:.ssh/authorized_keys 
#
# And done

