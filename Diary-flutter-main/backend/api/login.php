<?php
require_once '../config/database.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['email']) || !isset($data['password'])) {
    echo json_encode(['success' => false, 'message' => 'Email and password required']);
    exit();
}

$email = trim($data['email']);
$password = $data['password'];

$stmt = $pdo->prepare("SELECT id, username, email, password_hash, profile_image FROM users WHERE email = ?");
$stmt->execute([$email]);
$user = $stmt->fetch();

if ($user && password_verify($password, $user['password_hash'])) {
    echo json_encode([
        'success' => true,
        'message' => 'Login successful',
        'user_id' => $user['id'],
        'username' => $user['username'],
        'email' => $user['email']
    ]);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid email or password']);
}
?>