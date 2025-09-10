# 🚀 Installation FINALE - Stock Scan Mobile (Version Simplifiée)

## ✅ **Version Ultra-Simplifiée - Sans Erreurs**

Cette version a été simplifiée au maximum pour éviter toute erreur d'installation :

### **Corrections Finales :**
- ✅ **Fichiers de données** : Supprimés (évite les erreurs XML)
- ✅ **Paramètres de configuration** : Supprimés des doublons
- ✅ **Références de modèles** : Vérifiées et simplifiées
- ✅ **Groupes de sécurité** : Sans catégorie (évite les erreurs de référence)

## 📋 **Installation en 4 étapes**

### **1. Copier le module**
```bash
cp -r stock_scan_mobile /opt/odoo/addons/
```

### **2. Redémarrer Odoo**
```bash
sudo systemctl restart odoo
```

### **3. Installer le module**
1. **Apps** → **Update Apps List**
2. Rechercher **"Stock Scan Mobile"**
3. Cliquer **Install**

### **4. Configurer les utilisateurs**
1. **Paramètres** → **Utilisateurs**
2. Ajouter les groupes :
   - **Mobile App User**
   - **Mobile App Manager**

## 🧪 **Test de l'installation**

### **API Health Check**
```bash
curl -X GET "http://your-odoo-url:8069/api/health"
```

**Réponse attendue :**
```json
{
  "success": true,
  "status": "healthy",
  "message": "Stock Scan Mobile API is running"
}
```

### **Test d'authentification**
```bash
curl -X POST "http://your-odoo-url:8069/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin"
  }'
```

## 📱 **Configuration de l'app mobile**

1. **Ouvrir l'app** StockScan Pro
2. **Menu utilisateur** → **Configuration**
3. **Saisir l'URL** Odoo : `http://your-odoo-url:8069`
4. **Tester la connexion**

## 🎯 **Fonctionnalités disponibles**

### **API Endpoints :**
- `GET /api/health` - Vérification de santé
- `POST /api/auth/login` - Authentification
- `GET /api/pickings` - Liste des opérations stock
- `POST /api/serial/check` - Vérification numéro de série
- `POST /api/pickings/{id}/update_sn` - Mise à jour des numéros de série

### **Groupes de sécurité :**
- **Mobile App User** - Utilisateurs mobiles (lecture/écriture limitée)
- **Mobile App Manager** - Gestionnaires (accès complet)

### **Modèles supportés :**
- Stock Picking (Opérations de stock)
- Stock Move (Mouvements de stock)
- Stock Move Line (Lignes de mouvement)
- Stock Production Lot (Numéros de série)
- Product (Produits)

## ✅ **Module Prêt !**

Le module est maintenant installé et fonctionnel. Vous pouvez :

1. **Configurer les produits** avec suivi par numéro de série
2. **Connecter l'app mobile** à votre serveur Odoo
3. **Commencer à scanner** les numéros de série
4. **Gérer les opérations** Stock IN/OUT depuis l'app

## 🔧 **Configuration des produits**

Pour utiliser les numéros de série :

1. **Inventaire** → **Produits**
2. Sélectionner un produit
3. **Onglet Inventaire** → **Traçabilité**
4. Choisir **"Par numéro de série unique"**

## 🎉 **Installation Terminée !**

Le module Stock Scan Mobile est maintenant opérationnel et prêt à être utilisé avec l'application mobile !
