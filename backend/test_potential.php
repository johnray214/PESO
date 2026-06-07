<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

try {
    $request = new \Illuminate\Http\Request();
    $controller = new \App\Http\Controllers\Api\Admin\AdminApplicationController();
    $response = $controller->potentialApplicants($request);
    $body = $response->getContent();
    $json = json_decode($body, true);
    if ($json && isset($json['data'])) {
        echo "SUCCESS - " . count($json['data']) . " potential applicants found.\n";
    } else {
        echo "Response: " . substr($body, 0, 500) . "\n";
    }
} catch (\Throwable $e) {
    echo get_class($e) . ": " . $e->getMessage() . "\n";
    echo "File: " . $e->getFile() . ":" . $e->getLine() . "\n";
    echo "\nTrace:\n" . $e->getTraceAsString() . "\n";
}
