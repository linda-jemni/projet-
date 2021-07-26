#!/bin/sh

# Paranoia mode
set -e
set -u

# Je récupere le hostname du serveur
USER_EMAIL=""
USER_NAME=""
GIT_HOST=""
GIT_REPOSITORY=""
LAN_SUFFIX=""
HOSTNAME="$(hostname)"

WORKDIR="${1:-/vagrant}"
DOT_ENV="$WORKDIR/.env"
RSA_KEY="$WORKDIR/githosting_rsa"

## Vérifier que le fichier .env est bien défini
if [ ! -f "$DOT_ENV" ]; then
	>&2 echo "ERROR: unable to find $DOT_ENV file"
	>&2 echo ""
	>&2 echo "Please run the following command on host:"
	>&2 echo ""
	>&2 echo "    touch .env"
	>&2 echo ""
	exit 1
fi

## Vérifier le contenu du fichier .env
if ! grep -q '^USER_EMAIL=' "$DOT_ENV" ; then
	>&2 echo "ERROR: unable to find USER_EMAIL key in $DOT_ENV file"
	exit 1
fi

if ! grep -q '^USER_NAME=' "$DOT_ENV" ; then
	>&2 echo "ERROR: unable to find USER_NAME key in $DOT_ENV file"
	exit 1
fi

if ! grep -q '^GIT_HOST=' "$DOT_ENV" ; then
	>&2 echo "ERROR: unable to find GIT_HOST key in $DOT_ENV file"
	exit 1
fi

if ! grep -q '^GIT_REPOSITORY=' "$DOT_ENV" ; then
	>&2 echo "ERROR: unable to find GIT_REPOSITORY key in $DOT_ENV file"
	exit 1
fi

if ! grep -q '^LAN_SUFFIX=' "$DOT_ENV" ; then
	>&2 echo "ERROR: unable to find LAN_SUFFIX key in $DOT_ENV file"
	exit 1
fi

## Charger le contenu de .env en mémoire
eval "$(grep '^USER_EMAIL=' "$DOT_ENV")"
eval "$(grep '^USER_NAME=' "$DOT_ENV")"
eval "$(grep '^GIT_HOST=' "$DOT_ENV")"
eval "$(grep '^GIT_REPOSITORY=' "$DOT_ENV")"
eval "$(grep '^LAN_SUFFIX=' "$DOT_ENV")"

## Vérifier le contenu des variables
if [ -z "$USER_EMAIL" ]; then
	>&2 echo "ERROR: variable USER_EMAIL in .env must not be empty"
	exit 1
fi
if [ -z "$USER_NAME" ]; then
	>&2 echo "ERROR: variable USER_NAME in .env must not be empty"
	exit 1
fi
if ! echo "$GIT_REPOSITORY" |grep -q '^git@' ; then
	>&2 echo "ERROR: variable GIT_REPOSITORY must be the SSH address for the repository"
	exit 1
fi
if ! echo "$GIT_REPOSITORY" |grep -q "$GIT_HOST" ; then
	>&2 echo "ERROR: variable GIT_HOST must target the same server as GIT_REPOSITORY"
	exit 1
fi
if ! echo "$LAN_SUFFIX" |grep -q '^[a-z0-9]*$' ; then
	>&2 echo "ERROR: variable LAN_SUFFIX must contain only lowercase alphanumeric values"
	exit 1
fi

## Verifier que la paire de clefs pour GITHUB est presente avant de continuer
if [ ! -f "$RSA_KEY"  ]; then
	>&2 echo "ERROR: unable to find $RSA_KEY keyfile"
	>&2 echo ""
	>&2 echo "Please run the following command from your host to generate the keyfile:"
	>&2 echo ""
	>&2 echo "    ssh-keygen -f $(basename "$RSA_KEY") -C $(basename "$RSA_KEY")" 
	>&2 echo ""
	exit 1
fi
if [ ! -f "$RSA_KEY.pub" ]; then
	>&2 echo "ERROR: unable to find $RSA_KEY.pub keyfile"
	exit 1
fi

echo "Configuration file (.env) is valid."

