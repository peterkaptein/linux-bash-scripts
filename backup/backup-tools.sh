ensureDirForFileCopy() {
    # Parameter  based, like Bash-file. $1 is first item in input
    directoryAndFilename="$1" # based on input

    # Ensures a directory is there when needed
    # 1: Get path
    path=$(dirname "$directoryAndFilename") # Standard Bash function to get directory name fron string

    # 2: Create dir if not there yet
    mkdir -p "$path" # Recursive, so if parents are not there, they will be created as well
}

fullBackupFiles(){
echo ""
}

replace(){
    baseString="$1"
    searchFor="$2"
    replaceWith="$3"

    echo "${baseString/"$searchFor"/"$replaceWith"}"
}

fullBackupSymbolicLinks(){
    # A sybolic link links to the root of a mountpoint, i.e. /mnt/disk1/backup
    # When copied to disk 2, the symbolic link reference will still be to /mnt/disk1/backup
    # To make the backup self-sufficient (for instance: to copy files, or to restore files) 
    # we rewrtie the sybolic link on the destination dir, after we copied it. 
    # 
    # ABOUT:
    # This method rewrites symbolic links on the destination copy.
    # in case this link is still pointing at the old (source) location


    copyFrom_dir=$1
    copyTo_dir=$2




    find "$copyFrom_dir"  -type l -print0 | # -type f will not find symbolic links
    while IFS= read -r -d '' filename
    do
        #oldLink="$( stat -c%N "$filename" )"
        echo "REAd LINK
$filename
================"
        oldSymbolicLink="$(readlink "$filename")"
        #oldLink="${oldLink/*-\>*\'/}"
        
        # Take old link, find old dir, replace with new dir
        newlink="${oldSymbolicLink/$copyFrom_dir/$copyTo_dir}"

        newFile="${filename/$copyFrom_dir/$copyTo_dir}"

        echo "old link: '$oldLink'
new link: '$newlink'"

        ensureDirForFileCopy "$newlink"

        # Create or update symbolic link
        ln -snf "$newlink" "$newFile"

    done
}

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
# readlink -f filename 
# Symbolic links need a rewrite. readlink can read original location.
# Some regex-magic can then replace prefix to proper location

# Symbolic link change:  ln -snf foo2 bar
# -s = type: symbolic link
# -n = no defer / use/change link-file instead of real file
# -f = force: remove existing destination files
# fullBackupSymbolicLinks "/home/peterkaptein/Documents/work/timemachine/" "/home/peterkaptein/Documents/work/timemachine2/"

# filePath="a/b/c/d/e.txt"
# echo "${filePath%/*}/.irui"

# if ! $(fileExists "/home/peterkaptein/Documents/git/bash-scripts/backup/backup--tools.sh" )
# then 
#     echo "Not exists"
# else
#     echo "exits"
# fi

A="/home/peterkaptein/Documents/git/bash-scripts/backup/backup-tools.sh" 
B="/home/peterkaptein/Documents/git/bash-scripts/backup/client-config.sh"
if ! $(isOlderThan "$B" "$A"   )
then 
    echo "A Is not olderthan B"
else
    echo "is older"
fi

myFuinction(){
    echo "PEteR"
}

echo "my name is $( myFuinction )"

echo "$(replace "Recplace Peter with John - shold readn john john" "Peter" "John")"


        if [[ "/rghtr/hrtr/r/.de-leted/iuiui.kk" == *"/.deleted/"* ]]; then
            # We skip files in .deleted
            echo "Deleted"
        fi

getPathTo(){
    myPath="$1"
    echo "${myPath%/*}"
}

echo "$(getPathTo "/rr/tt/yy/mm.tct")"