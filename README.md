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



