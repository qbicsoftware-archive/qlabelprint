#!/bin/bash

##### BarcodePrinter 0.1
# Shell script for submitting barcodes to the printserver and automatically
# print them on the label-printer.
#
# @author: Sven Fillinger
# @email: sven.fillinger@student.uni-tuebingen.de
####

# Function to call when error occurs, returns an error message to the console
# and returns exit status 1
function error_exit
{
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}

function log_action
{
	echo "${PROGNAME}:$(date +%Y-%m-%d %H:%M:%S): ${1:-"Unknown log action"}" 1>&2
}

# the script's name
PROGNAME=$(basename $0)
# the directory containing the barcodes to rsync and print
DIR_BARCODES="$1"
# the host (printer server)
PRINTER_HOST="printserv.qbic.uni-tuebingen.de"
# the printer user which will connect via ssh
USER="printeruser"
# the hosts directory, where the files have to be copied to
HOST_DIR="printjobs"
# define the file size limit for the barcodes in kBytes
FILE_SIZE_LIMIT=100
# define the hosts log file
HOST_LOG_FILE="labelprinter.log"


#  Check if command param is provided or is == '-h'
if [ -z "$1" -o "$1" == "-h" ]; then
	printf '%s' "Usage:
${PROGNAME} [DIRECTORY_WITH_BARCODES]"
	exit 1
fi

# Check remote host connection
printf '%s' "Checking remote host connection: "
ping -c3 $PRINTER_HOST &> /dev/null;
if [ $? != 0 ]; then
	printf '%s\n' "FAILED"
	error_exit "Line $LINENO: Could not ping remote host."
else
	printf '%s\n' "SUCCESS"
fi


# check if DIR_BARCODES is a valid directory and process the files
if [ -d "$DIR_BARCODES" ]; then
	printf '%s\n' "Validate directory: SUCCESS"
	for file in "$DIR_BARCODES"/*
	do
		# scan directory for pdf files
	  if [[ -f "$file" && "$file" =~ ".pdf" ]]; then

			# check if the maximum file size is exceeded!
			if ! [ $(du -k "$file" | cut -f -1) -le $FILE_SIZE_LIMIT ]; then
				printf '%s\n' ""$file" exceeds the maximum file size!!"
				continue
			fi

			printf '%s\n' "Submitting file to host: "$file""

			# submit the file to the remote host
			rsync --progress -- "$file" $USER@$PRINTER_HOST:$HOST_DIR/

			# Check if transfer was successful
			if [ $? == 0 ]; then
				printf '%s\n' "--------------------------------------------"
				printf '%s\n' "Successfully transfered file to remote host."
				printf '%s\n' "--------------------------------------------"

				# now connect to the printserver and trigger the printjob
				ssh $USER@$PRINTER_HOST "{ printf '%s\t' "$(date +%Y-%m-%d_%H:%M:%S):";
					lp $HOST_DIR/$(basename "$file"); } | tee -a $HOST_LOG_FILE"


				if [ $? == 0 ]; then
					printf '%s\n' "--------------------------------------------"
					printf '%s\n' "Successfully printed file from remote host."
					printf '%s\n' "--------------------------------------------"
					message="$(date +%Y-%m-%d_%H:%M:%S):\tSuccessfully printed $(basename $file)"
					ssh $USER@$PRINTER_HOST "printf '%b\n' \"$message\" | tee -a $HOST_LOG_FILE"
				else
					message="[SUCCESS] $(date +%Y-%m-%d_%H:%M:%S):\tFailed to print $(basename $file)"
					ssh $USER@$PRINTER_HOST "printf '%b\n' \"$message\" | tee -a $HOST_LOG_FILE"
					error_exit "Line $LINENO: Could not print from remote host."
				fi

				# remove file after printing from the printserver
				ssh $USER@$PRINTER_HOST "rm $HOST_DIR/$(basename "$file")"

				if [ $? != 0 ]; then
					message="[ERROR] $(date +%Y-%m-%d_%H:%M:%S):\tCould not delete $(basename "$file") from remote dir."
					ssh $USER@$PRINTER_HOST "printf '%b\n' \"$message\" | tee -a $HOST_LOG_FILE"
				fi

			fi
		fi
	done
else
	printf '%s\n' "Validate directory: FAILED"
	error_exit "Line $LINENO: No directory with that name found"
fi
