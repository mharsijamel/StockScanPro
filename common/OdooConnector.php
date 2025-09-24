<?php
require_once __DIR__ . '/../vendor/autoload.php';

use PhpXmlRpc\Client;
use PhpXmlRpc\Request;
use PhpXmlRpc\Value;
use PhpXmlRpc\Encoder;

class OdooConnector {
    private $url;
    private $db;
    private $username;
    private $password;
    private $uid;

    public function __construct($url, $db, $username, $password) {
        $this->url = $url;
        $this->db = $db;
        $this->username = $username;
        $this->password = $password;
    }

    public function connect() {
        $client = new Client($this->url . "/xmlrpc/2/common");
        $request = new Request('authenticate', [
            new Value($this->db, 'string'),
            new Value($this->username, 'string'),
            new Value($this->password, 'string'),
            new Value([], 'struct')
        ]);

        $response = $client->send($request);

        if ($response->faultCode()) {
            return false;
        }

        $this->uid = $response->value()->scalarval();
        return $this->uid;
    }

    public function execute_kw($model, $method, $args = [], $kwargs = []) {
        if (!$this->uid) {
            return false;
        }

        $client = new Client($this->url . "/xmlrpc/2/object");
        
        // Use Encoder for automatic conversion
        $encoder = new \PhpXmlRpc\Encoder();
        
        $request = new Request('execute_kw', [
            new Value($this->db, 'string'),
            new Value($this->uid, 'int'),
            new Value($this->password, 'string'),
            new Value($model, 'string'),
            new Value($method, 'string'),
            $encoder->encode($args),
            $encoder->encode($kwargs)
        ]);

        $response = $client->send($request);

        if ($response->faultCode()) {
            error_log("Odoo API Error: " . $response->faultString());
            return false;
        }
        
        return json_decode(json_encode($response->value()), true);
    }
}


