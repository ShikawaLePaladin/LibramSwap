# LibramSwap - Addon WoW Vanilla/Turtle

**LibramSwap** est un addon pour World of Warcraft 1.12 (Vanilla/Turtle WoW) qui équipe automatiquement le bon libram quand vous lancez des sorts de Paladin.

## 📋 Fonctionnalités

- ✅ **Changement automatique de libram** avant de lancer un sort
- ✅ **Système de profils** pour sauvegarder différentes configurations
- ✅ **Gestion des sorts** via le Sorts Manager (Add/Remove)
- ✅ **Indicateurs visuels** (vert = libram dans les sacs, rouge = manquant)
- ✅ **Chargement automatique** du dernier profil utilisé à la connexion
- ✅ **Interface intuitive** avec dropdowns et checkboxes

## 🎮 Installation

1. Téléchargez l'addon (bouton vert "Code" → "Download ZIP")
2. Extrayez le dossier `Libramswap-main`
3. Renommez-le en `LibramSwap`
4. Placez-le dans : `World of Warcraft/Interface/AddOns/LibramSwap`
5. Redémarrez WoW ou tapez `/reload` en jeu

## ⌨️ Commandes

| Commande | Description |
|----------|-------------|
| `/libramconfig` | Ouvre/ferme le menu de configuration |
| `/libramswap` | Active/désactive l'addon |
| `/libramprofile` | Affiche le profil actuellement actif |
| `/libramdebug on/off` | Active/désactive les messages de debug |
| `/swaplibram <Sort>` | Test manuel du swap pour un sort |
| `/equiplibram <Nom>` | Équipe un libram manuellement |

## 📖 Guide d'utilisation

### 1️⃣ Premier lancement

Après installation, tapez `/libramconfig` pour ouvrir le menu.

### 2️⃣ Ajouter des sorts à configurer

1. Cliquez sur le bouton **"Sorts"** (en haut à droite)
2. Recherchez un sort dans la liste (ex: "Holy Light")
3. Cliquez sur **"Add"** pour l'ajouter à votre configuration
4. Répétez pour tous vos sorts importants

### 3️⃣ Choisir les librams

1. Dans la configuration principale, cliquez sur le bouton à côté du nom du sort
2. Sélectionnez le libram que vous voulez équiper pour ce sort
3. L'indicateur devient **vert** si vous avez le libram dans vos sacs

### 4️⃣ Sauvegarder un profil

1. Cliquez sur **"Save"** (en haut à droite)
2. Tapez un nom de profil (ex: "Heal", "Tank", "PvP")
3. Cliquez **"Create"** ou **"Save"**
4. Votre configuration est maintenant sauvegardée !

### 5️⃣ Charger un profil

1. Cliquez sur **"Save"** pour ouvrir le gestionnaire de profils
2. Cliquez sur un profil dans la liste
3. Cliquez **"Load"**
4. Le profil se charge automatiquement à la prochaine connexion

### 6️⃣ Supprimer des sorts

1. Cliquez sur **"Sorts"**
2. Trouvez le sort à supprimer
3. Cliquez sur **"Remove"**
4. Le sort disparaît de la configuration

## 🔧 Options avancées

### Délai de swap
- Ajustez le délai entre le changement de libram et le lancement du sort
- Valeur recommandée : **0.02 secondes**

### Debug
- Activez pour voir tous les messages détaillés dans le chat
- Utile pour diagnostiquer les problèmes

## 🎯 Sorts supportés

L'addon supporte tous les sorts de Paladin, notamment :
- Holy Light / Flash of Light
- Holy Shield / Holy Strike
- Consecration
- Cleanse
- Blessings (Wisdom, Might, Kings, etc.)
- Seals (Righteousness, Crusader, Wisdom, etc.)
- Judgement
- Hand of Freedom
- Hammer of Justice

## 📦 Librams supportés

- Libram of the Faithful
- Libram of the Farraki Zealot
- Libram of Radiance
- Libram of Light
- Libram of Grace
- Libram of the Dreamguard
- Libram of the Justicar
- Libram of the Resolute
- Libram of the Eternal Tower
- Libram of Final Judgement
- Libram of Hope
- Libram of Fervor
- Libram of Truth
- Libram of Veracity
- Libram of Divinity

## ❓ FAQ

**Q : L'addon ne charge pas mes librams à la connexion ?**  
R : Assurez-vous d'avoir cliqué "Save" après avoir configuré vos sorts. Le profil doit être sauvegardé pour se charger automatiquement.

**Q : Les dropdowns sont vides après `/reload` ?**  
R : Cela signifie que le profil a été créé avant d'avoir configuré les librams. Configurez vos sorts, puis cliquez "Save" pour écraser le profil.

**Q : Comment savoir quel profil est actif ?**  
R : Tapez `/libramprofile` pour voir le profil actif et le nombre de sorts configurés.

**Q : L'addon ne swap pas en combat ?**  
R : Par sécurité, l'addon ne swap pas si votre curseur a un objet, ou si une fenêtre de transaction est ouverte.

**Q : Comment créer plusieurs profils (Heal/Tank/PvP) ?**  
R : Configurez vos sorts pour un rôle, sauvegardez le profil avec un nom (ex: "Heal"). Changez la configuration, sauvegardez avec un autre nom (ex: "Tank"). Chargez le profil voulu selon la situation.

## 🐛 Problèmes connus

- Le swap peut échouer si vous spammez le sort trop rapidement (utilisez le délai)
- Certains librams nécessitent un nom exact (sensible à la casse)

## 👨‍💻 Développement

Ce projet est open-source. Les contributions sont les bienvenues !

### Structure des fichiers
- `LibramSwap_fixed.lua` : Logique principale du swap
- `LibramSwapConfig.lua` : Interface utilisateur (Configuration, Profils, Sorts Manager)
- `LibramSwap.toc` : Manifeste de l'addon

## 📜 Licence

Libre d'utilisation et de modification.

## 🙏 Remerciements

Merci à la communauté Turtle WoW pour leurs retours et suggestions !

---

**Version** : 1.0  
**Auteur** : Theo  
**Compatibilité** : WoW 1.12 (Vanilla) / Turtle WoW
