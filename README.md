# Système de traitement des presences au Coworking metz

## Utilisation
Le scripts de ce dépot peuvent tous être appellés avec le flag `-h` ou `--help` pour avoir plus de détails sur leur utilité et leur fonctionnement.

**Liste des scripts :**
### Déclenchement manuel ou via flags
* `presences.sh` Analyse des fichiers de logs pour calculer les présences par user 
* `reupload_period.sh` Refaire l'analyse des présences pour une période donnée 
* `reupload.sh` Refaire l'analyse des présences pour une adresse MAC donnée 
### Programmés
* `upload.sh` Faire l'analyse des présences pour une date donnée (chaque soir)
* `flags.sh` Traitement des flags envoyés depuis `ticket-backend` (toutes les 5 secondes)

## Dépendances

- ssh
- curl pour l'envoi sur le front
- rclone pour recupérer les fichiers de probes. Configuration dans [BitWarden](https://vault.bitwarden.com/#/vault?search=rc&itemId=6b663eae-c1bf-4d06-84e7-b1e700e83661)
- systemD pour la gestion des services

[Aide sur les timer systemD](https://wiki.archlinux.org/index.php/Systemd/Timers)

## Installation
Dans l'ordre indiqué
Toute l'installation ce passe en root


### Instalation 

1 On clone le repos
```
cd /opt/
git clone https://gitlab.com/coworking-metz/traitement-presences.git
```
2 On set les droits d'exécution
```
chmod +x /opt/traitement-presences/presences.sh
chmod +x /opt/traitement-presences/upload.sh
chmod +x /opt/traitement-presences/reupload.sh
chmod +x /opt/traitement-presences/reupload_period.sh
```
2 On crée les liens symboliques pour les timers et les services
```
ln -s /opt/traitement-presences/utils/ticket-upload.timer /etc/systemd/system
ln -s /opt/traitement-presences/utils/ticket-upload.service /etc/systemd/system
ln -s /opt/traitement-presences/utils/ticket-flags.timer /etc/systemd/system
ln -s /opt/traitement-presences/utils/ticket-flags.service /etc/systemd/system
```
3 On active les timers
```
systemctl enable ticket-upload.timer
systemctl enable ticket-flags.timer
```
4 On démarre les timers
```
systemctl start ticket-upload.timer
systemctl start ticket-flags.timer
```


## Organisation

 /!\ Les dossier d'instalation ont changé depuis la citation

 - Dossier d'install : '/opt/traitement-presences/'
 - Dossier des services : '/etc/systemd/system'

2 timer réglés sur :
- flags : toute les 5 secondes
- upload : tous les jours à 22:15:00

Le lan est hardcodé dans le script probe.sh


