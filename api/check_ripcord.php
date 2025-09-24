<?php
echo "Checking Ripcord files:\n";
$ripcord_dir = __DIR__ . '/../';
$files = scandir($ripcord_dir);
foreach ($files as $file) {
    if (strpos($file, 'ripcord') !== false) {
        echo "Found: $file\n";
    }
}

echo "\nLooking for transport files:\n";
$transport_file = $ripcord_dir . 'ripcord_transport/stream.php';
if (file_exists($transport_file)) {
    echo "Transport stream file exists\n";
} else {
    echo "Transport stream file MISSING\n";
}
?>