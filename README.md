# iac-lab : Terraform + Ansible sur AWS

Lab d'Infrastructure as Code : **Terraform** crée des serveurs sur AWS, **Ansible** les configure. L'ensemble se déploie, se met à l'échelle et se détruit en quelques commandes, sans aucune action manuelle sur les serveurs.

## Architecture

```
            Machine d'administration (Debian, EC2)
            - Terraform + Ansible
            - Role IAM : aucune cle AWS stockee
                     |
        +------------+-------------+
        |                          |
   Terraform                    Ansible
   (API AWS)                    (SSH)
        |                          |
        v                          v
  +-------------------------------------------+
  |  srv-terraform-01  -02  -03  (Debian 13)  |
  |  Groupe de securite : SSH + HTTP          |
  |  depuis la machine d'administration       |
  +-------------------------------------------+
```

## Ce que fait le projet

**Terraform** (`tf-vm/`)
- Crée N serveurs Debian (nombre, gabarit et préfixe de nom paramétrables)
- Crée la paire de clés SSH et le groupe de sécurité (accès restreint à l'IP d'administration)
- Génère automatiquement l'inventaire Ansible à partir des IP attribuées par AWS

**Ansible** (`ansible-lab/`)
- Rôle `commun` : mises à jour, outils de base, fuseau horaire, compte d'administration avec clé SSH et sudo, pare-feu ufw
- Rôle `web` : nginx, configuration générée par template Jinja2, page `/sante` de supervision, zone `/admin` protégée par mot de passe
- Secret chiffré avec **Ansible Vault**, handlers pour ne recharger nginx que si la configuration change

## Structure

```
iac-lab/
├── tf-vm/
│   ├── main.tf            # Ressources AWS
│   ├── variables.tf       # Déclaration des variables
│   ├── terraform.tfvars   # Valeurs du lab
│   ├── outputs.tf         # IP des serveurs
│   └── inventaire.tpl     # Modèle de l'inventaire Ansible
└── ansible-lab/
    ├── site.yml           # Playbook : roles commun puis web
    ├── ansible.cfg
    ├── group_vars/lab/    # Variables du groupe (dont vault.yml chiffré)
    ├── host_vars/         # Surcharges par serveur
    └── roles/
        ├── commun/
        └── web/
```

## Utilisation

Prérequis : une machine Linux avec Terraform et Ansible, un rôle IAM autorisant EC2, une clé SSH `~/.ssh/id_ed25519`.

```bash
# 1. Créer l'infrastructure
cd tf-vm
terraform init
terraform apply

# 2. Configurer les serveurs
cd ../ansible-lab
ansible-playbook -i inventaire.ini site.yml --ask-vault-pass

# 3. Tout supprimer
cd ../tf-vm
terraform destroy
```

Pour changer le nombre de serveurs, modifier `nombre_vm` dans `terraform.tfvars`, puis relancer les étapes 1 et 2 : seules les nouvelles machines sont configurées.

## Sécurité

- Authentification AWS par rôle IAM attaché à l'instance, sans clé d'accès stockée
- Accès réseau limité à la machine d'administration, doublé d'un pare-feu local (défense en profondeur)
- State Terraform et fichiers générés exclus du dépôt (`.gitignore`)
- Mot de passe de la zone admin chiffré en AES-256 avec Ansible Vault, masqué dans les sorties (`no_log`)

## Pistes d'évolution

- State Terraform dans un backend distant (S3) avec verrouillage
- Équilibreur de charge devant les serveurs web
- Pipeline CI qui lance `terraform plan` et `ansible-lint` à chaque modification
