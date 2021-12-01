if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Warning  "Running as non-Admin user. Skipping environment checks"
} else {
    $capability = Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH.Client*"
    Write-Information $capability
    if($capability.State -ne "Installed") {
        Write-Information "Installing OpenSSH client"
        Add-WindowsCapability -Online -Name $capability.Name
    } else {
        Write-Information "OpenSSH client installed"
    }

    $sshAgent = Get-Service ssh-agent
    if($sshAgent.Status -eq "Stopped") {$sshAgent | Start-Service}
    if($sshAgent.StartType -eq "Disabled") {$sshAgent | Set-Service -StartupType Automatic }

}

if([String]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable("GIT_SSH"))) {
    [Environment]::SetEnvironmentVariable("GIT_SSH", "$((Get-Command ssh).Source)", [System.EnvironmentVariableTarget]::User)
}

$keyPath = Join-Path $env:Userprofile ".ssh\id_rsa" { # Assuming file name here
    ssh-keygen -q -f $keyPath -C "autogenerated_key" -N """" # empty password
    ssh-add -q -f $keyPath
}

$line = Get-Content -Path "$($keyPath).pub" | Select-Object -First 1 # assuming file name and key index

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Your SSH Key'
$form.Size = New-Object System.Drawing.Size(600,150)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(260,70)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,10)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Copy your key and paste into ADO:'
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,30)
$textBox.Size = New-Object System.Drawing.Size(560,40)
$textBox.Text = $line
$textBox.ReadOnly = $true

$form.Controls.Add($textBox)
$form.Add_Shown({$textBox.Select()})
$form.Topmost = $true
$form.ShowDialog()