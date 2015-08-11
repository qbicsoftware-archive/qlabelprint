# qlabelprint
Shell script that will read out the barcodes from a folder and submits them to the printerserver. They will then be printed automatically on the TSC label printer.

```bash
> ./qbcprinter.sh [directory_barcodes]
```


### Setup client
In order to run the script successfully from a client, you have to make sure that the client can connect to the printerserver via ssh. I set up a user on the printer-server called `printeruser` that is allowed to print. In order to let the script connect via ssh, I added a **public key** to the `authorized_keys` file on the printer-server.


### SSH connection with keyfiles
In order to let the script run automatically from i.e. an application server, you don't want to use passphrases for the ssh connection. So you can use rsa-keyfiles to successfully connect to the printer-server. The public key is already installed on the server, you only need the private key. Feel free to come to my office to get an authorized copy of the private key.


### What the script does - details

***1. Global settings.*** First, I did some global settings, like the directory for the barcodes, the host's address and a maximum file size limit. Latter is set to 100kB by default, but of course can be adjusted if neccessary. I want to limit the file size, if accidently a bigger pdf is in the directory, it will not be transfered to the printer-server (not a valid barcode.pdf).

```bash

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

```

***2. Remote connection check.*** The script checks the remote connection to the host via `ping`. If it is not successful, the script will return the error and return exit status 1. 

```bash
# Check remote host connection
printf '%s' "Checking remote host connection: "
ping -c3 $PRINTER_HOST &> /dev/null;
if [ $? != 0 ]; then
	printf '%s\n' "FAILED"
	error_exit "Line $LINENO: Could not ping remote host."
else
	printf '%s\n' "SUCCESS"
fi
```

***3. Copying barcodes to remote host.*** The script scans the given directory for pdfs and only accepts small files (as the barcodes are usually very small). If the checks are passed, it calls `rsync`for the copying.

```bash
rsync --progress $file $USER@$PRINTER_HOST:$HOST_DIR/
```

After successfully copying the files, the script automatically calls the `lp` command for printing. The label-printer on the server is already set up as default printer, so there is no need for specifying it seperately.

```bash
# now connect to the printserver and trigger the printjob
ssh $USER@$PRINTER_HOST "lp $HOST_DIR/$(basename $file)"
```

# TODO

* Clean up files after successful printing


