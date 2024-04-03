#!/bin/bash

#############################################
Mirror local shares to another network drive
#############################################

function func_timestamp(){
	timestamp=$(date +"%d.%m.%y - %T")
}

function func_line(){
	echo -e "\n====================== \n"
}

function func_small_line(){
	echo -e "\n=== \n"
}

function func_set_colors(){
    ######################
    #Black        0;30     Dark Gray     1;30
    #Red          0;31     Light Red     1;31
    #Green        0;32     Light Green   1;32
    #Brown/Orange 0;33     Yellow        1;33
    #Blue         0;34     Light Blue    1;34
    #Purple       0;35     Light Purple  1;35
    #Cyan         0;36     Light Cyan    1;36
    #Light Gray   0;37     White         1;37
    ######################
    Color_Green='\033[1;32m'             # Success Messages
    Color_Red='\033[0;31m'               # Error Messages
    Color_Orange='\033[0;33m'            # Titles or important Information
    Color_NC='\033[0m'                   # No Color
    CM='✓'                               # Checkmark
    CROSS='✗'                            # Cross
}

function func_jobtitle(){
    func_timestamp
	echo -e "${Color_Orange}$timestamp :: ${CM} [Start] :: Starting Job $jobname${Color_NC}"
}

function func_mount(){
    func_timestamp
    echo -e "$timestamp :: [Mount] :: Mounting $mountpoint ..."
    mkdir -p $mountpoint
    if sudo mount.cifs //$ip_adresse/$share_name $mountpoint -o $mount_options ; then
        echo -e "${Color_Green}$timestamp :: ${CM} [Mount] :: Mount successfully${Color_NC}"
    else
        echo -e "${Color_Red}$timestamp :: ${CROSS} [Mount] :: Mount error with //$ip_adresse/$share_name on $mountpoint${Color_NC}"
        exit
    fi
}

function func_unmount {
    func_timestamp
	echo -e "$timestamp :: ${CM} [Mount] :: Unmounting $mountpoint ..."
    umount $mountpoint 2> /dev/null
    rmdir $mountpoint 2> /dev/null
    echo -e "$timestamp :: ${CM} [Mount] :: Unmounting done or not needed"
}

function func_sync(){
    func_timestamp
    if [ -d $source_dir ]; then
		if [ -d $mountpoint ]; then
            echo -e "$timestamp :: ${CM} [Sync] :: Syncing $source_dir to $mountpoint ..."
            if [ "$dryrun" -eq "1" ]
            then
                rsync -av --delete-before --dry-run --progress $source_dir $mountpoint
                func_rsync_error_check
                func_small_line
            else
                rsync -av --delete-before --progress $source_dir $mountpoint
                func_rsync_error_check
                func_small_line
            fi
        else
			echo "${Color_Red}$timestamp :: ${CROSS} [Mount] :: ERROR: $mountpoint not found${Color_NC}"
            exit
        fi
    else
        echo "${Color_Red}$timestamp :: ${CROSS} [Mount] :: ERROR: $source_dir not found${Color_NC}"
        exit
    fi
}

function func_sync_related_to_marker_files(){
    func_timestamp

    # Declare and delete $temp_file (just to be sure)
	temp_file="/tmp/$search_file"
	if [ -f $temp_file ]; then
		rm -f $temp_file
	fi

    # Build the $temp_file, containing all Dir to backup
    find $source_dir -type f -name $search_file | sed -r 's|/[^/]+$||' |sort |uniq | grep -o '[^/]*$' > $temp_file

    # Delete existing Dir/Files in the target storage, which are not longer present in $temp_file
    cd $mountpoint
    for i in *; do
        if ! grep -qxFe "$i" $temp_file; then
            echo -e "$timestamp :: ${CM} [Sync] :: Deleting: $mountpoint/$i ..."
            rm -r "$mountpoint/$i"
        fi
    done

    # Do the Sync, related to the $temp_file
    while read line
    do
        echo -e "${Color_Orange}$timestamp :: ${CM} [Sync] :: $line ...${Color_NC}"
        rsync -av --delete-before --progress "$source_dir/$line" $mountpoint
        func_rsync_error_check
        func_small_line
    done < $temp_file

    unset line

}

function func_rsync_error_check(){ 
        if [ "$?" -eq "0" ]
        then
            func_timestamp
            if [ -z "$line" ]
            then
                echo -e "${Color_Green}$timestamp :: ${CM} [Sync] :: Success: $source_dir${Color_NC}"
            else
                echo -e "${Color_Green}$timestamp :: ${CM} [Sync] :: Success: $source_dir$line${Color_NC}"
            fi
        else
            func_timestamp
            if [ -z "$line" ]
            then
                echo -e "${Color_Red}$timestamp :: ${CROSS} [Sync] :: ERROR: $source_dir${Color_NC}"
            else
                echo -e "${Color_Red}$timestamp :: ${CROSS} [Sync] :: ERROR: $source_dir$line${Color_NC}"
            fi
            exit
        fi
}

clear
func_set_colors

echo -e "${Color_Green}${CM}${Color_NC}"
source <(curl -s https://raw.githubusercontent.com/BeckenrandschwimmerTim/openmediavault/main/sync_files_to_network_drive_jobs_EXAMPLE)
