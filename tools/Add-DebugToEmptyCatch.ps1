param(
    [Parameter(Mandatory)]
    [string]$Root
)

if (-not (Test-Path -Path $Root)) {
    Write-Error "Root path not found: $Root"
    exit 1
}

$files = Get-ChildItem -Path $Root -Filter '*.ps1' -File
$updatedFiles = New-Object System.Collections.Generic.List[string]

foreach ($file in $files) {
    if ($file.Name -eq 'Write-AppLockerLog.ps1') {
        continue
    }
    $lines = Get-Content -Path $file.FullName
    $output = New-Object System.Collections.Generic.List[string]
    $modified = $false
    $i = 0

    while ($i -lt $lines.Count) {
        $line = $lines[$i]

        if ($line -match 'catch\s*\{\s*\}\s*$' -and $line -notmatch 'Write-AppLockerLog') {
            $logLine = 'catch { Write-AppLockerLog -Message "Empty catch in ' + $file.Name + '" -Level ''Debug'' -NoConsole }'
            $updatedLine = $line -replace 'catch\s*\{\s*\}\s*$', $logLine
            $output.Add($updatedLine) | Out-Null
            $modified = $true
            $i++
            continue
        }

        if ($line -match '^\s*catch\s*\{\s*\}\s*$' -or $line -match '^\s*catch\s*\{\s*#.*\}\s*$') {
            $comment = $null
            if ($line -match '^\s*catch\s*\{\s*(#.*)\}\s*$') {
                $comment = $Matches[1]
            }
            $indent = $line -replace 'catch\s*\{\s*.*$',''
            $output.Add(($indent + 'catch {')) | Out-Null
            if ($comment) {
                $output.Add(($indent + '    ' + $comment.Trim())) | Out-Null
            }
            $logLine = ($indent + '    ') + "Write-AppLockerLog -Message ""Empty catch in $($file.Name)"" -Level 'Debug' -NoConsole"
            $output.Add($logLine) | Out-Null
            $output.Add(($indent + '}')) | Out-Null
            $modified = $true
            $i++
            continue
        }

        if ($line -match 'catch\s*\{\s*\}\s*$' -and $line -match 'try\s*\{' -and $line -notmatch 'Write-AppLockerLog') {
            $indent = $line -replace 'try\s*\{.*$',''
            $logLine = 'catch { Write-AppLockerLog -Message "Empty catch in ' + $file.Name + '" -Level ''Debug'' -NoConsole }'
            $updatedLine = $line -replace 'catch\s*\{\s*\}\s*$', $logLine
            $output.Add($updatedLine) | Out-Null
            $modified = $true
            $i++
            continue
        }

        if ($line -match '^\s*catch\s*\{\s*$') {
            $output.Add($line) | Out-Null
            $i++

            $blockLines = New-Object System.Collections.Generic.List[string]
            while ($i -lt $lines.Count -and $lines[$i] -notmatch '^\s*\}\s*$') {
                $blockLines.Add($lines[$i]) | Out-Null
                $i++
            }

            $hasCode = $false
            foreach ($blockLine in $blockLines) {
                $trimmed = $blockLine.Trim()
                if ($trimmed -ne '' -and -not $trimmed.StartsWith('#')) {
                    $hasCode = $true
                    break
                }
            }

            if (-not $hasCode) {
                $indent = $line -replace 'catch\s*\{\s*$', ''

                $firstContent = $null
                foreach ($blockLine in $blockLines) {
                    if ($blockLine.Trim() -ne '') {
                        $firstContent = $blockLine
                        break
                    }
                }

                if ($null -ne $firstContent) {
                    $indent = $firstContent -replace '\S.*$', ''
                } else {
                    $indent = $indent + '    '
                }

                foreach ($blockLine in $blockLines) {
                    $output.Add($blockLine) | Out-Null
                }

                $logLine = $indent + "Write-AppLockerLog -Message ""Empty catch in $($file.Name)"" -Level 'Debug' -NoConsole"
                $output.Add($logLine) | Out-Null
                $modified = $true
            } else {
                foreach ($blockLine in $blockLines) {
                    $output.Add($blockLine) | Out-Null
                }
            }

            if ($i -lt $lines.Count -and $lines[$i] -match '^\s*\}\s*$') {
                $output.Add($lines[$i]) | Out-Null
            }

            $i++
            continue
        }

        $output.Add($line) | Out-Null
        $i++
    }

    if ($modified) {
        Set-Content -Path $file.FullName -Value $output -Encoding UTF8
        $updatedFiles.Add($file.FullName) | Out-Null
    }
}

Write-Output "Updated $($updatedFiles.Count) file(s)."
foreach ($updated in $updatedFiles) {
    Write-Output "- $updated"
}
