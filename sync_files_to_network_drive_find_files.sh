#!/bin/bash

# Search for all files with a name:
# Example: find $source_dir -type f -name 'backup_this_whole_directory' |sort |uniq
# Example: find /sharedfolders/Medien/Serien -type f -name 'backup_this_whole_directory' |sort |uniq

# Search for all files with a name and rename it:
# Example: find $source_dir -type f -name 'Backup_to_HDD030.txt' -execdir mv {} Backup_to_HDDXXX \;
