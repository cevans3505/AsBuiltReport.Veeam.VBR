
function Get-AbrVbrIOControlSetting {
    <#
    .SYNOPSIS
    Used by As Built Report to returns storage latency control settings on the production datastores.
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
        Write-PscriboMessage "Discovering Veeam VBR storage latency control settings information from $System."
    }

    process {
        try {
            if (Get-VBRInstalledLicense | Where-Object {$_.Edition -in @("EnterprisePlus","Enterprise") -and $_.Status -ne "Expired"}) {
                if ((Get-VBRStorageLatencyControlOptions).count -gt 0) {
                    Section -Style Heading4 'Storage Latency Control' {
                        $OutObj = @()
                        $StorageLatencyControls = Get-VBRStorageLatencyControlOptions
                        foreach ($StorageLatencyControl in $StorageLatencyControls) {
                            try {
                                $inObj = [ordered] @{
                                    'Latency Limit' = "$($StorageLatencyControl.LatencyLimitMs)/ms"
                                    'Throttling IO Limit' = "$($StorageLatencyControl.ThrottlingIOLimitMs)/ms"
                                    'Enabled' = ConvertTo-TextYN $StorageLatencyControl.Enabled
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "Storage Latency Control Section: $($_.Exception.Message)"
                            }
                        }

                        if ($HealthCheck.Infrastructure.Settings) {
                            $OutObj | Where-Object { $_.'Enabled' -like 'No'} | Set-Style -Style Warning -Property 'Enabled'
                        }

                        $TableParams = @{
                            Name = "Storage Latency Control - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 35, 35, 30
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        #---------------------------------------------------------------------------------------------#
                        #                          Per Datastore Latency Control Options                              #
                        #---------------------------------------------------------------------------------------------#
                        try {
                            if ((Get-VBRInstalledLicense | Where-Object {$_.Edition -eq "EnterprisePlus"}) -and ((Get-VBRAdvancedLatencyOptions).count -gt 0)) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'Per Datastore Latency Control Options' {
                                    $OutObj = @()
                                    $StorageLatencyControls = Get-VBRAdvancedLatencyOptions
                                    foreach ($StorageLatencyControl in $StorageLatencyControls) {
                                        try {
                                            $Datastores = Find-VBRViEntity -DatastoresAndVMs -ErrorAction SilentlyContinue | Where-Object {($_.type -eq "Datastore")}
                                            $DatastoreName = ($Datastores | Where-Object {$_.Reference -eq $StorageLatencyControl.DatastoreId}).Name | Select-Object -Unique
                                            $inObj = [ordered] @{
                                                'Datastore Name' = Switch ($DatastoreName) {
                                                    $Null {$StorageLatencyControl.DatastoreId}
                                                    default {$DatastoreName}
                                                }
                                                'Latency Limit' = "$($StorageLatencyControl.LatencyLimitMs)/ms"
                                                'Throttling IO Limit' = "$($StorageLatencyControl.ThrottlingIOLimitMs)/ms"
                                            }
                                            $OutObj += [pscustomobject]$inobj
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "Per Datastore Latency Control Options Section: $($_.Exception.Message)"
                                        }
                                    }


                                    $TableParams = @{
                                        Name = "Per Datastore Latency Control Options - $VeeamBackupServer"
                                        List = $false
                                        ColumnWidths = 40, 30, 30
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                }
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "Per Datastore Latency Control Options Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Storage Latency Control Section: $($_.Exception.Message)"
        }
    }
    end {}

}