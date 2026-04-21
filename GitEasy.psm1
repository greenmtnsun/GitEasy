## --- 1. CONNECTIVITY & SETUP ---

function Set-Vault {
    <#
    .SYNOPSIS
        Connects a folder to GitLab. Standardizes the .gitignore for DBA ecosystems.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$GitLabUrl,
        [string]$UserEmail,
        [string]$UserName
    )

    if (-not (Test-Path ".git")) {
        Write-Host "Initializing new Vault..." -ForegroundColor Cyan
        git init
        git remote add origin $GitLabUrl

        # Comprehensive ignore list for SQL/SSIS/RDL/PS
        $ignore = @(
            "*.user", "*.suo", "*.tmp", "*.log", "*.bak", # User/Temp noise
            "bin/", "obj/", "TestResults/",               # Build artifacts
            ".vs/", ".idea/", ".vscode/",                 # IDE noise
            "*.pfx", "secrets.json", "*.rdl.data"         # Security/Cache
        )
        $ignore | Out-File ".gitignore" -Encoding utf8 -Force
    }

    # Set local identity if provided (prevents "Who am I?" errors)
    if ($UserEmail) { git config user.email $UserEmail }
    if ($UserName)  { git config user.name $UserName }

    git branch -M main
    Write-Host "Vault linked to: $GitLabUrl" -ForegroundColor Green
}

function Show-Remote {
    <#
    .SYNOPSIS
        Shows where this Vault points online.
    #>
    [CmdletBinding()]
    param()

    git remote -v
}

function Set-Token {
    <#
    .SYNOPSIS
        Sets the online address and clears old saved login so Git can ask for a token.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$WebAddress
    )

    git remote set-url origin $WebAddress
    Reset-Login

    Write-Host "Web address set for origin." -ForegroundColor Green
    Write-Host "Next time Git asks for a password, paste your token instead." -ForegroundColor Cyan
}

function Set-Ssh {
    <#
    .SYNOPSIS
        Switches the online address to SSH style.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SshAddress
    )

    git remote set-url origin $SshAddress
    Write-Host "SSH address set for origin." -ForegroundColor Green
}

function Reset-Login {
    <#
    .SYNOPSIS
        Clears saved login for the current online host.
    #>
    [CmdletBinding()]
    param(
        [string]$HostName
    )

    if (-not $HostName) {
        $remote = git remote get-url origin 2>$null
        if (-not $remote) {
            Write-Warning "No online address found for origin."
            return
        }

        if ($remote -match 'https?://([^/]+)') {
            $HostName = $Matches[1]
        }
        elseif ($remote -match '@([^:]+):') {
            $HostName = $Matches[1]
        }
        else {
            Write-Warning "Could not figure out the host name from the current online address."
            return
        }
    }

    Write-Host "Clearing saved login for $HostName ..." -ForegroundColor Yellow

    $deletedSomething = $false

    if (Get-Command cmdkey.exe -ErrorAction SilentlyContinue) {
        $targets = @(
            "git:$HostName",
            "git:https://$HostName",
            "LegacyGeneric:target=git:https://$HostName",
            "LegacyGeneric:target=git:$HostName"
        )

        foreach ($target in $targets) {
            cmdkey.exe /delete:$target *> $null
        }

        $deletedSomething = $true
    }

    if (Get-Command git -ErrorAction SilentlyContinue) {
        try {
            $helper = git config --global credential.helper 2>$null
            if ($helper -match 'manager') {
                $credentialInput = "protocol=https`nhost=$HostName`n"
                $credentialInput | git credential-manager erase *> $null
                $deletedSomething = $true
            }
        }
        catch {
            # Ignore helper cleanup failures. cmdkey cleanup is still useful.
        }
    }

    if ($deletedSomething) {
        Write-Host "Saved login cleanup attempted for $HostName." -ForegroundColor Green
    }
    else {
        Write-Warning "Could not find a supported saved-login tool on this machine."
    }
}

function Test-Login {
    <#
    .SYNOPSIS
        Safely checks whether this Vault can talk to the online remote.
    #>
    [CmdletBinding()]
    param()

    $output = git ls-remote origin 2>&1
    $code = $LASTEXITCODE

    if ($code -eq 0) {
        Write-Host "Login works. Git can reach the online remote." -ForegroundColor Green
        return $true
    }

    Write-Warning "Git could not reach the online remote with the current login."
    $output | ForEach-Object { Write-Host $_ }
    Write-Host "Try Set-Token, Set-Ssh, or Reset-Login." -ForegroundColor Yellow
    return $false
}

## --- 2. THE SYNC ENGINE ---
function Save-Work {
    <#
    .SYNOPSIS
        Snapshots every file and pushes to GitHub or GitLab.
        Handles module versioning and pulls peer updates first.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Note,
        [switch]$NewVersion,
        [ValidateSet('Major', 'Minor', 'Build', 'Revision')]
        [string]$BumpType = 'Revision'
    )

    # 1. Handle PowerShell Module Versioning
    if ($NewVersion) {
        $Manifest = Get-ChildItem *.psd1 | Select-Object -First 1
        if ($Manifest) {
            $manifestData = Import-PowerShellDataFile $Manifest.FullName
            $v = [version]$manifestData.ModuleVersion

            switch ($BumpType) {
                'Major'    { $newV = New-Object System.Version ($v.Major + 1), 0, 0, 0 }
                'Minor'    { $newV = New-Object System.Version $v.Major, ($v.Minor + 1), 0, 0 }
                'Build'    { $newV = New-Object System.Version $v.Major, $v.Minor, ($v.Build + 1), 0 }
                'Revision' { $newV = New-Object System.Version $v.Major, $v.Minor, $v.Build, ($v.Revision + 1) }
            }

            $pattern = "ModuleVersion\s*=\s*'[^']+'"
            $replacement = "ModuleVersion     = '$newV'"
            (Get-Content $Manifest.FullName -Raw) -replace $pattern, $replacement | Set-Content $Manifest.FullName

            $Note = "[v$newV] $Note"
            Write-Host "Bumped $BumpType to $newV" -ForegroundColor Cyan
        }
    }

    # 2. Check whether anything changed before doing remote work
    $pending = git status --porcelain
    if (-not $pending) {
        Write-Warning "No changes found to save."
        return
    }

    # 3. Pull first, before staging
    Write-Host "Checking for peer updates..." -ForegroundColor Gray
    git pull origin main --rebase

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Pull failed. Fix that first, then run Save-Work again."
        return
    }

    # 4. Now stage and commit
    git add .

    $pendingAfterAdd = git status --porcelain
    if (-not $pendingAfterAdd) {
        Write-Warning "No changes found to commit after staging."
        return
    }

    git commit -m "$Note"

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Commit failed."
        return
    }

    # 5. Push
    git push origin main

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Work synced and secured." -ForegroundColor Green
    }
    else {
        Write-Warning "Push failed. Your commit is still safe locally."
        Write-Host "Use Show-Remote to see where Git points." -ForegroundColor Yellow
        Write-Host "Use Test-Login to test access safely." -ForegroundColor Yellow
        Write-Host "Use Reset-Login if Windows saved the wrong login." -ForegroundColor Yellow
        Write-Host "Use Set-Token for HTTPS token login or Set-Ssh for SSH." -ForegroundColor Yellow
    }
}
## --- 3. THE TOP 15 DBA UTILITIES ---

function Show-History {
    <# .SYNOPSIS See a visual timeline of changes. #>
    [CmdletBinding()]
    param()

    git log --oneline -n 15 --graph --decorate
}

function Find-CodeChange {
    <# .SYNOPSIS Search all history for a string (for example, a dropped table name). #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SearchString
    )

    git log -S "$SearchString" --patch
}

function Restore-File {
    <# .SYNOPSIS Revert a single file to its last-saved state. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FileName
    )

    git checkout -- "$FileName"
    Write-Host "Restored $FileName." -ForegroundColor Cyan
}

function Clear-Junk {
    <# .SYNOPSIS Clean out bin/obj and untracked temp files from ecosystems. #>
    [CmdletBinding()]
    param()

    git clean -fdX
    Write-Host "Temp files and build artifacts cleared." -ForegroundColor Yellow
}

function Undo-Changes {
    <# .SYNOPSIS Wipe local mess and start fresh from GitLab. #>
    [CmdletBinding()]
    param()

    if ((Read-Host "Wipe all unsaved work? (Y/N)") -eq 'Y') {
        git reset --hard HEAD
        git clean -fd
        Write-Host "Local state reset to GitLab truth." -ForegroundColor Red
    }
}

function New-WorkBranch {
    <# .SYNOPSIS Create a sandbox for experimental work. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Name
    )

    git checkout -b "$Name"
}

function Switch-Work {
    <# .SYNOPSIS Switch between main and a sandbox branch. #>
    [CmdletBinding()]
    param(
        [string]$Name = "main"
    )

    git checkout "$Name"
}

function Get-VaultStatus {
    <# .SYNOPSIS Check what is changed but not yet saved. #>
    [CmdletBinding()]
    param()

    git status -s
}

Export-ModuleMember -Function Set-Vault, Show-Remote, Set-Token, Set-Ssh, Reset-Login, Test-Login, Save-Work, Show-History, Find-CodeChange, Restore-File, Clear-Junk, Undo-Changes, New-WorkBranch, Switch-Work, Get-VaultStatus
