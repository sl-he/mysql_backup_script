#!/bin/sh
# Shell script to backup MySQL database adapted for FreeBSD 12 and MariaDB 10
# To backup Nysql databases file to /usr/data_backup dir and later pick up by your
# script. You can skip few databases from backup too.
# Need pbzip2 for running
# Adding Telegram notify

MySQL_USER="$USERNAME"           # USERNAME
MySQL_PASS="$PASSWORD"           # PASSWORD
MySQL_HOST="localhost"           # Hostname

# Linux bin paths, change this if it can not be autodetected via which command
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
MYSQLADMIN="$(which mysqladmin)"
CHOWN="$(which chown)"
CHMOD="$(which chmod)"
PBZIP2="$(which pbzip2)"
RSYNC="$(which rsync)"
FIND="$(which find)"

# Get data in dd-mm-yyyy format
NOW="$(date +"%F")"

# Backup Dest directory, change this if you have someother location
DEST="/tmp"
BACKUP_DIR="/usr/data_backup"
# Main directory where backup will be stored
MBD="$DEST/$NOW"

# Get hostname
HOSTNAME=`uname -n`

# File to store current backup file
FILE=""

# Store list of databases
DBS=""

# Опции
mysqloptfull="--opt --skip-lock-tables"

# DO NOT BACKUP these databases
IGGY="performance_schema"

[ ! -d $MBD ] && mkdir -p $MBD || :

# Get all database list first
DBS="$($MYSQL -u $MySQL_USER -h $MySQL_HOST -p$MySQL_PASS -Bse 'show databases')"

for db in $DBS
do
    skipdb=-1
    if [ "$IGGY" != "" ];
    then
        for i in $IGGY
        do
            [ "$db" = "$i" ] && skipdb=1 || :
        done
    fi
    if [ "$skipdb" = "-1" ] ; then
        FILE="$MBD/$HOSTNAME.$db.$NOW.sql.tar.bz2"
        # do all inone job in pipe,
        # connect to mysql using mysqldump for select mysql database
        # and pipe it out to sql.tar.bz2 file in backup dir
        echo "Dumping database "$db"..."
        $MYSQLDUMP -u $MySQL_USER -h $MySQL_HOST -p$MySQL_PASS $mysqloptfull $db |  $PBZIP2 -c > $FILE
        if [ $? -ne 1 ]
        then
         $PATH_TO_TELEGRAM_SCRIPT/telegram.sh $YOUR_TELEGRAM_ID DB_BACKUP "Backup database $db is completed successfully on $HOSTNAME."
        else
         $PATH_TO_TELEGRAM_SCRIPT/telegram.sh $YOUR_TELEGRAM_ID DB_BACKUP "Backup database $db is NOT completed successfully on $HOSTNAME."
        fi
        echo "End of dumping database "$db"..."
    fi
done

# Only root can access to backups!!!
$CHOWN -R root:wheel $MBD
$CHMOD -R 0600 $MBD
$CHOWN -R root:wheel $BACKUP_DIR
$CHMOD -R 0600 $BACKUP_DIR

# Create copy on main backup server
cd $MBD && /bin/mv *.* $BACKUP_DIR
rm -rf $MBD
exit 0
