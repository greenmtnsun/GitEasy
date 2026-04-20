## --- 1. CONNECTIVITY & SETUP ---

function Set-Vault {
    <#
    .SYNOPSIS
        Connects a folder to GitLab. Standardizes the .gitignore for DBA ecosystems.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$GitLabUrl,
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

## --- 2. THE SYNC ENGINE ---
function Save-Work {
    <#
    .SYNOPSIS
        Snapshots every file (SQL, PS1, RDL, DTSX) and pushes to GitLab/GitHub.
        Handles atomic versioning and "First-Day" sync issues.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Note, 
        [switch]$NewVersion,
        [ValidateSet('Major','Minor','Build','Revision')]
        [string]$BumpType = 'Revision'
    )
    
    # 1. THE FULL VERSIONING LOGIC (RESTORED)
    if ($NewVersion) {
        $Manifest = Get-ChildItem *.psd1 | Select-Object -First 1
        if ($Manifest) {
            $v = [version](Import-PowerShellDataFile $Manifest.FullName).ModuleVersion
            
            switch ($BumpType) {
                'Major'    { $newV = New-Object System.Version ($v.Major + 1), 0, 0, 0 }
                'Minor'    { $newV = New-Object System.Version $v.Major, ($v.Minor + 1), 0, 0 }
                'Build'    { $newV = New-Object System.Version $v.Major, $v.Minor, ($v.Build + 1), 0 }
                'Revision' { $newV = New-Object System.Version $v.Major, $v.Minor, $v.Build, ($v.Revision + 1) }
            }

            (Get-Content $Manifest.FullName -Raw) -replace "(ModuleVersion\s*=\s*['""])$($v.ToString())(['""])", "`${1}$newV`${2}" | Set-Content $Manifest.FullName
            $Note = "[v$newV] $Note"
            Write-Host "Bumped $BumpType to $newV" -ForegroundColor Cyan
        }
    }

    # 2. STAGE ALL ASSETS
    git add .

    # 3. SYNC ENGINE (HARDENED)
    if (git status --porcelain) {
        Write-Host "Syncing with Vault..." -ForegroundColor Cyan
        
        # This handles the 'unrelated histories' curveball from GitHub
        git pull origin main --rebase --allow-unrelated-histories 2>$null

        git commit -m "$Note"
        
        # Ensure we track the branch (vital for the first push)
        git push -u origin main
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Work synced and secured." -ForegroundColor Green
        } else {
            Write-Error "Push failed! Check your connection or credentials."
        }
    } else {
        Write-Warning "No changes detected. Nothing to vault."
    }
}

## --- 3. THE TOP 15 DBA UTILITIES ---

function Show-History {
    <# .SYNOPSIS See a visual timeline of changes. #>
    git log --oneline -n 15 --graph --decorate
}

function Find-CodeChange {
    <# .SYNOPSIS Search all history for a string (e.g. searching for a dropped table). #>
    param([Parameter(Mandatory=$true)][string]$SearchString)
    git log -S "$SearchString" --patch
}

function Restore-File {
    <# .SYNOPSIS Revert a single file to its last-saved state. #>
    param([Parameter(Mandatory=$true)][string]$FileName)
    git checkout "$FileName"
    Write-Host "Restored $FileName." -ForegroundColor Cyan
}

function Clear-Junk {
    <# .SYNOPSIS Clean out bin/obj and untracked temp files from ecosystems. #>
    git clean -fdX
    Write-Host "Temp files and build artifacts cleared." -ForegroundColor Yellow
}

function Undo-Changes {
    <# .SYNOPSIS Wipe local mess and start fresh from GitLab. #>
    if ((Read-Host "Wipe all unsaved work? (Y/N)") -eq 'Y') {
        git reset --hard HEAD
        git clean -fd
        Write-Host "Local state reset to GitLab 'Truth'." -ForegroundColor Red
    }
}

function New-WorkBranch {
    <# .SYNOPSIS Create a sandbox for experimental work. #>
    param([Parameter(Mandatory=$true)][string]$Name)
    git checkout -b "$Name"
}

function Switch-Work {
    <# .SYNOPSIS Switch between 'main' and a sandbox branch. #>
    param([string]$Name = "main")
    git checkout "$Name"
}

function Get-VaultStatus {
    <# .SYNOPSIS Check what is changed but not yet saved. #>
    git status -s
}

Export-ModuleMember -Function Set-Vault, Save-Work, Show-History, Find-CodeChange, Restore-File, Clear-Junk, Undo-Changes, New-WorkBranch, Switch-Work, Get-VaultStatus
