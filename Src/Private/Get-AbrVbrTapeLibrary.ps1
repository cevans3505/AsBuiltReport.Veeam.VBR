
function Get-AbrVbrTapeLibrary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Tape Library Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.7.1
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Veeam VBR Tape Library information from $System."
    }

    process {
        try {
            $TapeObjs = Get-VBRTapeLibrary | Sort-Object -Property Name
            if ($TapeObjs) {
                Section -Style Heading3 'Tape Libraries' {
                    Paragraph "The following section provides summary information about Tape Server connected Tape Library."
                    BlankLine
                    $OutObj = @()
                    try {
                        foreach ($TapeObj in $TapeObjs) {
                            try {
                                Section -Style Heading4 $($TapeObj.Name) {
                                    Write-PscriboMessage "Discovered $($TapeObj.Name) Type Library."
                                    $TapeServer = (Get-VBRTapeServer | Where-Object {$_.Id -eq $TapeObj.TapeServerId}).Name
                                    $inObj = [ordered] @{
                                        'Library Name' = $TapeObj.Name
                                        'Library Model' = $TapeObj.Model
                                        'Library Type' = $TapeObj.Type
                                        'Number of Slots' = $TapeObj.Slots
                                        'Connected to' = $TapeServer
                                        'Enabled' = ConvertTo-TextYN $TapeObj.Enabled
                                        'Status' = Switch ($TapeObj.State) {
                                            'Online' {'Available'}
                                            'Offline' {'Unavailable'}
                                            default {$TapeObj.State}
                                        }
                                    }

                                    $OutObj += [pscustomobject]$inobj

                                    if ($HealthCheck.Tape.Status) {
                                        $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                                    }

                                    $TableParams = @{
                                        Name = "Tape Library - $($TapeObj.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }

                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                    #---------------------------------------------------------------------------------------------#
                                    #                                  Tape Drives Section                                        #
                                    #---------------------------------------------------------------------------------------------#
                                    try {
                                        $DriveObjs = Get-VBRTapeDrive -Library $TapeObj.Id
                                        if ($DriveObjs) {
                                            Write-PscriboMessage "Collecting $($TapeObj.Name) Tape Drives"
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC "Tape Drives" {
                                                $OutObj = @()
                                                try {
                                                    foreach ($DriveObj in $DriveObjs) {
                                                        Write-PscriboMessage "Discovered $($DriveObj.Name) Type Drive."
                                                        $inObj = [ordered] @{
                                                            'Name' = $DriveObj.Name
                                                            'Model' = $DriveObj.Model
                                                            'Serial Number' = $DriveObj.SerialNumber
                                                            'Medium' = switch ([string]::IsNullOrEmpty($DriveObj.Medium)) {
                                                                $true {'-' }
                                                                $false {$DriveObj.Medium}
                                                                Default {'Unknown'}
                                                            }
                                                            'Enabled' = ConvertTo-TextYN $DriveObj.Enabled
                                                            'Is Locked' = ConvertTo-TextYN $DriveObj.IsLocked
                                                            'State' = $DriveObj.State
                                                        }
                                                        $OutObj += [pscustomobject]$inobj
                                                    }

                                                    if ($HealthCheck.Tape.Status) {
                                                        $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                                                    }

                                                    $TableParams = @{
                                                        Name = "Tape Drives - $($TapeObj.Name)"
                                                        List = $false
                                                        ColumnWidths = 14, 18, 16, 16, 12, 12, 12
                                                    }

                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning "Tape Drives $($TapeObj.Name) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning "Tape Drives Section: $($_.Exception.Message)"
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                                  Tape Medium Section                                        #
                                    #---------------------------------------------------------------------------------------------#
                                    try {
                                        if ($InfoLevel.Tape.Library -ge 2) {
                                            $MediumObjs = Get-VBRTapeMedium -Library $TapeObj.Id
                                            if ($MediumObjs) {
                                                Write-PscriboMessage "Collecting $($TapeObj.Name) Tape Medium"
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC "Tape Mediums" {
                                                    $OutObj = @()
                                                    foreach ($MediumObj in $MediumObjs) {
                                                        try {

                                                            Write-PscriboMessage "Discovered $($MediumObj.Name) Type Medium."
                                                            $inObj = [ordered] @{
                                                                'Name' = $MediumObj.Name
                                                                'Expiration Date' = Switch (($MediumObj.ExpirationDate).count) {
                                                                    0 {"-"}
                                                                    default {$MediumObj.ExpirationDate.ToShortDateString()}
                                                                }
                                                                'Total Space' = ConvertTo-FileSizeString $MediumObj.Capacity
                                                                'Free Space' = ConvertTo-FileSizeString $MediumObj.Free
                                                                'Locked' = ConvertTo-TextYN $MediumObj.IsLocked
                                                                'Retired' = ConvertTo-TextYN $MediumObj.IsRetired
                                                                'Worm' = ConvertTo-TextYN $MediumObj.IsWorm
                                                            }
                                                            $OutObj += [pscustomobject]$inobj
                                                        }
                                                        catch {
                                                            Write-PscriboMessage -IsWarning "Tape Mediums $($MediumObj.Name) Section: $($_.Exception.Message)"
                                                        }
                                                    }

                                                    $TableParams = @{
                                                        Name = "Tape Mediums - $($TapeObj.Name)"
                                                        List = $false
                                                        ColumnWidths = 30, 16, 12, 12, 10, 10, 10
                                                    }

                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                }
                                            }
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning "Tape Mediums Section: $($_.Exception.Message)"
                                    }
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "Tape Library $($TapeObj.Name) Section: $($_.Exception.Message)"
                            }
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "Tape Libraries Table Section: $($_.Exception.Message)"
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Tape Libraries Section: $($_.Exception.Message)"
        }
    }
    end {}

}