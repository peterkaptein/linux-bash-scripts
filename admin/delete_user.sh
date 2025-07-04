# So we can call this script from anywhere without messing up the includes
myDir="$(dirname $(readlink -f $BASH_SOURCE))"

# Include
source $myDir/usermanagement.sh

# See _globals.sh for list of servers and so on.

# We will ask the user for all relevant dara
# Go!
removeUser