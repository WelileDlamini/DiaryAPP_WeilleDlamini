<?php
require_once '../config/database.php';

$user_id = $_GET['user_id'] ?? null;

if (!$user_id) {
    echo json_encode(['success' => false, 'message' => 'User ID required']);
    exit();
}

$stmt = $pdo->prepare("SELECT id, title, content, date, tags, images, audios, is_favorite, created_at 
                       FROM diary_entries 
                       WHERE user_id = ? 
                       ORDER BY date DESC");
$stmt->execute([$user_id]);
$entries = $stmt->fetchAll();

foreach ($entries as &$entry) {
    $entry['tags'] = json_decode($entry['tags'], true) ?: [];
    $entry['images'] = json_decode($entry['images'], true) ?: [];
    $entry['audios'] = json_decode($entry['audios'], true) ?: [];
}

echo json_encode([
    'success' => true,
    'entries' => $entries
]);
?>