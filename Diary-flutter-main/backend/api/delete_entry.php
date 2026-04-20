<?php
require_once '../config/database.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['entry_id']) || !isset($data['user_id'])) {
    echo json_encode(['success' => false, 'message' => 'Entry ID and User ID required']);
    exit();
}

$stmt = $pdo->prepare("DELETE FROM diary_entries WHERE id = ? AND user_id = ?");
$stmt->execute([$data['entry_id'], $data['user_id']]);

if ($stmt->rowCount() > 0) {
    echo json_encode(['success' => true, 'message' => 'Entry deleted successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Entry not found or unauthorized']);
}
?>