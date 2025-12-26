<?php
header('Content-Type: application/json');
require_once '../includes/config.php';
session_start();

$action = $_GET['action'] ?? '';

// Basic error handler
function sendResponse($success, $data = null, $message = '')
{
    echo json_encode(['success' => $success, 'data' => $data, 'message' => $message]);
    exit;
}

switch ($action) {
    case 'login':
        // Handle login via AJAX
        $data = json_decode(file_get_contents('php://input'), true);
        $username = $data['username'] ?? '';
        $password = $data['password'] ?? '';

        // Quick verify (duplicating logic for API simplicity or include auth.php logic)
        $stmt = $mysqli->prepare("SELECT id, password, role FROM users WHERE username = ?");
        $stmt->bind_param("s", $username);
        $stmt->execute();
        $stmt->store_result();

        if ($stmt->num_rows > 0) {
            $stmt->bind_result($id, $hashed_password, $role);
            $stmt->fetch();
            if (password_verify($password, $hashed_password)) {
                $_SESSION['user_id'] = $id;
                $_SESSION['role'] = $role;
                sendResponse(true, ['id' => $id, 'role' => $role], 'Login successful');
            }
        }
        sendResponse(false, null, 'Invalid credentials');
        break;

    case 'get_status':
        // 1. Fetch Gates (A & B)
        $gates = [];
        // Use Prepared Statements for consistency
        $stmtGate = $mysqli->prepare("SELECT * FROM gates WHERE id = ? LIMIT 1");

        // Gate A (ID 2)
        $idA = 2;
        $stmtGate->bind_param("i", $idA);
        $stmtGate->execute();
        $resA = $stmtGate->get_result();
        if ($resA)
            $gates['A'] = $resA->fetch_assoc();

        // Gate B (ID 3)
        $idB = 3;
        $stmtGate->bind_param("i", $idB);
        $stmtGate->execute();
        $resB = $stmtGate->get_result();
        if ($resB)
            $gates['B'] = $resB->fetch_assoc();

        $stmtGate->close();

        // 2. Fetch Sensors
        $sensors = [];
        $stmtSens = $mysqli->prepare("SELECT * FROM sensor_readings WHERE gate_id = ? ORDER BY recorded_at DESC LIMIT 1");

        // Sensor A
        $stmtSens->bind_param("i", $idA);
        $stmtSens->execute();
        $resSA = $stmtSens->get_result();
        if ($resSA)
            $sensors['A'] = $resSA->fetch_assoc();

        // Sensor B
        $stmtSens->bind_param("i", $idB);
        $stmtSens->execute();
        $resSB = $stmtSens->get_result();
        if ($resSB)
            $sensors['B'] = $resSB->fetch_assoc();

        $stmtSens->close();

        // 3. Fetch Live Weather (Open-Meteo)
        $lat = 41.5308;
        $lon = 60.3214;
        $weather = null;
        try {
            // Short timeout to prevent hanging
            $ctx = stream_context_create(['http' => ['timeout' => 2]]);
            $url = "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,rain,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m&timezone=auto";
            $json = @file_get_contents($url, false, $ctx);
            if ($json) {
                $weather = json_decode($json, true);
            }
        } catch (Exception $e) {
            // Ignore weather errors
        }

        // 4. Construct Response
        $response = [
            'gates' => $gates,
            'sensors' => $sensors,
            'metastation' => $weather ?? ['error' => 'Weather unavailable'],
            'timestamp' => date('Y-m-d H:i:s')
        ];

        sendResponse(true, $response);
        break;

    case 'control_gate':
        $data = json_decode(file_get_contents('php://input'), true);

        $user_id = 0;

        // 1. Try Session (Web)
        if (isset($_SESSION['user_id'])) {
            $user_id = $_SESSION['user_id'];
        }
        // 2. Try Input Payload (Mobile App)
        elseif (isset($data['user_id'])) {
            $user_id = intval($data['user_id']);
            // Basic validation: Check if user exists
            $check = $mysqli->query("SELECT id FROM users WHERE id = $user_id");
            if ($check->num_rows === 0) {
                sendResponse(false, null, 'Invalid User ID');
            }
        } else {
            sendResponse(false, null, 'Unauthorized: Login required');
        }

        $command = $data['command'] ?? ''; // open, close, set_position
        $target_position = $data['position'] ?? 0;

        $target_name = $data['target'] ?? 'MAIN GATE';
        $gate_id = 1; // Default (Main Gate)

        if ($target_name === 'GATE A') {
            $gate_id = 2; // Canal Sluice A
        } elseif ($target_name === 'GATE B') {
            $gate_id = 3; // Canal Sluice B
        }

        // Validate inputs
        if ($command === 'open')
            $target_position = 100;
        if ($command === 'close')
            $target_position = 0;

        // Update database (Dynamic ID)
        $stmt = $mysqli->prepare("UPDATE gates SET status = 'moving', position = ? WHERE id = ?");
        $stmt->bind_param("ii", $target_position, $gate_id);

        if ($stmt->execute()) {
            // Log the action
            $log_stmt = $mysqli->prepare("INSERT INTO gate_history (gate_id, action, details, performed_by) VALUES (?, 'control_command', ?, ?)");
            $details = "Command: $command, Target: $target_position";
            $log_stmt->bind_param("isi", $gate_id, $details, $user_id);
            $log_stmt->execute();

            sendResponse(true, ['new_position' => $target_position, 'gate_id' => $gate_id], 'Command sent successfully');
        } else {
            sendResponse(false, null, 'Database error');
        }
        break;

    default:
        sendResponse(false, null, 'Invalid action');
}
?></content>
<parameter name="filePath">c:\Users\ASB\.gemini\antigravity\scratch\scada_mobile_app\api.php