<?php
require_once '../config/database.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['user_id']) || !isset($data['title']) || !isset($data['content'])) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit();
}

$user_id = $data['user_id'];
$title = $data['title'];
$content = $data['content'];
$date = $data['date'] ?? date('Y-m-d');
$tags = json_encode($data['tags'] ?? []);
$images = json_encode($data['images'] ?? []);
$audios = json_encode($data['audios'] ?? []);
$is_favorite = $data['is_favorite'] ?? 0;

try {
    $stmt = $pdo->prepare("INSERT INTO diary_entries (user_id, title, content, date, tags, images, audios, is_favorite) 
                           VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->execute([$user_id, $title, $content, $date, $tags, $images, $audios, $is_favorite]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Entry saved successfully',
        'entry_id' => $pdo->lastInsertId()
    ]);
} catch(PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Failed to save entry: ' . $e->getMessage()]);
}
?>