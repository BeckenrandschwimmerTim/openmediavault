#!/bin/bash

##################################################################
App="Mirror local shares to another network drive (with checksum)"
##################################################################

# Search for main.func primarily localy else source it from the web
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [ -f $DIR/../misc/main.func ]; then
  echo -e "Use local source"
  source "$DIR/../misc/main.func"
else
  echo -e "Use web source"
  source <(curl -s https://raw.githubusercontent.com/BeckenrandschwimmerTim/proxmox/main/misc/main.func)
fi

function func_jobtitle(){
    func_timestamp
	echo -e "${Color_Orange}$timestamp :: ${CM} [Start] :: Starting Job $jobname${Color_NC}"
}

function func_mount(){
    func_timestamp
    echo -e "$timestamp :: ${CM} [Mount] :: Mounting $mountpoint ..."
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
    umount -l $mountpoint 2> /dev/null
    rmdir $mountpoint 2> /dev/null
    echo -e "$timestamp :: ${CM} [Mount] :: Unmounting done or not needed"
}

function func_sync(){
    func_timestamp
    if [ -d $source_dir ]; then
		if [ -d $mountpoint ]; then
            echo -e "$timestamp :: ${CM} [Sync ] :: Syncing $source_dir to $mountpoint ..."
            if [ "$dryrun" -eq "1" ]
            then
                rsync -av --delete-before --checksum --dry-run --progress $source_dir $mountpoint
                func_rsync_error_check
                func_small_line
            else
                rsync -av --delete-before --checksum --progress $source_dir $mountpoint
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
            echo -e "$timestamp :: ${CM} [Sync ] :: Deleting: $mountpoint/$i ..."
            rm -r "$mountpoint/$i"
        fi
    done

    # Do the Sync, related to the $temp_file
    while read line
    do
        echo -e "${Color_Orange}$timestamp :: ${CM} [Sync ] :: $line ...${Color_NC}"
        rsync -av --delete-before --checksum --progress "$source_dir/$line" $mountpoint
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
                echo -e "${Color_Green}$timestamp :: ${CM} [Sync ] :: Success: $source_dir${Color_NC}"
            else
                echo -e "${Color_Green}$timestamp :: ${CM} [Sync ] :: Success: $source_dir$line${Color_NC}"
            fi
        else
            func_timestamp
            if [ -z "$line" ]
            then
                echo -e "${Color_Red}$timestamp :: ${CROSS} [Sync ] :: ERROR: $source_dir${Color_NC}"
            else
                echo -e "${Color_Red}$timestamp :: ${CROSS} [Sync ] :: ERROR: $source_dir$line${Color_NC}"
            fi
            exit
        fi
}

header_info
func_app_title

# Start the jobs file
func_timestamp
if [ -f $DIR/sync_files_to_network_drive.jobs ]; then
	echo -e "${Color_Green}$timestamp :: ${CM} [File ] :: Success: Found sync_files_to_network_drive.jobs${Color_NC}"
	source $DIR/sync_files_to_network_drive.jobs
else
	echo -e "${Color_Red}$timestamp :: ${CROSS} [File ] :: ERROR: $DIR/sync_files_to_network_drive.jobs not found${Color_NC}"
fi
