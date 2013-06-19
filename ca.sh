#!/bin/bash 

# include other bash scripts (libraries)
. ./inc/ssl_config_parser.sh
. ./inc/output.sh
# include "config file"
. ./conf.sh

# little bugfix
export ALTNAME=""

VERSION="1.1.1"
OPENSSLCONF="openssl.cnf"   # path to openssl.cnf
#
# CA variables 
#
CURRENTCA=""                # name of current used CA
CURRENTCADIR=""             # path to current used CA
CURRENTCACERTDIR=""         # path to cert folder of current used CA
CURRENTCADB=""              # path to database of current used CA 
CURRENTCANEWCERTDIR=""      # path to new cert folder of current used CA 
CURRENTCACERT=""            # path to certificate of current used CA 
CURRENTCASERIAL=""          # path to serial of current used CA 
CURRENTCACRLDIR=""          # path to crl folder of current used CA
CURRENTCACRLNUMBER=""       # path to crl number of current used CA 
CURRENTCACRL=""             # path to certivicate revocation list of current used CA 
CURRENTCAPRIVATEKEY=""      # path to private key of current used CA 
CURRENTCARANDFILE=""        # path to rand file of current used CA 
CURRENTCACSRDIR=""          # path to Certificate signing requests files 

###############################################################################
#
#   FUNCTIONS
#
###############################################################################

#
# changes the CA / the values of CURRENTCA*
#
change_ca()
{
    PS3="Select a CA: "
    select ca in ${CAarray[@]}
    do 
        break
    done
    ca_section_content=$(ssl_get_ca_dir $ssl_filecontent $ca)
    set_ca_variables $ca_section_content
    CURRENTCA=$ca
    check_ca_file_structure
}


#
# checks wether the file structure for CURRENTCA exists.
# If it does not exists it asks to create it.
#
check_ca_file_structure()
{
    if [ ! -d "$CURRENTCADIR" ];then
        echo_warning
        echo "[+] The CA directory  does not exist, it'll be created"
        # create directories
        mkdir $CURRENTCADIR
        mkdir $CURRENTCACERTDIR
        mkdir $CURRENTCANEWCERTDIR
        mkdir $CURRENTCACRLDIR
        mkdir ${CURRENTCAPRIVATEKEY%/*}
        mkdir ${CURRENTCACSRDIR}
        # create index/database
        touch $CURRENTCADB
        # create file with cert serials
        echo $FIRSTSERIAL > $CURRENTCASERIAL
        # create file with crl serials
        echo $FIRSTCRLSERIAL > $CURRENTCACRLNUMBER
    else
        echo_success
        echo "[+] The CA directory exists"
        if [ ! -d $CURRENTCACERTDIR ]; then
            echo_warning
            echo "[+] The cert directory does not exist, it'll be created"
            mkdir $CURRENTCACERTDIR
        fi
        if [ ! -d $CURRENTCANEWCERTDIR ]; then
            echo_warning
            echo "[+] The new cert directory does not exist, it'll be created"
            mkdir $CURRENTCANEWCERTDIR
        fi
        if [ ! -d $CURRENTCACRLDIR ]; then
            echo_warning
            echo "[+] The crl directory does not exist, it'll be created"
            mkdir $CURRENTCACRLDIR
        fi
        if [ ! -d ${CURRENTCAPRIVATEKEY%/*} ]; then
            echo_warning
            echo "[+] The private directory does not exist, it'll be created"
            mkdir ${CURRENTCAPRIVATEKEY%/*}
        fi
        if [ ! -d ${CURRENTCACSRDIR} ]; then
            echo_warning
            echo "[+] The CSR directory does not exist, it'll be created"
            mkdir ${CURRENTCACSRDIR}
        fi
        if [ ! -e $CURRENTCASERIAL ]; then
            echo_warning
            echo "[+] The serial file does not exist, it'll be created"
            touch $CURRENTCASERIAL
        fi
        if [ ! -e $CURRENTCADB ]; then
            echo_warning
            echo "[+] The database does not exist, it'll be created"
            echo $FIRSTSERIAL > $CURRENTCADB
        fi
        if [ ! -e $CURRENTCACRLNUMBER ]; then
            echo_warning
            echo "[+] The crl number file does not exist, it'll be created"
            echo $FIRSTCRLSERIAL > $CURRENTCACRLNUMBER
        fi
    fi
}

###############################################################################
#
#   INITAL CHECKS
#
###############################################################################

#
# check whether openssl.cnf exists and is readable
#
if [ -f $OPENSSLCONF ] && [ -r $OPENSSLCONF ]; then
    echo_success
    echo "[+] ${OPENSSLCONF} exists and is readable"
else
    echo_failure
    echo "[X] ERROR: ${OPENSSLCONF} does not exist or is not readable"
    exit 1
fi
#
# get default CA
#
ssl_filecontent=$(ssl_read_config $OPENSSLCONF)
DEFAULTCA=$(ssl_get_default_ca $ssl_filecontent)
if [ -z $DEFAULTCA ]; then
    echo_failure
    echo "[X] ERROR: ${OPENSSLCONF} contains no default CA"
    exit 1
else
    echo_success
    echo "[-] Found default CA: ${DEFAULTCA}"
    CURRENTCA=$DEFAULTCA
fi
#
# get all defined CA's
#
ssl_CAS=$(ssl_get_all_cas $ssl_filecontent)
oldIFS=$IFS # save field separator 
# convert CAS to an array
IFS=' ' read -a CAarray <<< "$ssl_CAS"
IFS=$oldIFS # restore old field separator
if [ ${#CAarray[@]} -eq 0 ]; then
    echo_failure
    echo "[X] ERROR: No CA definition found"
    exit 1
else
    echo_success
    echo "[-] Found ${#CAarray[@]} CA sections"
fi


###############################################################################
#
#   MAIN
#
###############################################################################

#
#   VARIABLES
#
GREET="LinuxM0nk3y's Certificate Authority Management\n\t\t\t\tVersion $VERSION"
# Strings for the main menu
MAINMENU=("Create a self signed certificate" "Create a certificate signing request" "Create a certificate revocation list" "Sign a certificate" "Revoke a certificate" "Verify a certificate" "Print content of a certificate" "Export a certificate to PKCS#12" "Change CA" "Split private key" "Combine private key" "Shred private key" "Quit")
#
#   Read CA variables (path, path to files, etc.) and check file structure
#
ca_section_content=$(ssl_get_ca_dir $ssl_filecontent $CURRENTCA)
set_ca_variables $ca_section_content
# check file structure for DEFAULTCA
check_ca_file_structure
#
# clear screen
clear
#
#   show menu
#
# display greeter
echo -e "\t\t$GREET\n\n"
# display current ca infos
echo_ca_info $CURRENTCA $CURRENTCAPRIVATEKEY $CURRENTCACERT
# change the input text#
PS3="Select an option: "    
# show main menu 
select opt in "${MAINMENU[@]}"
do
    case $REPLY in 
        1)  # Create a self signed certificate
            ssl_create_selfsigned_cert 
            ;;
        2)  # Create a certificate signing request
            ssl_create_signing_request
            ;;
        3)  # Create a certificate revocation list
            ssl_create_crl 
            ;;
        4)  # Sign a certificate"
            ssl_sign_certificate
            ;;
        5)  # Revoke a certificate"
            ssl_revoke_cert
            ;;
        6)  # Verify/Display a certificate 
            ssl_verify_cert
            ;;
        7)  # Print content of a certificate
            ssl_print_cert
            ;;
        8)  # Convert a certificate
            ssl_export_cert
            ;;
        9)  # Change CA 
            change_ca
            ;;
        10) # Split private key
            ssl_split_key
            ;;
        11) # Combine private key
            ssl_combine_key
            ;;
        12) # Delete private key (shred)
            ssl_shred_key
            ;;
        13) # Quit
            exit 0
            ;;
        *)  # invalid option  
            echo "Invalid option"
            ;;
    esac
    echo -e "\n"
    read -p "Press ENTER to go back to the main menu" -n 1
    clear 
    # display greeter
    echo -e "\t\t$GREET\n\n"
    # display current ca infos
    echo_ca_info $CURRENTCA $CURRENTCAPRIVATEKEY $CURRENTCACERT
    # change the input text
    PS3="Select an option: "
done
