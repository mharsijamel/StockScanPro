# 🔧 Guide de Configuration - StockScan Pro

## 📱 Configuration de l'URL du serveur Odoo

### Option 1: Configuration via l'application mobile

1. **Ouvrir l'application** StockScan Pro
2. **Se connecter** avec les identifiants demo (ou vos identifiants)
3. **Accéder au menu utilisateur** (icône profil en haut à droite)
4. **Sélectionner "Configuration"**
5. **Saisir l'URL de votre serveur Odoo** :
   - Format: `https://your-company.odoo.com`
   - Ou: `http://localhost:8069` (pour développement local)
6. **Cliquer "Sauvegarder"**
7. **Si plusieurs bases de données** → Écran de sélection automatique
8. **Sélectionner la base de données** appropriée
9. **Test automatique** de la connexion

### 🗄️ Gestion des bases de données multiples

**Cas 1: Une seule base de données**
- Configuration automatique
- Pas de sélection nécessaire

**Cas 2: Plusieurs bases de données**
- Écran de sélection automatique
- Liste des bases disponibles
- Possibilité de changer ultérieurement

**Fonctionnalités:**
- ✅ **Détection automatique** du nombre de bases
- ✅ **Sélection interactive** avec interface dédiée
- ✅ **Test de connexion** pour chaque base
- ✅ **Changement facile** via le bouton "Changer"
- ✅ **Affichage** de la base sélectionnée

### Option 2: Configuration dans le code

Modifiez le fichier `lib/constants/app_constants.dart` :

```dart
// API Configuration
static const String baseUrl = 'https://your-odoo-instance.com';
```

### Option 3: Configuration par environnement

Le fichier `lib/config/app_config.dart` permet de configurer différentes URLs selon l'environnement :

```dart
// Mode développement (Debug)
static const String _devBaseUrl = 'http://localhost:8069';

// Mode staging/test (Profile)
static const String _stagingBaseUrl = 'https://staging.your-odoo.com';

// Mode production (Release)
static const String _prodBaseUrl = 'https://your-odoo.com';
```

## 🌐 URLs communes pour Odoo

### Développement local
- `http://localhost:8069`
- `http://127.0.0.1:8069`
- `http://192.168.1.100:8069` (remplacez par votre IP locale)

### Odoo.com (SaaS)
- `https://your-company.odoo.com`
- `https://your-database.odoo.com`

### Serveur dédié
- `https://your-domain.com`
- `https://erp.your-company.com`
- `http://your-server-ip:8069`

## 🔐 Configuration du module Odoo

### 1. Installation du module

1. **Copier le dossier** `odoo_module/stock_scan_mobile` dans votre répertoire addons Odoo
2. **Redémarrer Odoo** avec `--update=all` ou via l'interface
3. **Aller dans Apps** → Rechercher "Stock Scan Mobile"
4. **Installer le module**

### 2. Configuration des utilisateurs

1. **Aller dans Paramètres** → Utilisateurs et Entreprises → Utilisateurs
2. **Sélectionner un utilisateur**
3. **Dans l'onglet "Droits d'accès"**, ajouter les groupes :
   - `Mobile User` - Pour les utilisateurs mobiles
   - `Mobile Manager` - Pour les gestionnaires (optionnel)

### 3. Configuration des produits

1. **Aller dans Inventaire** → Produits → Produits
2. **Sélectionner un produit**
3. **Dans l'onglet "Inventaire"**, section **Traçabilité** :
   - ✅ Cocher **"Par numéro de série unique"**
4. **Sauvegarder**

## 🗄️ Configuration des bases de données multiples

### Scénarios courants

**1. Serveur avec une seule base de données**
```
https://your-company.odoo.com → Base unique → Configuration automatique
```

**2. Serveur avec plusieurs bases de données**
```
https://your-company.odoo.com → [production, test, dev] → Sélection requise
```

**3. Instance Odoo.com avec plusieurs environnements**
```
https://your-company.odoo.com → [live, staging] → Sélection requise
```

### Processus de sélection

1. **Saisie de l'URL** du serveur
2. **Détection automatique** du nombre de bases
3. **Si plusieurs bases** :
   - Ouverture automatique de l'écran de sélection
   - Liste des bases disponibles
   - Sélection par radio button
   - Test de connexion pour la base sélectionnée
4. **Si une seule base** :
   - Configuration automatique
   - Pas d'intervention utilisateur

### Gestion dans l'interface

**Affichage de la base sélectionnée:**
- Carte bleue dans l'écran de configuration
- Nom de la base de données affiché
- Bouton "Changer" pour modifier

**Changement de base de données:**
1. Aller dans Configuration
2. Cliquer sur "Changer" dans la carte bleue
3. Sélectionner une nouvelle base
4. Confirmation automatique

## 🧪 Test de la configuration

### Test de connexion API

Utilisez curl pour tester la connexion :

```bash
# Test de santé (nouveau endpoint)
curl -X GET "http://your-odoo-url:8069/api/health"

# Test de liste des bases de données
curl -X GET "http://your-odoo-url:8069/api/databases"

# Test d'authentification avec base de données
curl -X POST "http://your-odoo-url:8069/api/auth/login" \
  -H "Content-Type: application/json" \
  -H "X-Openerp-Database: your-database-name" \
  -d '{
    "username": "admin",
    "password": "admin"
  }'
```

### Test via l'application

1. **Ouvrir l'app** StockScan Pro
2. **Aller dans Configuration** (menu utilisateur)
3. **Saisir l'URL** de votre serveur
4. **Cliquer "Sauvegarder"**
5. **Vérifier le message** de confirmation

## 🚨 Résolution des problèmes

### Erreur de connexion

**Problème**: "Erreur de connexion réseau"
**Solutions**:
- Vérifier que l'URL est correcte
- Vérifier que le serveur Odoo est accessible
- Vérifier les paramètres réseau/firewall
- Tester avec curl depuis le même réseau

### Module non trouvé

**Problème**: "Module stock_scan_mobile non installé"
**Solutions**:
- Vérifier que le module est dans le répertoire addons
- Redémarrer Odoo avec `--update=all`
- Vérifier les logs Odoo pour les erreurs d'installation

### Erreur d'authentification

**Problème**: "Erreur d'authentification"
**Solutions**:
- Vérifier les identifiants utilisateur
- Vérifier que l'utilisateur a les bons groupes d'accès
- Vérifier que le module est installé et activé

### Produit non trouvé

**Problème**: "Produit non configuré pour le suivi par numéro de série"
**Solutions**:
- Aller dans Inventaire → Produits
- Sélectionner le produit
- Activer "Par numéro de série unique" dans l'onglet Inventaire

## 📋 Checklist de configuration

### ✅ Serveur Odoo
- [ ] Odoo 15 installé et fonctionnel
- [ ] Module `stock_scan_mobile` installé
- [ ] Utilisateurs configurés avec les bons groupes
- [ ] Produits configurés avec suivi par numéro de série

### ✅ Application Mobile
- [ ] URL du serveur configurée
- [ ] Test de connexion réussi
- [ ] Authentification fonctionnelle
- [ ] Navigation dans l'app opérationnelle

### ✅ Tests d'intégration
- [ ] Login/logout fonctionnel
- [ ] Récupération des pickings
- [ ] Scan des numéros de série
- [ ] Synchronisation des données

## 🔧 Configuration avancée

### Variables d'environnement

Vous pouvez utiliser des variables d'environnement pour la configuration :

```bash
export ODOO_URL="https://your-odoo.com"
export ODOO_DB="your-database"
export ODOO_USERNAME="admin"
export ODOO_PASSWORD="admin"
```

### Configuration HTTPS

Pour la production, utilisez toujours HTTPS :

```dart
static const String baseUrl = 'https://your-secure-odoo.com';
```

### Configuration CORS

Le module inclut la configuration CORS automatique, mais vous pouvez l'ajuster dans :
`odoo_module/stock_scan_mobile/controllers/auth_controller.py`

---

## 📞 Support

Si vous rencontrez des problèmes :

1. **Vérifiez les logs** Odoo pour les erreurs
2. **Testez la connexion** avec curl
3. **Vérifiez la configuration** des utilisateurs et produits
4. **Consultez la documentation** API dans `API_TESTING.md`

La configuration est maintenant flexible et permet de s'adapter à différents environnements ! 🚀
