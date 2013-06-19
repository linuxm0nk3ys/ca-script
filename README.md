CA script
=========

A little Bash script to create, sign, revoke, verify and export certificate.
This version is a stable version. But maybe some features are not implemented.
I appriciate any suggestions or bug reports.

Feel free to modify the script or to fork the script.

Requirements
============
The script uses the following linux commands:
- bc
- cat
- cut
- dd
- egrep
- find
- grep
- openssl
- sed
- shred
- sort
- stat
- tr
- uniq

Usage
=====
To start the script just start the ca.sh.

The script "ca.sh" will read the openssl.cnf and parse it to get the CA sections (You can change the path to the openssl.cnf by changing the value of the "OPENSSLCONF" in "ca.sh"). 

You can change the default values for most of the parameters in "conf.sh".


Signed certificates will be stored in "newcerts" and "certs". The name of the certificate in "newcerts" will be the actual serial number of the CA. The name of certificates in "certs" will be renamed to the common name.

Exported certificates "PKCS#12" will be stored in "private".

- The CA Sections within the openssl.cnf have to start with the string "CA_".
- Generated keys will be stored in the "private" directory of the current used CA.
- The extension of the keys have to be "key"
- The extension of the certificate signing request have to be "csr"
