# Système de traitement des presences au Coworking metz

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
chmod +x /opt/presences/presences.sh
chmod +x /opt/presences/upload.sh
chmod +x /opt/presences/reupload.sh
```
2 On crée les liens symboliques pour les timers et les services
```
ln -s /opt/presences/ticket-upload.timer /etc/systemd/system
ln -s /opt/presences/ticket-upload.service /etc/systemd/system
```
3 On active les timers
```
systemctl enable ticket-upload.timer
```
4 On démarre les timers
```
systemctl start ticket-upload.timer
```

## Citation Source


> - `presences.sh` aggrège les données d'une journée (passée en paramètre), télécharge la correspondance adresse mac -> adresse mail/identifant depuis tickets.coworking-metz.fr/mac  et calcul pour chaque compte le "montant de présence" (0.5 ou 1 ticket). Ce script est utilisé par les deux scripts suivants.

> - `upload.sh` envoie pour chaque adresse résultant de `presences.sh` le montant de présence sur tickets.coworking-metz.fr/presence et loggue une éventuelle erreur dans /var/presences/logs/YYYY-MM-DD ce script est appelé tous les soirs à 19h15. On peut utiliser `upload.sh YYYY-MM-DD` pour reuploader toute une journée

> - `reupload.sh` (alias la moulinette) permet de reparcourir les données pour une adresse mac donnée en paramètre et met à jour le compte correspondant. Cela permet de manuellement mettre à jour une solde si une adresse mac a été saisie trop tard sur tickets.coworking-metz.fr. Le script affiche les journées où l'adresse mac a été détectée. Exemple : `/var/presences/reupload.sh 11:22:33:44:55:66`

## Organisation

 /!\ Les dossier d'instalation ont changé depuis la citation

 - Dossier d'install : '/opt/presences/'
 - Dossier des services : '/etc/systemd/system'

3 timer réglés sur :
- probe : toute les minutes
- upload : tous les jours à 22:15:00

Le lan est hardcodé dans le script probe.sh


