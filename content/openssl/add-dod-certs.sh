#!/bin/bash
# Import DoD root certificates into linux CA store

main() {
    # Location of bundle from DISA site
    url='https://public.cyber.mil/pki-pke/pkipke-document-library/'
    #bundle=$(curl -s $url | awk -F '"' 'tolower($2) ~ /dod.zip/ {print $2}')
    bundle=https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip

    # Set cert directory and update command based on OS
    source /etc/os-release
    if [[ $ID      =~ (fedora|rhel|centos) ||
          $ID_LIKE =~ (fedora|rhel|centos) ]]; then
        certdir=/etc/pki/ca-trust/source/anchors
        update=update-ca-trust
    elif [[ $ID      =~ (debian|ubuntu|mint) ||
            $ID_LIKE =~ (debian|ubuntu|mint) ]]; then
        certdir=/usr/local/share/ca-certificates
        update=update-ca-certificates
    else
        certdir=$1
        update=$2
    fi

    [[ -n $certdir && -n $update ]] || {
        echo 'Unable to autodetect OS using /etc/os-release.'
        echo 'Please provide CA certificate directory and update command.'
        echo 'Example: add-dod-certs.sh /cert/store/location update-cmd'
        exit 1
    }

    # Extract the bundle
    cd $certdir
    rm -fr tmp
   
    echo "get the bundle"
    wget -qP tmp $bundle

    echo "unzip the bundle"

    unzip -qj tmp/${bundle##*/} -d tmp

    # Convert the PKCS#7 bundle into individual PEM files
    echo "convert bundle into individual pem files"

    

    for p in tmp/*.p7b; do
	echo $p
        openssl pkcs7 -print_certs -in $p -inform DER |
           awk 'BEGIN {c=0} /subject=/ {c++} {print > "cert." c ".pem"}'
    done

    # Rename the files based on the CA name
    echo "rename the file based on the CA name"
    for i in *.pem; do
	echo $i
        name=$(openssl x509 -noout -subject -in $i |
               awk -F '(=|= )' '{gsub(/ /, "_", $NF); print $NF}' 
       )
        echo ${name}
        mv $i ${name}.crt
    done

    # Remove temp files and update certificate stores
    rm -fr tmp
    $update
}

# Only execute if not being sourced
[[ ${BASH_SOURCE[0]} == "$0" ]] && main "$@"
