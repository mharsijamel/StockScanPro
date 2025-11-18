<?php
class TokenManager {

    public static function generateToken(string $username, array $credentials): string {
        $tokens = self::loadTokens();
        $token = bin2hex(random_bytes(32));
        
        $tokens[$token] = [
            'user' => $username,
            'credentials' => $credentials, // Stocke les identifiants pour les réutiliser
            'expires_at' => time() + TOKEN_EXPIRATION_TIME
        ];

        self::saveTokens($tokens);
        return $token;
    }

    public static function getCredentials(string $token): ?array {
        $tokens = self::loadTokens();
        if (!isset($tokens[$token])) {
            return null;
        }

        if (time() > $tokens[$token]['expires_at']) {
            // Token expiré, on le supprime
            unset($tokens[$token]);
            self::saveTokens($tokens);
            return null;
        }

        return $tokens[$token]['credentials'];
    }

    private static function loadTokens(): array {
        if (!file_exists(TOKEN_STORAGE_FILE)) {
            return [];
        }
        $json = file_get_contents(TOKEN_STORAGE_FILE);
        return json_decode($json, true) ?: [];
    }

    private static function saveTokens(array $tokens): void {
        file_put_contents(TOKEN_STORAGE_FILE, json_encode($tokens, JSON_PRETTY_PRINT));
    }
}
