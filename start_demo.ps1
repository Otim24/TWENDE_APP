# Get the list of connected devices
$devices = flutter devices --machine | ConvertFrom-Json

if ($devices.Count -lt 2) {
    Write-Host "Error: Need at least 2 connected devices. Found $($devices.Count)." -ForegroundColor Red
    exit
}

$device1 = $devices[0].id
$device2 = $devices[1].id

Write-Host "Device 1: $device1" -ForegroundColor Green
Write-Host "Device 2: $device2" -ForegroundColor Green

Write-Host "Launching Passenger App on $device1..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd passenger_app; flutter run -d $device1"

Write-Host "Launching Conductor App on $device2..." -ForegroundColor Magenta
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd conductor_app; flutter run -d $device2"

Write-Host "Both apps are launching in separate windows!" -ForegroundColor Yellow
