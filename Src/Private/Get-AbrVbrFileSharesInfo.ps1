
function Get-AbrVbrFileSharesInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam File Share Information
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
        Write-PscriboMessage "Discovering Veeam VBR File Share information from $System."
    }

    process {
        if ((Get-VBRNASServer).count -gt 0) {
            Section -Style Heading3 'File Shares' {
                Paragraph "The following table provides a summary about the file shares backed-up by Veeam Server $(((Get-VBRServerSession).Server))."
                BlankLine
                $OutObj = @()
                try {
                    $ShareObjs = Get-VBRNASServer
                    foreach ($ShareObj in $ShareObjs) {
                        $Path = $Null
                        try {
                            if ($ShareObj.Type -eq 'FileServer') {
                                $Path = $ShareObj.Name
                                $AccessCredentials = $ShareObj.Server.ProxyServicesCreds.Name
                            } else {
                                $Path = Get-VBRNASServerPath -Server $ShareObj
                                $AccessCredentials = $ShareObj.AccessCredentials
                            }
                            Write-PscriboMessage "Discovered $($Path) Share."
                            $inObj = [ordered] @{
                                'Path' = $Path
                                'Type' = switch ($ShareObj.Type) {
                                    "FileServer" {"File Server"}
                                    "SANSMB" {"NAS Filler"}
                                    "SMB" {"SMB Share"}
                                    "NFS" {"NFS Share"}
                                    "SANNFS" {"NAS Filler"}
                                    Default {$ShareObj.Type}
                                }
                                'Backup IO Control' = $ShareObj.BackupIOControlLevel
                                'Credentials' = Switch (($AccessCredentials).count) {
                                    0 {"None"}
                                    default {$AccessCredentials}
                                }
                                'Cache Repository' = $ShareObj.CacheRepository.Name
                            }

                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "File Shares $($Path) Section: $($_.Exception.Message)"
                        }
                    }

                    $TableParams = @{
                        Name = "File Shares - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 30, 13, 12, 22, 23
                    }

                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-object -Property 'Path' | Table @TableParams
                }
                catch {
                    Write-PscriboMessage -IsWarning "File Shares Section: $($_.Exception.Message)"
                }
            }
        }
    }
    end {}

}