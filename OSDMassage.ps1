# Function to Get Device Type
function Get-DeviceType {
    # Query Win32_SystemEnclosure to check the ChassisTypes
    $ChassisTypes = (Get-WmiObject -Class Win32_SystemEnclosure).ChassisTypes

    # Determine if the system is a laptop or desktop
    if ($ChassisTypes -contains 10 -or $ChassisTypes -contains 14) {
        return "L" # Laptop
    } else {
        return "D" # Desktop
    }
}

# Function to Get Serial Number
function Get-SerialNumber {
    # Query Win32_BIOS to get the serial number
    return (Get-WmiObject -Class Win32_BIOS).SerialNumber
}

# Function to Set BIOS Password for Dell, HP, and VMware
function Set-BiosPassword {
    param (
        [string]$BiosPassword
    )

    # Check for Dell Command | Configure and install if necessary
    if (Test-Path "C:\Program Files (x86)\Dell\CommandConfigure\cmd") {
        Write-Host "Setting BIOS password for Dell..."
        & "C:\Program Files (x86)\Dell\CommandConfigure\cmd" /set /password:$BiosPassword
        Write-Host "Dell BIOS password set successfully."
    }
    # Check for HP BIOS Configuration Utility and install if necessary
    elseif (Test-Path "C:\Program Files (x86)\HP\HP BIOS Configuration Utility\HPBIOSCmd.exe") {
        Write-Host "Setting BIOS password for HP..."
        & "C:\Program Files (x86)\HP\HP BIOS Configuration Utility\HPBIOSCmd.exe" /setpw:$BiosPassword
        Write-Host "HP BIOS password set successfully."
    }
    # VMware BIOS password handling (not natively supported via VMware Tools)
    elseif (Test-Path "C:\Program Files\VMware\VMware Tools\vmtoolsd.exe") {
        Write-Host "Setting BIOS password for VMware..."
        Write-Error "Setting BIOS password for VMware is not directly supported via VMware Tools."
    }
    # If BIOS tool is not detected, install the correct tool
    else {
        Write-Host "BIOS configuration tool not detected. Installing the required tool..."

        # Install the correct tool based on system manufacturer
        $manufacturer = (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer
        switch ($manufacturer) {
            "Dell Inc." {
                # Install Dell Command | Configure if the system is Dell
                Write-Host "System is Dell. Installing Dell Command | Configure..."
                Install-DellCommandConfigure
                & "C:\Program Files (x86)\Dell\CommandConfigure\cmd" /set /password:$BiosPassword
                Write-Host "Dell BIOS password set successfully."
                break
            }
            "Hewlett-Packard" {
                # Install HP BIOS Configuration Utility if the system is HP
                Write-Host "System is HP. Installing HP BIOS Configuration Utility..."
                Install-HPBiosConfigUtility
                & "C:\Program Files (x86)\HP\HP BIOS Configuration Utility\HPBIOSCmd.exe" /setpw:$BiosPassword
                Write-Host "HP BIOS password set successfully."
                break
            }
            default {
                Write-Error "Unknown system manufacturer. BIOS password cannot be set."
            }
        }
    }
}

# Function to Install Dell Command | Configure
function Install-DellCommandConfigure {
    $DellInstallerUrl = "https://downloads.dell.com/FOLDER12345/Command_Configure.exe"
    $DellInstallerPath = "C:\Temp\DellCommandConfigure.exe"
    
    Write-Host "Downloading Dell Command | Configure..."
    Invoke-WebRequest -Uri $DellInstallerUrl -OutFile $DellInstallerPath
    Write-Host "Installing Dell Command | Configure..."
    Start-Process -FilePath $DellInstallerPath -ArgumentList "/quiet /norestart" -Wait
    Write-Host "Dell Command | Configure installed successfully."
}

# Function to Install HP BIOS Configuration Utility
function Install-HPBiosConfigUtility {
    $HPInstallerUrl = "https://downloads.hp.com/FOLDER67890/HPBIOSConfigUtility.exe"
    $HPInstallerPath = "C:\Temp\HPBIOSConfigUtility.exe"
    
    Write-Host "Downloading HP BIOS Configuration Utility..."
    Invoke-WebRequest -Uri $HPInstallerUrl -OutFile $HPInstallerPath
    Write-Host "Installing HP BIOS Configuration Utility..."
    Start-Process -FilePath $HPInstallerPath -ArgumentList "/quiet /norestart" -Wait
    Write-Host "HP BIOS Configuration Utility installed successfully."
}

# Function to Install Sophos EDR
function Install-SophosEDR {
    param (
        [string]$SophosInstallerPath
    )

    # Check if Sophos EDR installer is available
    if (Test-Path $SophosInstallerPath) {
        Write-Host "Starting Sophos EDR installation..."
        Start-Process -FilePath $SophosInstallerPath -ArgumentList "/quiet /norestart" -Wait
        Write-Host "Sophos EDR installed successfully."
    } else {
        Write-Error "Sophos EDR installer not found at $SophosInstallerPath."
    }
}

# Function to Rename the Computer Based on Department, Serial, and Device Type
function Rename-ComputerBasedOnAttributes {
    param (
        [string]$Department
    )

    # Get device type and serial number
    $DeviceType = Get-DeviceType
    $SerialNumber = Get-SerialNumber

    # Combine department, serial number, and device type to create the computer name
    $NewComputerName = "$Department-$SerialNumber$DeviceType"

    # Rename the computer
    Write-Host "Renaming the computer to $NewComputerName..."
    Rename-Computer -NewName $NewComputerName -Force -Restart
}

# Main Execution Block
try {
    # Step 1: Prompt user for the department name
    $Department = Read-Host "Enter the department name"

    # Default BIOS password
    $BiosPassword = "D3CyPher!T$"

    # Prompt for Sophos EDR installer path (assumes the installer is on the flash drive in a folder)
    $FlashDrivePath = "E:\"  # Adjust to match the flash drive letter
    $SophosInstallerPath = Join-Path -Path $FlashDrivePath -ChildPath "Sophos\installer.exe"

    # Check if the Sophos EDR installer exists
    if (-Not (Test-Path $SophosInstallerPath)) {
        Write-Error "Sophos installer not found on flash drive."
    } else {
        # Set BIOS password
        Set-BiosPassword -BiosPassword $BiosPassword

        # Install Sophos EDR
        Install-SophosEDR -SophosInstallerPath $SophosInstallerPath

        # Rename the computer based on department, serial number, and device type
        Rename-ComputerBasedOnAttributes -Department $Department
    }

    Write-Host "Script completed successfully."
} catch {
    Write-Error "An error occurred: $_"
}
