#!/nin/bash


#TODO read content of openssl.cnf into an array
#   Reads the given openssl.cnf removes all comments, spaces and empty lines
#   Parameter:
#   $1: Path to openssl.cnf
#
ssl_read_config() 
{
    # read openssl config, remove all comments
    local filecontent=$(sed -e "s/#.*//" $1 | tr -d ' \t' | egrep -v "^$" | tr '\n' '#') # | sed 's/#\[/\n\[/g')
    echo $filecontent
}


#
#   Get the default CA within the given filecontent ($1).
#   Parameter:
#   $1: filecontent of openssl.cnf
#
ssl_get_default_ca()
{
    # get default CA 
    [[ $1 =~ default_ca=CA_[a-zA-Z0-9]+ ]] && DEFAULTCA=$(echo $BASH_REMATCH | cut -d"=" -f2)
    echo $DEFAULTCA
}


#TODO get only CA's in brackets
#   Get all CA's within the given filecontent ($1). CA's are marked by the prefix "CA_"
#   Parameter:
#   $1: filecontent of openssl.cnf
#
ssl_get_all_cas() 
{
    # get all CA's
    local CAS=$(echo $1 | grep -Po "CA_[a-zA-Z0-9]+" | sort | uniq | tr '\n' ' ')
    echo $CAS
}

#
#   Reads the content of openssl.cnf and "returns" the directories of the given CA (separated by space)
#   Parameter:
#   $1: filecontent of openssl.cnf
#   $2: name of CA
#
ssl_get_ca_dir()
{
    local ca_content=""
    [[ $1 =~ \[$2\]{1}[a-zA-Z0-9#=.\/\\\$\_]+ ]] && ca_content=$BASH_REMATCH
    # remove last "#"
    ca_content=$(echo $ca_content | sed 's/#$//')
    echo $ca_content | cut -d# -f2- | sed 's/#/ /g'
}

#
#   Sets all directories and files of the given CA to the CURRENTCA variables.
#   Parameter:
#   $1: openssl.cnf content of the CA (use ssl_get_ca_dir to get the content)
#
set_ca_variables()
{
    read -a ca_content_array <<< "$1"
    for entry in ${ca_section_content[@]}; do
        [[ $entry =~ ^dir.+ ]] && CURRENTCADIR=$(echo $entry | cut -d"=" -f2)
        [[ $entry =~ ^certs.+ ]] && CURRENTCACERTDIR=$(echo $entry | cut -d"=" -f2 | sed 's/$dir/%s/g')
        if [ ! -z ${CURRENTCACERTDIR} ]; then
            CURRENTCACERTDIR=$(printf "$CURRENTCACERTDIR" $CURRENTCADIR)
        fi
        [[ $entry =~ ^crl_dir.+ ]] && CURRENTCACRLDIR=$(echo $entry | cut -d"=" -f2 | sed 's/$dir/%s/g')
        if [ ! -z ${CURRENTCACRLDIR} ]; then
            CURRENTCACRLDIR=$(printf "$CURRENTCACRLDIR" $CURRENTCADIR)
        fi  
        [[ $entry =~ ^database.+ ]] && CURRENTCADB=$(echo $entry | cut -d"=" -f2 | sed 's/$dir/%s/g')
        if [ ! -z ${CURRENTCADB} ]; then
            CURRENTCADB=$(printf "$CURRENTCADB" $CURRENTCADIR)
        fi 
        [[ $entry =~ ^new_certs_dir.+ ]] && CURRENTCANEWCERTDIR=$(echo $entry | cut -d"=" -f2 | sed 's/$dir/%s/g')
        if [ ! -z ${CURRENTCANEWCERTDIR} ]; then
            CURRENTCANEWCERTDIR=$(printf "$CURRENTCANEWCERTDIR" $CURRENTCADIR)
        fi 
        [[ $entry =~ ^certificate.+ ]] && CURRENTCACERT=$(echo $entry | cut -d"=" -f2 | sed 's/$dir/%s/g')
        if [ ! -z ${CURRENTCACERT} ]; then
            CURRENTCACERT=$(printf "$CURRENTCACERT" $CURRENTCADIR)
        fi  
        [[ $entry =~ ^serial.+ ]] && CURRENTCASERIAL=$(echo $entry | cut -d"=" -f2 | sed 's/$dir/%s/g')
        if [ ! -z ${CURRENTCASERIAL} ]; then
            CURRENTCASERIAL=$(printf "$CURRENTCASERIAL" $CURRENTCADIR)
        fi 
        [[ $entry =~ ^crlnumber.+ ]] && CURRENTCACRLNUMBER=$(echo $entry | cut -d"=" -f2 | sed 's/$dir/%s/g')
        if [ ! -z ${CURRENTCACRLNUMBER} ]; then
            CURRENTCACRLNUMBER=$(printf "$CURRENTCACRLNUMBER" $CURRENTCADIR)
        fi
        [[ $entry =~ ^crl.+ ]] && CURRENTCACRL=$(echo $entry | cut -d"=" -f2 | sed 's/$dir/%s/g')
        if [ ! -z ${CURRENTCACRL} ]; then
            CURRENTCACRL=$(printf "$CURRENTCACRL" $CURRENTCADIR)
        fi  
        [[ $entry =~ ^private_key.+ ]] && CURRENTCAPRIVATEKEY=$(echo $entry | cut -d"=" -f2 | sed 's/$dir/%s/g') 
        if [ ! -z ${CURRENTCAPRIVATEKEY} ]; then
            CURRENTCAPRIVATEKEY=$(printf "$CURRENTCAPRIVATEKEY" $CURRENTCADIR)
        fi
        [[ $entry =~ ^RANDFILE.+ ]] && CURRENTCARANDFILE=$(echo $entry | cut -d"=" -f2 | sed 's/$dir/%s/g') 
        if [ ! -z ${CURRENTCARANDFILE} ]; then
            CURRENTCARANDFILE=$(printf "$CURRENTCARANDFILE" $CURRENTCADIR)
        fi
    done
    # set variable for signing requests
    CURRENTCACSRDIR="${CURRENTCADIR}/csr"
}


###############################################################################
#
# Certificate creation
#
###############################################################################

#
#   Creates a file with random noise. The filename (and path) is given by
#   the first parameter. If the first parameter is empty, the script will
#   ask for the filename.
#   Parameter:
#   $1: filename of randfile
#   Returns:
#   filename of the randfile. if the filename is empty the user don't want to use
#   a randfile. 
#
ssl_create_rand_noise()
{
    echo "[+] Create random noise"
    randfile=""
    # check whether a random noise filename is given 
    if [ ! -z "$1" ]; then
        # path to randfile is not empty
        # check whether the random noise file exists and is not empty
        if [ ! -s $1 ]; then
            read -p "[-] Random noise file does not exist or is empty. Do you want to create it? [Y/n]" -n 1
            if [ -z $REPLY ] || [[ $REPLY = [yY] ]]; then
                openssl rand -out $1 $RANDBYTES
                randfile=$1
                echo "[-] Path to random noise is: ${randfile}"
            fi
        else
            read -p "[-] Random noise file exists. Do you want to overwrite it? [y/N]" -n 1
            if [ -z $REPLY ] || [[ $REPLY = [yY] ]]; then
                openssl rand -out $1 $RANDBYTES
                randfile=$1
                echo "[-] Path to random noise is: ${randfile}"
            else
                randfile=$1
            fi
        fi
    else
        # path to random noise file is empty
        read -p "[-] Random noise file does not exist. Do you want to create it? [Y/n]" -n 1
        if [ -z $REPLY ] || [[ $REPLY = [yY] ]]; then
            read -p "[>] Enter the filename for random noise: "
            while [ -z $REPLY ]; do
                read -p "[>] Enter the filename for random noise: "
            done
            randfile="${CURRENTCAPRIVATEKEY%/*}/$REPLY"
            openssl rand -out $randfile $RANDBYTES
            echo "[-] Path to random noise is: ${randfile}"
        fi
    fi
}


#
# creates a RSA key
# Parameter:
# $1:               path to random noise file, if $1 is empty this function asks for a filename
#                   the file will be stored in the private folder 
# $2 (optional):    name of private key
# $3:               caller function name ($FUNCNAME)
#
ssl_create_key()
{
    # create random noise
    ssl_create_rand_noise $1
    # create default key name
    if [ "$3" == "ssl_create_signing_request" ]; then
        default_key=${CURRENTCAPRIVATEKEY##*/}
    else
        default_key="new.key"
    fi
    echo "[+] Create key"
    if [ ! -z $2 ]; then
        # path to private key is not empty
        keyname=$2
        # check whether the variable randfile is empty 
        if [ ! -z "$randfile" ]; then
            # randfile is not empty, user wants to use random noise
            randoption="-rand ${randfile}"
        else
            # randfile is empty, user doesn't want to use random noise
            randoption=""
        fi
    else
        # path to private key is empty, user has to enter the filename
        read -p "[-] Enter the filename of the private key [$default_key]: "
        if [ -z $REPLY ]; then 
            keyname="${CURRENTCAPRIVATEKEY%/*}/$default_key"
        else
            keyname="${CURRENTCAPRIVATEKEY%/*}/$REPLY"
        fi
    fi
    # check whether the key already exists
    if [ ! -s $keyname ]; then
        # key does not exist
        openssl genrsa -out $keyname -aes256 $KEYSIZE $randoption
    else 
        # key exists and is not empty
        read -p "[-] Key already exists. Do you want to overwrite it? [y/N]" -n 1
        echo -e "\n"
        if [[ $REPLY = [yY] ]]; then
            openssl genrsa -out $keyname -aes256 $KEYSIZE $randoption
        fi
    fi
}


#
# creates a self signed certificate. This function handles all task to create the cert,
# i.e. create random noise, the private key and the cert itself
#
ssl_create_selfsigned_cert()
{
    echo -e "\n[+] Create a self signed certificate\n"
    ssl_create_key $CURRENTCARANDFILE $CURRENTCAPRIVATEKEY
    # variable keyname is the correct filename of the key (variable within ssl_create_key)
    echo "[+] Create certificate"
    openssl req -new -x509 -days $SELFSIGNEDDAYS -key $keyname -out $CURRENTCACERT -config $OPENSSLCONF
}


#
# creates a certificate signing request
#
ssl_create_signing_request()
{
    echo -e "\n[+] Create Certificate signing request\n"
    echo "[-] Create key"
    ssl_create_key "" ""    # empty arguments, function will ask for filenames
    echo "[-] Create signing request"
    read -p "[>] Enter filename of CSR file: [new.csr] "
    if [ -z "$REPLY" ]; then
        csrfilename="${CURRENTCACSRDIR}/new.csr"
    else
        csrfilename="${CURRENTCACSRDIR}/$REPLY"
    fi
    openssl req -new -key $keyname -out $csrfilename -config $OPENSSLCONF
}


#
# creates the certificate revocation list for the current used ca.
#
ssl_create_crl()
{
    echo -e "\n[+] Create CRL for ${CURRENTCA}"
    openssl ca -name $CURRENTCA -md sha512 -gencrl -out $CURRENTCACRL -config $OPENSSLCONF
}


#
# signs a certificate which is stored in the csr directory
#
ssl_sign_certificate()
{
    echo -e "\n[+] Sign a certificate\n"
    # get all files within the directory csr
    csrfiles=$(find $CURRENTCACSRDIR -type f | egrep *.csr$)
    PS3="Select a csr: "
    if [ ! -z "$csrfiles" ]; then
        # csr directory is not empty
        select opt in ${csrfiles}
        do
            # check whether user input is valid or not
            if [ ! -z $opt ]; then
                csr=$opt
                break
            else
                echo "[-] Invalid option"
            fi
        done
        echo -e "[-] You selected: ${opt}\n"
        # variable for certificate extension type, if this variable is empty, the default
        # extension will be used (user certificate)
        extension=""
#        CSRMENU=("User certificate" "Server certificate" "Sub CA certificate" "Proxy certificate")
        CSRMENU=("User certificate" "Server certificate" "Sub CA certificate")
        PS3="Select type of certificate: "
        # get type of certificate 
        select opt in "${CSRMENU[@]}"
        do
            case $REPLY in
                1)  # User certificate
                    extension="user_cert"
                    break
                    ;;
                2)  # Server certificate
                    extension="server_cert"
                    break
                    ;;
                3)  # Sub CA certificate
                    extension="subca_cert"
                    break
                    ;;
#                4)  # Proxy certificate
#                    extension="proxy_cert"
#                    break
#                    ;;
                *)  # invalid option 
                    echo "Invalid option"
                    ;;
            esac  
        done
        # if extension is equal to "server_cert" or "proxy_cert", the user have to set the subject alternativ name
        if [ "$extension" == "proxy_cert" ] || [ "$extension" == "server_cert" ]; then
            read -p "[-] Enter the subject alternative name (e.g. DNS:www.example.com, email:test@example.com): "
            while [ -z "$REPLY" ]; do
                read -p "[-] Enter the subject alternative name (e.g. DNS:www.example.com, email:test@example.com): "
            done
            # export user input to environment variable "ALTNAME"
            export ALTNAME=$REPLY
        fi
        # save current serial. This will be the filename of the signed certificate 
        certserial=$(cat $CURRENTCASERIAL)
        # sign certificate
        openssl ca -name $CURRENTCA -md sha512 -in $csr -extensions $extension -config $OPENSSLCONF
        # check whether the last command was successful
        if [ $? -eq 0 ]; then
            # get common name of signed certificate
            certcn=$(subj=$(openssl x509 -text -in "${CURRENTCANEWCERTDIR}/$certserial.pem" | grep "Subject:") ; [[ $subj =~ CN=[a-zA-Z0-9_@[:space:].:\(\)]+[^/] ]] && cn=$BASH_REMATCH ; echo $cn | cut -d"=" -f2 | sed 's/ /_/g')
            # copy new certificate to "certs" directory and rename it to the common name of the certificate
            cp "${CURRENTCANEWCERTDIR}/$certserial.pem" "${CURRENTCACERTDIR}/$certcn.pem"
        else
            echo "[-] Failed to sign the certificate ${csr}"
        fi
    else
        echo "[-] No csr files found in ${CURRENTCACSRDIR}"
    fi
}


#
# revokes a certificate which is stored within "certs"
#
ssl_revoke_cert()
{
    echo -e "\n[+] Revoke a certificate\n"
    # get all files within "certs" directory
    certfiles=$(find $CURRENTCACERTDIR -type f | egrep *.pem$)
    PS3="Select a certificate to revoke: "
    # check whether files are stored within "certs"
    if [ ! -z "$certfiles" ]; then
        # found *.pem files
        select pem in ${certfiles}
        do
            # check for invalid user input
            if [ ! -z $pem ]; then
                revcert=$pem
                break
            else
                echo "[-] Invalid input"
            fi
        done
        # revoke certificate
        openssl ca -name $CURRENTCA -revoke $pem -config $OPENSSLCONF
        # TODO perhaps create a new crl at this point
        echo "[+] Don't forget to create a new revocation list"
    else
        # directory contains no *.pem files
        echo "[+] No certs found in ${CURRENTCACERTDIR}"        
    fi
}


#
# prints the content of a certificate which is stored within "certs"
#
ssl_print_cert()
{
    echo -e "\n[+] Print content of a certificate to stdout\n"
    # get all files within "certs" directory
    certfiles=$(find $CURRENTCACERTDIR -type f | egrep *.pem$)
    PS3="Select a certificate to verify: "
    # check whether files are stored within "certs"
    if [ ! -z "$certfiles" ]; then
        # found *.pem files
        select pem in ${certfiles}
        do
            # check for invalid user input
            if [ ! -z $pem ]; then
                revcert=$pem
                break
            else
                echo "[-] Invalid input"
            fi
        done
        # print certificate content to stdout
        openssl x509 -in $pem -noout -text
    else
        # directory contains no *.pem files
        echo "[+] No certs found in ${CURRENTCACERTDIR}"        
    fi
}

#
# verifies a certificate which is stored within "certs"
#
ssl_verify_cert()
{
    echo -e "\n[+] Verify a certificate\n"
    # get all files within "certs" directory
    certfiles=$(find $CURRENTCACERTDIR -type f | egrep *.pem$)
    PS3="Select a certificate to verify: "
    # check whether files are stored within "certs"
    if [ ! -z "$certfiles" ]; then
        # found *.pem files
        select pem in ${certfiles}
        do
            # check for invalid user input
            if [ ! -z $pem ]; then
                revcert=$pem
                break
            else
                echo "[-] Invalid input"
            fi
        done
        # verify certificate
        openssl verify -verbose -CApath $CURRENTCADIR -CAfile $CURRENTCACERT $pem
    else
        # directory contains no *.pem files
        echo "[+] No certs found in ${CURRENTCACERTDIR}"        
    fi
}

#
# exports a certificate which is stored within "certs" to PKCS#12 format 
#
ssl_export_cert()
{
    echo -e "\n[+] Export a certificate to PKCS#12\n"
    echo -e "[-] The exported certificate will contain the public AND private key!\n"
    # get all files within "certs" directory
    certfiles=$(find $CURRENTCACERTDIR -type f | egrep *.pem$)
    PS3="Select a certificate to export: "
    # check whether files are stored within "certs"
    if [ ! -z "$certfiles" ]; then
        # found *.pem files
        select pem in ${certfiles}
        do
            # check for invalid user input
            if [ ! -z $pem ]; then
                revcert=$pem
                break
            else
                echo "[-] Invalid input"
            fi
        done
        keyfiles=$(find ${CURRENTCAPRIVATEKEY%/*} -type f | egrep *.key$)
        PS3="Select the private key of the certificate: "
        # check whether files are stored within "private"
        if [ ! -z "$keyfiles" ]; then
            # found *.key files
            select key in ${keyfiles}
            do
                # check for invalid user input
                if [ ! -z $key ]; then
                    privkey=$key
                    break
                else
                    echo "[-] Invalid input"
                fi
            done
            read -p "Enter a name for the certificate: "
            while [ -z "$REPLY" ]; do
                read -p "Enter a name for the certificate: "
            done
            name=$(echo $REPLY | sed 's/ /-/g')
            # change file extension
            newname="${pem%*.pem}.pfx"
            # change path
            newname="${CURRENTCAPRIVATEKEY%/*}/${newname##*/}"
            # revoke certificate
            openssl pkcs12 -export -in $pem -inkey $privkey -out $newname -name $name
            if [ $? -eq 0 ]; then
                echo "[+] Path to exported certificate: ${newname}"
            fi
        else
            echo "[+] No keys found in ${CURRENTCAPRIVATEKEY%/*}"
        fi
    else
        # directory contains no *.pem files
        echo "[+] No certs found in ${CURRENTCACERTDIR}"        
    fi
}


#
# splits a key which is stored in "private" 
#
ssl_split_key()
{
    echo -e "\n[+] Split key\n"
    # get all files within "private" directory
    keyfiles=$(find ${CURRENTCAPRIVATEKEY%/*} -type f | egrep *.key$)
    PS3="Select a key to split: "
    # check whether files are stored within "private"
    if [ ! -z "$keyfiles" ]; then
        # found *.key files
        select key in ${keyfiles}
        do
            # check for invalid user input
            if [ ! -z $key ]; then
                key_to_split=$key
                break
            else
                echo "[-] Invalid input"
            fi
        done
        # get size of key
        split_keysize=$(stat --format %s $key_to_split)
        # get number of parts
        read -p "[-] Enter the number of parts: "
        # check for valid user input
        while [[ $REPLY -lt 2 ]] || [[ $REPLY -gt $split_keysize ]]
        do
            echo "[-] Invalid input"
            read -p "[-] Enter the number of parts: "
        done
        # divide keysize by number of parts
        partsize=$(echo "$split_keysize/$REPLY" | bc)
        # multiply partsize by number of parts to check whether the key size is divisable
        # by number of parts
        tmp=$(echo $partsize*$REPLY | bc)
        tmp2=$(echo $split_keysize-$tmp | bc)
        # create the first parts 
        for i in $(seq 1 $(echo "$REPLY-1" | bc))
        do
            dd if=$key_to_split of="${key_to_split}.part${i}" bs=1 count=$partsize skip=$(echo "($i-1)*$partsize" | bc)
        done
        # create last part (this part can be larger as the other)
        dd if=$key_to_split of="${key_to_split}.part${REPLY}" bs=1 count=$(echo "$partsize+$tmp2" | bc) skip=$(echo "($REPLY-1)*$partsize" | bc)
    else
        # directory contains no *.key files
        echo "[+] No keys found in ${CURRENTCAPRIVATEKEY%/*}"
    fi
}


#
# combines the parts of a key 
#
ssl_combine_key()
{
    echo -e "\n[+] Combine key\n"
    # get all keys which have part files within the directory "private"
    splitted_keys=$(ls ${CURRENTCAPRIVATEKEY%/*} | grep part | sed '/part/s/part.//g' | sed 's/.$//g' | sort | uniq)
    PS3="Select a key to combine: "
    if [ ! -z "$splitted_keys" ]; then
        # there are splitted keys within "private"
        select key in ${splitted_keys}
        do
            # check for invalid user input
            if [ ! -z $key ]; then
                key_to_combine=$key
                break
            else
                echo "[-] Invalid input"
            fi
        done
        cat "${CURRENTCAPRIVATEKEY%/*}/${key_to_combine}.part"* > "${CURRENTCAPRIVATEKEY%/*}/${key_to_combine}"
        if [ $? -ne 0 ]; then
            echo "[-] Failed to combine ${key_to_combine}"
        else
            echo "[-] ${key_to_combine} successfully combined"
            read -p "[-] Do you want to shred the part files? [Y/n]" -n 1
            if [ -z $REPLY ] || [[ $REPLY =~ [yY] ]]; then
                shred -uzvn $SHREDNUMBER "${CURRENTCAPRIVATEKEY%/*}/${key_to_combine}.part"*
            fi
        fi
    else
         # directory contains no *.part files
        echo "[+] No *.part files found in ${CURRENTCAPRIVATEKEY%/*}"
    fi
}


#
# shreds a key within "private"
#
ssl_shred_key()
{
    echo -e "\n[+] Shred key\n"
    # get all files within "private" directory
    keyfiles=$(find ${CURRENTCAPRIVATEKEY%/*} -type f | egrep *.key$)
    PS3="Select a key to shred: "
    # check whether files are stored within "private"
    if [ ! -z "$keyfiles" ]; then
        # found *.key files
        select key in ${keyfiles}
        do
            # check for invalid user input
            if [ ! -z $key ]; then
                key_to_shred=$key
                break
            else
                echo "[-] Invalid input"
            fi
        done
        read -p "Do you really want to shred the key ${key_to_shred} [y/N]" -n 1
        if [[ $REPLY =~ [yY] ]]; then
            shred -uzvn $SHREDNUMBER $key_to_shred
        fi
    fi
}

