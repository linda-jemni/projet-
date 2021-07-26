
# Mise en place de l'infrastructure pour Puppet

## Préparation

### Choisir la version que vous préféréz

* Soit à base de Virtualbox (solution de préférence)
* Soit à base de LXC

Renommer le fichier `Vagrantfile.xxxx` en `Vagrantfile`


### Générer des clefs SSH

Une paire de clefs pour votre hébergement git:

    ssh-keygen -f githosting_rsa -C githosting_rsa

P.S: copier ensuite la clef publique pour GIT dans votre hébergement


### Préparer les machines virtuelles

Si elles sont éteintes

    vagrant up

Si elles sont déjà démarrées

    vagrant rsync && vagrant provision


## Utilisation

### Connexion sur les machines virtuelles 

Depuis le host, taper:

    vagrant ssh server0
    vagrant ssh server1
    vagrant ssh server2


## Trucs et astuces

### Utilisation de /etc/hosts

Pour associer les noms aux adresses IP, sans DNS

    cat >> /etc/hosts <<MARK
    ## BEGIN PROVISION
    192.168.50.250      control
    192.168.50.10       server0
    192.168.50.20       server1
    192.168.50.30       server2
    ## END PROVISION
    MARK


### Utilisation de l'agent SSH 

Pour pré-charger les clefs SSH

	eval $(ssh-agent -s)
	ssh-add ~/.ssh/githosting_rsa


### Pour valider automatiquement les clefs 

Ajouter la liste des machines dans le fichier liste-pour-ssh

    for machine in server0 server1 server2 control ; do \
      ssh-keyscan $machine  >> ~/.ssh/known_hosts ; \
    done

