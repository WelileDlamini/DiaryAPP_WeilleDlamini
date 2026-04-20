<?php
require_once '../config/database.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['username']) || !isset($data['email']) || !isset($data['password'])) {
    echo json_encode(['success' => false, 'message' => 'Username, email and password required']);
    exit();
}

$username = trim($data['username']);
$email = trim($data['email']);
$password = $data['password'];

if (strlen($password) < 4) {
    echo json_encode(['success' => false, 'message' => 'Password must be at least 4 characters']);
    exit();
}

$password_hash = password_hash($password, PASSWORD_DEFAULT);

try {
    $stmt = $pdo->prepare("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)");
    $stmt->execute([$username, $email, $password_hash]);
    
    $userId = $pdo->lastInsertId();
    
    echo json_encode([
        'success' => true,
        'message' => 'Registration successful',
        'user_id' => $userId,
        'username' => $username
    ]);
} catch(PDOException $e) {
    if ($e->errorInfo[1] == 1062) {
        echo json_encode(['success' => false, 'message' => 'Username or email already exists']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Registration failed: ' . $e->getMessage()]);
    }
}
?>