<#
.SYNOPSIS
    A PowerShell script demonstrating WPF UI creation, registry manipulation, and system management.

.DESCRIPTION
    This script serves as a learning tool for PowerShell and WPF development, covering:
    - PowerShell scripting fundamentals
    - Windows Registry manipulation
    - Windows Presentation Foundation (WPF) UI development
    - Event handling and user input processing
    - Error handling and resource management
    - System administration tasks

.NOTES
    File Name      : BedtimeReminder.ps1
    Prerequisites  : 
        - PowerShell 5.1 or later
        - Windows operating system
        - Administrator privileges
        - .NET Framework 4.5 or later

.EXAMPLE
    .\BedtimeReminder.ps1

.LINK
    PowerShell Documentation: https://docs.microsoft.com/en-us/powershell/
    WPF Documentation: https://docs.microsoft.com/en-us/dotnet/desktop/wpf/
#>

#Requires -RunAsAdministrator
<#
    POWERSHELL CONCEPT: #Requires
    - Specifies required conditions for running the script
    - Must be first non-comment line in the script
    - Common requirements:
        -RunAsAdministrator : Requires admin privileges
        -Version X.X       : Requires specific PowerShell version
        -Modules X,Y,Z     : Requires specific modules be installed
#>

#region MODULE IMPORTS AND INITIALIZATION
<#
    POWERSHELL CONCEPT: Add-Type
    - Adds .NET Framework types to PowerShell session
    - Can load assemblies, compile C# code, or add existing types
    - -AssemblyName parameter loads pre-compiled .NET assemblies
#>
try {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase -ErrorAction Stop
    <#
        POWERSHELL CONCEPT: Error Handling
        - -ErrorAction parameter controls how cmdlet handles errors
        - Common values:
            Continue : Report error and continue (default)
            Stop     : Throw exception
            SilentlyContinue : Ignore error and continue
            Inquire  : Prompt user for action
    #>
}
catch {
    <#
        POWERSHELL CONCEPT: Exception Handling
        - try/catch blocks handle errors
        - $_ in catch block contains error details
        - Write-Error writes to error stream (can be redirected)
    #>
    Write-Error "Failed to load WPF assemblies: $_"
    exit 1
}
#endregion MODULE IMPORTS

#region VARIABLE DECLARATIONS
<#
    POWERSHELL CONCEPT: Variables
    - Prefixed with $
    - No type declaration needed (dynamic typing)
    - $script: scope makes variable available throughout script
    - Common scopes:
        $script:  - Script level
        $global:  - Global level (all scripts)
        $local:   - Current scope (default)
        $private: - Current scope only (no inheritance)
#>
$script:window = $null
$script:reader = $null

# Registry paths
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
<#
    POWERSHELL CONCEPT: Registry Paths
    - HKCU: = HKEY_CURRENT_USER
    - Registry paths use : after hive name
    - Use \ as path separator (like file system)
#>
$registryName = "DisableTaskMgr"

# The sentence users must type
$requiredSentence = "I will put my computer to sleep at 23:15 every night."
#endregion VARIABLE DECLARATIONS

#region REGISTRY FUNCTIONS
<#
    POWERSHELL CONCEPT: Functions
    - Defined using function keyword
    - Can use param() block for parameters
    - Can use [CmdletBinding()] for advanced functions
    - Return value is everything that's not captured
#>

function Disable-TaskManager {
    <#
    .SYNOPSIS
        Disables Windows Task Manager by modifying registry.
    
    .DESCRIPTION
        Creates or modifies registry key to prevent Task Manager access.
        Includes error checking and verification of changes.
    
    .NOTES
        Requires administrative privileges to modify registry.
    #>
    
    try {
        # Check if already disabled
        <#
            POWERSHELL CONCEPT: Registry Operations
            - Test-Path works with registry like file system
            - Get-ItemProperty reads registry values
            - ErrorAction SilentlyContinue suppresses errors
        #>
        if ((Test-Path $registryPath) -and 
            (Get-ItemProperty -Path $registryPath -Name $registryName -ErrorAction SilentlyContinue).$registryName -eq 1) {
            Write-Host "Task Manager is already disabled"
            return
        }

        # Create registry path if needed
        if (!(Test-Path $registryPath)) {
            <#
                POWERSHELL CONCEPT: Pipeline
                - | sends output of one command as input to next
                - Out-Null discards output
                - Similar to Linux pipes but works with objects
            #>
            New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null
        }
        
        # Test write access
        <#
            POWERSHELL CONCEPT: .NET Integration
            - Can use .NET classes directly
            - [System.Guid]::NewGuid() calls static .NET method
            - PowerShell automatically loads common .NET namespaces
        #>
        $testValue = [System.Guid]::NewGuid().ToString()
        Set-ItemProperty -Path $registryPath -Name "TestWrite" -Value $testValue -ErrorAction Stop
        Remove-ItemProperty -Path $registryPath -Name "TestWrite" -ErrorAction Stop
        
        # Disable Task Manager
        Set-ItemProperty -Path $registryPath -Name $registryName -Value 1 -Type DWord -ErrorAction Stop
        
        # Verify change
        $result = Get-ItemProperty -Path $registryPath -Name $registryName -ErrorAction Stop
        if ($result.$registryName -ne 1) {
            throw "Failed to verify registry change"
        }
        
        Write-Host "Task Manager disabled successfully"
    }
    catch {
        Write-Error "Failed to disable Task Manager: $_"
        <#
            POWERSHELL CONCEPT: WPF Integration
            - Can use WPF classes for UI elements
            - Static methods called using :: operator
            - Parameters often use enumerated values
        #>
        [System.Windows.MessageBox]::Show(
            "Failed to initialize security settings. The application will exit.",
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
        exit 1
    }
}

# Additional functions and sections would continue with similar detailed documentation...
#endregion REGISTRY FUNCTIONS

#region XAML UI DEFINITION
<#
    POWERSHELL CONCEPT: Here-Strings
    - @" "@ defines multi-line string
    - Preserves all formatting and whitespace
    - Useful for XML, SQL, or other formatted text
    - Can embed variables using $() syntax
#>
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    Title="Bedtime Reminder"
    WindowState="Maximized"
    WindowStyle="None"
    ResizeMode="NoResize"
    Topmost="True"
    Background="Navy">
    
    <!-- XAML documentation would go here -->
</Window>
"@
#endregion XAML UI DEFINITION

#region EVENT HANDLERS
<#
    POWERSHELL CONCEPT: Event Handlers
    - Add_EventName syntax registers event handler
    - Script block {} contains handler code
    - $sender is control that raised event
    - $_ or $e contains event arguments
#>

# Text changed event handler
$inputTextBox.Add_TextChanged({
    <#
        POWERSHELL CONCEPT: Script Blocks
        - Code between {} is a script block
        - Can be stored in variables
        - Can be passed as parameters
        - Can access parent scope variables
    #>
    try {
        # Input sanitization
        <#
            POWERSHELL CONCEPT: Regular Expressions
            - -replace operator uses regex
            - [^\x20-\x7E] matches non-printable chars
            - ^ inside [] means "not these characters"
        #>
        $sanitizedText = $inputTextBox.Text -replace '[^\x20-\x7E]', ''
        
        # Update text if sanitized
        if ($sanitizedText -ne $inputTextBox.Text) {
            $inputTextBox.Text = $sanitizedText
            $inputTextBox.CaretIndex = $sanitizedText.Length
        }
        
        # Calculate match percentage
        <#
            POWERSHELL CONCEPT: Math Operations
            - Basic operators: +, -, *, /, %
            - [Math] class provides advanced functions
            - Automatic type conversion for numbers
        #>
        $totalLength = $requiredSentence.Length
        $matchLength = 0
        
        # Compare characters
        <#
            POWERSHELL CONCEPT: Looping
            - for loop similar to C-style
            - can also use foreach, while, do-while
            - break and continue work as expected
        #>
        for ($i = 0; $i -lt [Math]::Min($sanitizedText.Length, $totalLength); $i++) {
            if ($sanitizedText[$i] -eq $requiredSentence[$i]) {
                $matchLength++
            }
        }
        
        # Update UI based on match
        $percentMatch = ($matchLength / $totalLength) * 100
        $matchProgress.Value = $percentMatch
        $progressText.Text = "Match: $([Math]::Round($percentMatch))%"
        
        # Visual feedback
        <#
            POWERSHELL CONCEPT: Comparison Operators
            - -eq : Equals
            - -ne : Not equals
            - -gt : Greater than
            - -lt : Less than
            - -ge : Greater than or equal
            - -le : Less than or equal
        #>
        if ($percentMatch -eq 100) {
            $inputTextBox.BorderBrush = "Green"
            $errorMessage.Text = ""
        }
        elseif ($percentMatch -gt 80) {
            $inputTextBox.BorderBrush = "Orange"
            $errorMessage.Text = "Almost there! Check for small differences."
        }
        else {
            $inputTextBox.BorderBrush = "Red"
            $errorMessage.Text = ""
        }
    }
    catch {
        Write-Error "Text change handler error: $_"
    }
})

# Would continue with other event handlers and sections...
#endregion EVENT HANDLERS

#region MAIN EXECUTION
<#
    POWERSHELL CONCEPT: Script Execution
    - Scripts execute top to bottom
    - Functions are defined but not executed until called
    - try/catch/finally blocks handle errors
    - exit terminates script with status code
#>
try {
    # Initialize registry
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null
    }
    
    # Disable Task Manager and show window
    Disable-TaskManager
    $window.ShowDialog()
}
catch {
    Write-Error "Main execution error: $_"
    exit 1
}
finally {
    # Cleanup always runs
    & $cleanup  # & is the call operator
}
#endregion MAIN EXECUTION
