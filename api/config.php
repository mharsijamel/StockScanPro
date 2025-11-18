<?php
// Durée de validité du token en secondes (ici, 24 heures)
define('TOKEN_EXPIRATION_TIME', 24 * 3600); 

// Fichier pour stocker les tokens (pour cet exemple, un simple fichier JSON)
define('TOKEN_STORAGE_FILE', __DIR__ . '/tokens.json');
