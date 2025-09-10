# 📋 Références de Modèles Odoo 15 - Stock Scan Mobile

## ✅ **Modèles Vérifiés et Utilisés**

### **Modèles Stock (Module stock)**
- `stock.model_stock_picking` ✅
- `stock.model_stock_move` ✅
- `stock.model_stock_move_line` ✅
- `stock.model_stock_production_lot` ✅
- `stock.model_stock_quant` ✅
- `stock.model_stock_location` ✅
- `stock.model_stock_picking_type` ✅

### **Modèles Product (Module product)**
- `product.model_product_product` ✅
- `product.model_product_template` ✅

### **Modèles Base (Module base)**
- `base.model_res_partner` ✅

## ❌ **Modèles Supprimés (Problématiques)**

### **UOM (Unité de Mesure)**
- ~~`uom.model_uom`~~ ❌ (Référence incorrecte)
- ~~`uom.model_uom_uom`~~ ❌ (Non nécessaire pour l'API mobile)

### **Configuration Parameters**
- ~~`base.model_ir_config_parameter`~~ ❌ (Accès non nécessaire pour utilisateurs mobiles)

## 🔧 **Groupes de Sécurité**

### **Groupes Créés**
- `group_mobile_user` - Utilisateurs mobiles
- `group_mobile_manager` - Gestionnaires mobiles

### **Catégorie de Module**
- **Supprimée** pour éviter les erreurs de référence
- Les groupes sont créés sans catégorie spécifique

## 📝 **Permissions par Groupe**

### **Mobile User (group_mobile_user)**
- **Lecture** : Tous les modèles stock, product, partner
- **Écriture** : stock.picking, stock.move
- **Création** : stock.move.line, stock.production.lot
- **Suppression** : stock.move.line uniquement

### **Mobile Manager (group_mobile_manager)**
- **Lecture** : Tous les modèles
- **Écriture** : Tous les modèles (sauf quant, location)
- **Création** : Tous les modèles (sauf quant, location)
- **Suppression** : stock.picking, stock.move, stock.move.line, stock.production.lot

## 🚀 **Installation Sans Erreurs**

Avec ces corrections, le module s'installe maintenant sans erreurs :

1. ✅ **Pas d'erreurs de références externes**
2. ✅ **Pas d'erreurs de modèles manquants**
3. ✅ **Pas d'erreurs de catégories**
4. ✅ **Ordre de chargement correct**

## 🧪 **Test des Permissions**

Pour tester les permissions après installation :

```python
# Dans Odoo shell
user = env['res.users'].search([('login', '=', 'mobile_user')])
user.has_group('stock_scan_mobile.group_mobile_user')  # True
user.has_group('stock_scan_mobile.group_mobile_manager')  # False (sauf si assigné)
```

## 📚 **Références Utiles**

### **Commandes de Vérification**
```bash
# Vérifier les modèles disponibles
grep -r "model_" /opt/odoo/addons/stock/security/
grep -r "model_" /opt/odoo/addons/product/security/
grep -r "model_" /opt/odoo/addons/base/security/
```

### **Structure des Fichiers**
```
stock_scan_mobile/
├── security/
│   ├── security.xml          # Groupes (chargé en premier)
│   └── ir.model.access.csv    # Permissions (chargé après)
├── data/
│   └── ir_config_parameter.xml # Configuration
└── __manifest__.py            # Ordre de chargement
```

## ✅ **Module Prêt pour Production**

Le module est maintenant stable et peut être installé en production sans erreurs de sécurité ou de références.
