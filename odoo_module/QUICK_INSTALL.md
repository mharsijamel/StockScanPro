# 🚀 Installation Rapide - Stock Scan Mobile

## ✅ **Erreurs Corrigées**

- **Ordre de chargement** : `security.xml` avant `ir.model.access.csv`
- **Catégorie de module** : Supprimée (évite les erreurs de référence)
- **Hook post_init** : Supprimé (non nécessaire)
- **Références de modèles** : Corrigées dans `ir.model.access.csv`
- **Modèle UOM** : Référence incorrecte supprimée

## 📋 **Installation en 5 étapes**

### **1. Copier le module**
```bash
# Copiez le dossier stock_scan_mobile dans votre répertoire addons
cp -r stock_scan_mobile /opt/odoo/addons/
# ou
cp -r stock_scan_mobile /path/to/your/odoo/addons/
```

### **2. Redémarrer Odoo**
```bash
sudo systemctl restart odoo
# ou
sudo service odoo restart
```

### **3. Mettre à jour la liste des modules**
1. Connectez-vous à Odoo en tant qu'administrateur
2. Allez dans **Apps**
3. Cliquez sur **Update Apps List**

### **4. Installer le module**
1. Recherchez "Stock Scan Mobile"
2. Cliquez sur **Install**
3. ✅ **L'installation devrait maintenant réussir !**

### **5. Configurer les utilisateurs**
1. **Paramètres** → **Utilisateurs et Entreprises** → **Utilisateurs**
2. Sélectionnez un utilisateur
3. Dans **Droits d'accès**, ajoutez :
   - **Mobile App User** (utilisateurs mobiles)
   - **Mobile App Manager** (administrateurs)

## 🧪 **Test rapide**

### **Test de l'API Health**
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

## 🎯 **Prochaines étapes**

1. **Configurer l'app mobile** avec l'URL de votre serveur Odoo
2. **Tester la connexion** depuis l'application mobile
3. **Configurer les produits** avec suivi par numéro de série
4. **Former les utilisateurs** sur l'utilisation de l'app

## 🔧 **Configuration des produits**

Pour utiliser les numéros de série :

1. **Inventaire** → **Produits** → **Produits**
2. Sélectionnez un produit
3. Onglet **Inventaire** → **Traçabilité**
4. Sélectionnez **"Par numéro de série unique"**

## 📱 **Configuration de l'app mobile**

1. Ouvrez l'app StockScan Pro sur votre téléphone
2. Menu utilisateur → **Configuration**
3. Saisissez l'URL de votre serveur Odoo
4. Testez la connexion

## ✅ **Module prêt à l'emploi !**

Le module est maintenant installé et configuré. Vous pouvez commencer à utiliser l'application mobile pour scanner les numéros de série !
