<?php
$ssid = $_POST['ssid'];
$password = $_POST['password'];
echo "Connecting";
exec("/usr/bin/yio-remote/first-time-setup/wifi_network_setup.sh ".escapeshellarg($ssid)." ".escapeshellarg($password));
?>


