# 🗄️ Fonctionnalité Multi-Bases de Données - StockScan Pro

## 🎯 **Problème résolu**

Quand une instance Odoo possède **plusieurs bases de données**, l'utilisateur doit pouvoir :
1. **Voir la liste** des bases disponibles
2. **Sélectionner** la base appropriée
3. **Changer facilement** de base si nécessaire

## ✅ **Solution implémentée**

### **1. Détection automatique**
- L'app détecte automatiquement si le serveur a une ou plusieurs bases
- Si **une seule base** → Configuration automatique
- Si **plusieurs bases** → Écran de sélection

### **2. Service de gestion des bases de données**
**Fichier:** `lib/services/database_selection_service.dart`

**Fonctionnalités:**
- ✅ Récupération de la liste des bases via API
- ✅ Test de connexion pour chaque base
- ✅ Détection du nombre de bases
- ✅ Gestion des erreurs et fallbacks

**Endpoints utilisés:**
1. `/api/databases` (notre endpoint personnalisé)
2. `/web/database/list` (endpoint standard Odoo)
3. Parsing HTML en fallback

### **3. Écran de sélection interactif**
**Fichier:** `lib/screens/database_selection_screen.dart`

**Interface utilisateur:**
- ✅ Liste des bases disponibles
- ✅ Sélection par radio buttons
- ✅ Informations sur le serveur
- ✅ Test de connexion automatique
- ✅ Gestion des erreurs avec retry
- ✅ Interface moderne et intuitive

### **4. Configuration dynamique**
**Fichier:** `lib/config/app_config.dart`

**Nouvelles fonctionnalités:**
- ✅ Stockage de la base sélectionnée
- ✅ Configuration par environnement
- ✅ Méthodes de gestion (set, clear, get)

### **5. Intégration API**
**Fichier:** `lib/services/api_service.dart`

**Améliorations:**
- ✅ Header `X-Openerp-Database` automatique
- ✅ Utilisation de la base sélectionnée
- ✅ Compatibilité avec toutes les requêtes

### **6. Interface utilisateur améliorée**
**Fichier:** `lib/screens/settings_screen.dart`

**Nouvelles fonctionnalités:**
- ✅ Affichage de la base sélectionnée
- ✅ Bouton "Changer" pour modifier la base
- ✅ Carte d'information bleue
- ✅ Workflow automatique lors de la configuration

### **7. Endpoint Odoo personnalisé**
**Fichier:** `odoo_module/stock_scan_mobile/controllers/health_controller.py`

**Nouveaux endpoints:**
- ✅ `/api/health` - Test de santé du serveur
- ✅ `/api/databases` - Liste des bases disponibles
- ✅ Headers CORS configurés
- ✅ Gestion des erreurs

## 🔄 **Workflow utilisateur**

### **Cas 1: Première configuration**
1. Utilisateur saisit l'URL du serveur
2. App détecte automatiquement les bases disponibles
3. **Si plusieurs bases** → Écran de sélection s'ouvre
4. Utilisateur sélectionne la base appropriée
5. Test de connexion automatique
6. Configuration sauvegardée

### **Cas 2: Changement de base**
1. Utilisateur va dans Configuration
2. Voit la base actuelle dans la carte bleue
3. Clique sur "Changer"
4. Écran de sélection s'ouvre
5. Sélectionne une nouvelle base
6. Configuration mise à jour

### **Cas 3: Une seule base**
1. Utilisateur saisit l'URL du serveur
2. App détecte une seule base
3. Configuration automatique
4. Pas d'intervention nécessaire

## 🛠️ **Aspects techniques**

### **Headers HTTP**
```http
X-Openerp-Database: nom-de-la-base
Content-Type: application/json
Authorization: Bearer token
```

### **Endpoints API**
```bash
# Santé du serveur
GET /api/health

# Liste des bases
GET /api/databases

# Authentification avec base
POST /api/auth/login
Headers: X-Openerp-Database: ma-base
```

### **Configuration stockée**
```dart
AppConfig.setSelectedDatabase('production');
AppConfig.selectedDatabase; // 'production'
AppConfig.clearSelectedDatabase();
```

## 🎨 **Interface utilisateur**

### **Écran de sélection**
- **Header:** Titre et URL du serveur
- **Liste:** Radio buttons pour chaque base
- **Actions:** Boutons Annuler/Sélectionner
- **États:** Loading, erreur, succès

### **Écran de configuration**
- **Carte bleue:** Base sélectionnée + bouton Changer
- **URL:** Champ de saisie du serveur
- **Actions:** Réinitialiser/Sauvegarder

## 🧪 **Tests**

### **Scénarios testés**
- ✅ Serveur avec une seule base
- ✅ Serveur avec plusieurs bases
- ✅ Serveur inaccessible
- ✅ Bases de données inaccessibles
- ✅ Changement de base
- ✅ Réinitialisation de configuration

### **Endpoints testés**
- ✅ `/api/health` - Santé du serveur
- ✅ `/api/databases` - Liste des bases
- ✅ `/web/database/list` - Fallback Odoo
- ✅ Parsing HTML en dernier recours

## 📋 **Avantages**

### **Pour l'utilisateur**
- ✅ **Simplicité** - Détection automatique
- ✅ **Flexibilité** - Changement facile de base
- ✅ **Clarté** - Affichage de la base sélectionnée
- ✅ **Fiabilité** - Test de connexion automatique

### **Pour le développeur**
- ✅ **Robustesse** - Multiples fallbacks
- ✅ **Maintenabilité** - Code modulaire
- ✅ **Extensibilité** - Facile à étendre
- ✅ **Compatibilité** - Fonctionne avec toutes versions Odoo

## 🚀 **Utilisation**

### **Configuration simple**
```dart
// L'utilisateur saisit juste l'URL
// Tout le reste est automatique !
AppConfig.setManualBaseUrl('https://company.odoo.com');
```

### **Gestion programmatique**
```dart
// Vérifier s'il y a plusieurs bases
final hasMultiple = !await dbService.hasSingleDatabase(url);

// Récupérer la liste
final databases = await dbService.getDatabaseList(url);

// Tester une base spécifique
final isAccessible = await dbService.testDatabaseConnection(url, 'prod');
```

## 🎉 **Résultat**

**L'application gère maintenant parfaitement les instances Odoo avec plusieurs bases de données !**

- ✅ **Détection automatique** du nombre de bases
- ✅ **Interface intuitive** de sélection
- ✅ **Configuration flexible** et persistante
- ✅ **Compatibilité totale** avec Odoo 15+
- ✅ **Expérience utilisateur** optimale

**Plus besoin de configuration manuelle complexe - tout est automatique ! 🚀**
