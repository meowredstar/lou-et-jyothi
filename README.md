# lou-et-jyothi

# Projet Wokeworld

## Introduction

**Wokeworld** est une simulation 3D d'un petit écosystème et de son évolution dans le temps, réalisée à l'aide du moteur de jeu **Godot**.

---

## Fonctionnalités

### Environnements & Terrain
- **Génération procédurale du terrain** : Création d'un relief aléatoire via le bruit de Perlin.
- **Gestion des arbres** : Génération aléatoire d'un nombre fixe d'arbres au lancement.
- **Limites du terrain** : Bords du terrain bloquants pour empêcher les agents d'en sortir.
- **Météo & Incendies** :
  - Système de météo intégrant la pluie.
  - Simulation de feux de forêt.
  - Extinction aléatoire des arbres en feu lorsqu'il pleut.
  - Pousse de nouveaux arbres après la pluie.
  - Équilibrage du système afin d'éviter la disparition totale de la végétation.

### Agents & Dynamiques de Population
- **Génération d'agents** : Population initiale fixe de proies et de prédateurs.
- **Comportement Proie-Prédateur** :
  - Champ de détection pour la poursuite et la fuite.
  - Adaptation dynamique des vitesses de fuite et de poursuite.
  - Capture et élimination de la proie au contact du prédateur.
- **Épidémiologie** : Modèle de diffusion épidémique chez les agents (proies et prédateurs).
- **Évolution & Mutations** :
  - Comportement adaptatif des agents.
  - Système de mutations rendant les agents plus redoutables (modification du taux de reproduction, de la vitesse, du risque de mortalité, etc.).
- **Équilibrage** : Mécanismes d'équilibrage du système visant à éviter l'extinction complète des espèces.

---

## Contrôles

### Météo et Environnement
- **M** (`manual`) : Active / désactive le mode météo manuel (mode automatique par défaut).
- **R** (`rain`) : Déclenche / arrête la pluie (lorsque le mode manuel est activé).
- **F** (`stop_fire`) : Déclenche / arrête les incendies de forêt (lorsque le mode manuel est activé).

### Caméra
- **Déplacements :**
  - **Z** (`move_forward`) : Avancer
  - **S** (`move_back`) : Reculer
  - **Q** (`move_left`) : Aller à gauche
  - **D** (`move_right`) : Aller à droite
  - **Espace** (`move_up`) : Monter
  - **Maj + Espace** (`move_down`) : Descendre
- **Rotation :**
  - **Haut / Bas / Gauche / Droite** (`rotate_up`, `rotate_down`, `rotate_left`, `rotate_right`) : Orienter la caméra
- **Zoom :**
  - **A** (`zoom_in`) : Zoomer
  - **E** (`zoom_out`) : Dézoomer

---

## Installation et Lancement

### Prérequis

- **Godot Engine v4.6.2 (stable)** : https://godotengine.org/download/archive/4.6.2-stable
- **Git**

### Instructions

1. **Cloner le dépôt Git :**
   ```bash
   git clone https://github.com/meowredstar/lou-et-jyothi.git
   cd lou-et-jyothi
   ```

2. **Ouvrir le projet dans Godot :**
   - Lancez **Godot Engine**.
   - Cliquez sur **Importer**.
   - Sélectionnez le fichier `project.godot` situé dans le sous-dossier `wokeworld`.

3. **Lancer la simulation :**
   - **Mode Debug** : Appuyez sur la touche `F5` dans le moteur Godot.
   - **Version Compilée** : 
     - Vous pouvez exporter le projet via `Projet > Exporter sous... > Windows/Linux`.
     - Vous pouvez également exécuter le fichier binaire prêt à l'emploi situé dans le dossier `exec/` du dépôt.

---

## Autrices

- **Lou Eouzan**
- **Jyothi Marigot**
