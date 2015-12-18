#!/usr/bin/fish

# Script to backup the minecraft server.
# Intended to be run weekly, and it won't work any more often
# than daily.  If it needs to be run more often, then edit
# the FILENAME variable so that the date component of the
# name includes at least a partial timestamp.
# 
# This script will also handle restoring the backups.

###############################################

set argc (count $argv)

set BACKUP_DIR "backups"

set WORLDS_FILE  "worlds.list"
set CONFIGS_FILE "configFiles.list"

set CONFIG_ARCHIVE        "serverConfig"
set CONSOLODATION_ARCHIVE "back_latest"

#======

if test $argc -lt 1
# Help text

	echo "Usage:
To backup: ./backup.fish -b
To restore: ./backup.fish -r <date stamp>

When backing up: the file '$WORLDS_FILE' will be read to tell which folders
contain worlds that need to be backed up.

'$CONFIGS_FILE' will be read to tell which configuration files need to be \
backed up."
	exit
end

if test $argv[1] = "-b"
# Backup
	
	set FILE_PREFIX "bak_"(date +%Y%m%d)"_"
	
	#--
	
	if test -d $BACKUP_DIR
	else
		mkdir $BACKUP_DIR
	end
	
	if test -f $WORLDS_FILE
	else
		echo "The file '$WORLDS_FILE' could not be found.  Please write to it the list of all the worlds that need to be backed up."
		exit
	end
	
	if test -f $CONFIGS_FILE
	else
		echo "The file '$CONFIGS_FILE' could not be found.  Please write to it the list of all the configuration files that need to be backed up."
		exit
	end
	
	#--
	
	echo "Taring Maps"
	echo "Prefix: $FILE_PREFIX"
	
	echo $CONFIG_ARCHIVE
	tar cf $BACKUP_DIR/$FILE_PREFIX$CONFIG_ARCHIVE.tar \
			(cat $CONFIGS_FILE)
	
	for WORLD in (cat $WORLDS_FILE)
		echo $WORLD
		tar cf $BACKUP_DIR/$FILE_PREFIX$WORLD.tar $WORLD/
	end
	
	echo "Compressing..."
	nice -19 lzma -9v $BACKUP_DIR/$FILE_PREFIX*.tar
	
	echo "Consolodating..."
	tar cvf $BACKUP_DIR/$CONSOLODATION_ARCHIVE.tar \
			$BACKUP_DIR/$FILE_PREFIX*.tar.lzma
	
	echo "Done."
	
else if test $argv[1] = "-r"
# Restore
	
	if test $argc -lt 2
		echo "Date stamp required to restore a backup."
		exit
	end
	
	set FILE_PREFIX "bak_"$argv[2]"_"
	
	rm -rf (cat $CONFIGS_FILE)
	
	for ARCHIVE in (ls $BACKUP_DIR/$FILE_PREFIX*.tar.lzma)
		set ARCHIVE_NAME (echo $ARCHIVE | \
				sed "s/$BACKUP_DIR\/$FILE_PREFIX//" | \
				sed "s/\.tar\.lzma//")
		echo "Restoring $ARCHIVE_NAME..."
		
		rm -rf $ARCHIVE_NAME/
		tar xaf $ARCHIVE
	end
	
	echo "Done."
	
end
