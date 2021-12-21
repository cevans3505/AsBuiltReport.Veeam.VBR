
function Get-AbrVbrServerInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Server Information
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Veeam V&R Server information from $System."
    }

    process {
        Section -Style Heading2 'Backup Server Information' {
            Paragraph "The following section provides a summary of the Veeam Backup Server"
            BlankLine
            $OutObj = @()
            if ((Get-VBRServerSession).Server) {
                try {
                    $BackupServers = Get-VBRServer -Type Local
                    foreach ($BackupServer in $BackupServers) {
                        Write-PscriboMessage "Discovered $BackupServer Server."
                        $inObj = [ordered] @{
                            'Server Name' = $BackupServer.Name
                            'Description' = $BackupServer.Description
                            'Type' = $BackupServer.Type
                            'Status' = Switch ($BackupServer.IsUnavailable) {
                                'False' {'Available'}
                                'True' {'Unavailable'}
                                default {$BackupServer.IsUnavailable}
                            }
                            'Api Version' = $BackupServer.ApiVersion
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                catch {
                    Write-PscriboMessage $_.Exception.Message
                }

                $TableParams = @{
                    Name = "Backup Server Information - $($BackupServer.Name.Split(".")[0])"
                    List = $true
                    ColumnWidths = 40, 60
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
    }
    end {}

}