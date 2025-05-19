#!/usr/bin/env bash
#
SCRIPT_FULLNAME=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_BASENAME=$(basename $0)
SCRIPT_DIR_TEST="scripts/$SCRIPT_BASENAME"
KEYNAME="privkey.pem"
CERTNAME="fullchain.pem"
DHNAME="dhparam.pem"
VALID="1095"
INTERMEDIATE_KEY="intermediate_key.pem"
INTERMEDIATE_REQ="intermediate_req.pem"
SUBJ="/C=BR/O=Your compane name/CN=Intermediate Certificate"
INTERMEDIATE_CERT="intermediate_cert.pem"
CHAIN="chain.pem"

echo $SCRIPT_FULLNAME | grep "$SCRIPT_DIR_TEST"
if [ "$?" = 0 ];then
    CERTDIR="$(echo "$SCRIPT_FULLNAME"| sed "s/scripts\/$SCRIPT_BASENAME//g")certs/"
else
    echo "    ALERTA: Se o script estiver fora do diretório padrão pode gerar comportamento indesejado!"
    echo "    Diretório esperado: $PWD/scripts"
    CERTDIR="$(echo "$SCRIPT_FULLNAME"| sed "s/$SCRIPT_BASENAME//g")certs/"
fi

# Functions
# Create certs function
Cert_and_dhparam_create() {
    # Generate private key and testened certificate
    if openssl req -newkey rsa:2048 -nodes -keyout ${CERTDIR}${KEYNAME} -x509 -days "${VALID}" -out ${CERTDIR}${CERTNAME}; then
        echo "Chave privada e certificado autoassinado gerados com sucesso."
    else
        echo "Erro ao gerar chave privada e certificado autoassinado."
        return 1
    fi

    # Generate private key and CSR for the intermediate certificate
    if openssl req -new -keyout "${CERTDIR}${INTERMEDIATE_KEY}" -out "${CERTDIR}${INTERMEDIATE_REQ}" -subj "${SUBJ}"; then
        echo "Chave privada e CSR para certificado intermediário gerados com sucesso."
    else
        echo "Erro ao gerar chave privada e CSR para certificado intermediário."
        return 1
    fi

    # Sign the intermediate certificate with self testened certificate
    if openssl x509 -req -days "${VALID}" -in "${CERTDIR}${INTERMEDIATE_REQ}" -CA "${CERTDIR}${CERTNAME}" -CAkey "${CERTDIR}${KEYNAME}" -CAcreateserial -out "${CERTDIR}${INTERMEDIATE_CERT}"; then
        echo "Certificado intermediário assinado com sucesso."
    else
        echo "Erro ao assinar certificado intermediário com o certificado autoassinado."
        return 1
    fi

    # Generate chain.pem file concatenating certificate self testened and intermediate certificate
    if cat "${CERTDIR}${CERTNAME}" "${CERTDIR}${INTERMEDIATE_CERT}" > "${CERTDIR}${CHAIN}"; then
        echo "Arquivo chain.pem criado com sucesso."
    else
        echo "Erro ao criar arquivo chain.pem."
        return 1
    fi

    # Generate parameters Diffie-Hellman
    if openssl dhparam -out "${CERTDIR}${DHNAME}" 2048; then
        echo "Parâmetro Diffie-Hellman gerado com sucesso."
    else
        echo "Erro ao gerar parâmetro Diffie-Hellman!"
        return 1
    fi

    echo "Certificado e parâmetro Diffie-Hellman gerados com sucesso."
    return 0
}

# Main script logic
main() {
    # Ensure directories exist or create them
    if [ ! -d "$CERTDIR" ]; then
        mkdir -p "$CERTDIR" || { echo "Erro ao criar diretório: $CERTDIR"; exit 1; }
    fi

    # Generate certificates
    Cert_and_dhparam_create || { echo "Erro ao gerar certificados e parâmetros"; exit 1; }

    # Set permissions
    chmod -w $CERTDIR* || { echo "Erro ao definir permissões em $CERTDIR"; exit 1; }

    echo "Script concluído com sucesso!"
}

# Run main function
main

