myDir="$(dirname $(readlink -f $BASH_SOURCE))"
# INCLUDES
source $myDir/_globals.sh

fileExists(){
    file="$1"
    if [ -f "$file" ]
    then     
        echo true
        return
    fi
    echo false
}

generateSshCertificate(){
    userName="$1"
    mkdir -p ./users/$userName

    if $(fileExists "./users/$userName/$userName-ssh_key")
    then
        echo "Certificate already exists for $userName. Keeping existing files."
    else
    echo "Generating new SSH key.
    
Accept defaults: enter, enter.

"
        ssh-keygen -t rsa -b 4096 -f ./users/$userName/$userName-ssh_key
    fi

}
replaceSshCertificate(){
    userName="$1"

    mkdir -p ./users/$userName

    if fileExists "./users/$userName/$userName-ssh_key"
    then
        echo "Renaming old key to 'old_$userName-ssh_key'."
        mv "./users/$userName/$userName-ssh_key" "./users/$userName/old_$userName-ssh_key"
        mv "./users/$userName/$userName-ssh_key.pub" "./users/$userName/old_$userName-ssh_key.pub"
    fi

    # Generate nww key
    echo "Generating new SSH key.
    
Accept defaults: enter, enter.

"
    echo ssh-keygen -t rsa -b 4096 -f ./users/$userName/$userName-ssh_key

}

zipCertificates(){
    userName="$1"

    # Generate a random password
    password=$(head -c 14 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')

    echo "Creating ZIP-file"

    zip -r --encrypt "./users/$userName-certificates.zip" "./users/$userName" -P "$password"

    echo "Hi $userName,
    
Password for your zip-file is: $password" > "./users/$userName-certificates-zip-password.txt"

echo "
==========
IMPORTANT!
==========    
Make sure the user receives the zip with updated ssh-key certificate files, 
so they can continue to login properly.

- All passwords, including those of the user on the server, 
  are auto-generated from a random string value.
  These passwords are included in the zip-file.

The zip file is stored in /users/ under their username.
A file with the password (generated) is also included there.
"
}

copyCertificateToServer()
{
    remoteComputer="$1"
    newUserName="$2"
    newPassword="$3"


    echo "Create the public ssh-key on the server, in '.ssh/authorized_keys'
    
==========
IMPORTANT!
==========    
Make sure the user receives the ssh-key certificate files, 
so they can continue to login properly.

They are stored in /users/ under their username.
    "

    # Copy the file to the server, using cat, ssh and sshpass
    cat ./users/$newUserName/$newUserName-ssh_key.pub | sshpass -p "$newPassword" ssh -o StrictHostKeyChecking=no $newUserName@$remoteComputer "mkdir -p ~/.ssh && cat > ~/.ssh/authorized_keys"

    # sshpass -p $newPassword ssh-copy-id -i ./users/$newUserName-ssh_key "$newUserName@$remoteComputer" 
    echo "Done"

}
replaceCertificateOnServer()
{
    remoteComputer="$1"
    userName="$2"
   
    echo "Replace the public ssh-key on the server, in '.ssh/authorized_keys'"

    # series of commands to create or replace key-file
    cat ./users/$userName/$userName-ssh_key.pub | ssh -o StrictHostKeyChecking=no $userName@$remoteComputer -i ./users/old_$userName-ssh_key "mkdir -p ~/.ssh && cat > ~/.ssh/authorized_keys"

    # sshpass -p $newPassword ssh-copy-id -i ./users/$newUserName-ssh_key "$newUserName@$remoteComputer" 
    echo "Done"

}

createUserAccount(){
    remoteComputer="$1"
    myPassword="$2" # Requested via a prompt
    newUserName="$3"
    newPassword="$4"


# Step 1: Add (if not present)  user and (re)set password
# =======================================================

# We use some Bash-tricks to automatically login as sudo

ssh "$__myUsername@$remoteComputer" "echo '$myPassword' | sudo -Sk adduser $newUserName
echo '$myPassword
'$newUserName:$newPassword | sudo -Sk chpasswd"

# Newline in the item above emulates an enter, needed to insert the sudo-password



# Step 2: Create the folders, if not present and (re)set access rights
# ====================================================================

ssh "$__myUsername@$remoteComputer" "mkdir -p $__usersRootDir/$newUserName
echo '$myPassword' | sudo -S chown $newUserName: $__usersRootDir/$newUserName
echo '$myPassword' | sudo -S chmod 700 $__usersRootDir/$newUserName" 

# Uset is given exclusive rights on their folder.

# Done
}

removeUserAccount(){
    remoteComputer="$1"
    myPassword="$2" # Requested via a prompt
    userName="$3"

ssh "$__myUsername@$remoteComputer" "echo '$myPassword' | sudo -Sk deluser --remove-home $userName"

}

changePassword(){
    remoteComputer="$1"
    myPassword="$2" # Requested via a prompt
    newUserName="$3"
    newPassword="$4"

ssh "$__myUsername@$remoteComputer" "echo '$myPassword
'$newUserName:$newPassword | sudo -Sk chpasswd"

}

createSharedFolder(){
remoteComputer="$1"
folderName="$2"
# TODO: create shared folder on the server, based on on group that we create.

}

createGroup(){
remoteComputer="$1"
groupName="$2"
}
addUserToGroup()
{
remoteComputer="$1"
groupName="$2"
userName="$3"

}

createUser(){

#     read -p "Enter your sudo-password: " myPassword
#     # Serverlist

#     echo "Add new user to all servers
# ======================================"
    read -p "Enter their username: " newUserName
    
    newPassword=$(head -c 14 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')

    echo "Create SSH certificate"

    generateSshCertificate "$newUserName"
    
    for remoteComputer in "${__servers[@]}"
    do
        # Create account if it not exists
        createUserAccount "$remoteComputer" "$myPassword" "$newUserName" "$newPassword"

        # Copy the key file to the server
        copyCertificateToServer "$remoteComputer" "$newUserName" "$newPassword" 
        # Add username and password.
        echo "
===========================================    
Creating new user: $newUserName
With password    : $newPassword
On               : $remoteComputer

CONNECT:
========
To connect via SSH

   ssh -o StrictHostKeyChecking=no $newUserName@$remoteComputer -i /your/ssh/key/location/$newUserName-ssh_key

To connect with sshfs:

SSHFS BASICS:
=============
sshfs <options> <server>:<remote path> <local mountpoint> <other options>

   sshfs $newUserName@$remoteComputer:$__usersRootDir/$newUserName /your/local/mountpoint -o IdentityFile=/your/ssh/key/location/$newUserName-ssh_key

To add caching and improve speed of re-loading files, add the following list of options:

   -o reconnect,cache=yes,kernel_cache,Compression=yes,allow_other,cache_timeout=60

'cache_timeout' is in seconds. One hour is 3600 seconds. 100000 seconds is roughly a day.
BEWARE: Longer cahching-times improve loading times, but might also lead to loading old versions

Mount on startup:
==================

Place this line in file: /etc/fstab

    $newUserName@$remoteComputer:$__usersRootDir/$newUserName /your/local/mountpoint sshfs -o IdentityFile=/path/to/your/key

" > "./users/$newUserName/$newUserName-$remoteComputer-accountinfo.txt"
           
    done

    zipCertificates "$newUserName"
}

removeUser(){

    read -p "Enter your sudo-password: " myPassword
    # Serverlist

    echo "Add new user to all servers
======================================"
    read -p "Enter their username: " userName

    
    for remoteComputer in "${__servers[@]}"
    do
        # Create account if it not exists
        removeUserAccount "$remoteComputer" "$myPassword" "$userName"            
    done

}

resetUserCredentials(){

    read -p "Enter your sudo-password: " myPassword
    # Serverlist

    echo "Add new user to all servers
======================================"
    read -p "Enter their username     : " userName

    newPassword=$(head -c 14 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')

    replaceSshCertificate "$userName"
    
    for remoteComputer in "${__servers[@]}"
    do
        changePassword "$remoteComputer" "$userName" "$newPassword"
        # Create account if it not exists
        replaceCertificateOnServer "$remoteComputer" "$userName" 

echo "
===========================================    
Changed credentials for : $userName
With password           : $newPassword
On                      : $remoteComputer

Please also update your ssh-key certificate files on your computer(s).
these are already updated on the server.

They are included in this ZIP-file.
" > "./users/$newUserName/$newUserName-$remoteComputer-accountinfo.txt"
    done

    zipCertificates "$userName"
}


createUser 
