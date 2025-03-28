
function Get-AbrVbrSureBackup {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam VBR SureBackup Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.0
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
        Write-PscriboMessage "Discovering Veeam VBR SureBackup information from $System."
    }

    process {
        try {
            if (((Get-VBRApplicationGroup).count -gt 0) -or ((Get-VBRVirtualLab).count -gt 0)) {
                Section -Style Heading3 'SureBackup Configuration' {
                    Paragraph "The following section provides configuration information about SureBackup."
                    BlankLine
                    try {
                        if ((Get-VBRApplicationGroup).count -gt 0) {
                            Section -Style Heading4 'Application Groups' {
                                Paragraph "The following section provides a summary about Application Groups."
                                BlankLine
                                $OutObj = @()
                                try {
                                    $SureBackupAGs = Get-VBRApplicationGroup
                                    foreach ($SureBackupAG in $SureBackupAGs) {
                                        Write-PscriboMessage "Discovered $($SureBackupAG.Name) Application Group."
                                        $inObj = [ordered] @{
                                            'Name' = $SureBackupAG.Name
                                            'VM List' = $SureBackupAG.VM -join ", "
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    }
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning "SureBackup Configuration $($SureBackupAG.Name) Section: $($_.Exception.Message)"
                                }

                                $TableParams = @{
                                    Name = "Application Group - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 50, 50
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                            }
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "SureBackup Configuration Section: $($_.Exception.Message)"
                    }
                    if ((Get-VBRApplicationGroup).count -gt 0) {
                        if ($InfoLevel.Infrastructure.SureBackup -ge 2) {
                            try {
                                $SureBackupAGs = Get-VBRApplicationGroup | Sort-Object -Property Name
                                foreach ($SureBackupAG in $SureBackupAGs) {
                                    if ($SureBackupAG.VM) {
                                        Section -Style Heading5 "$($SureBackupAG.Name) VM Settings" {
                                            foreach ($VMSetting in $SureBackupAG.VM) {
                                                try {
                                                    Section -Style NOTOCHeading4 -ExcludeFromTOC $($VMSetting.Name) {
                                                        $OutObj = @()
                                                        Write-PscriboMessage "Discovered $($VMSetting.Name) Application Group VM Setting."
                                                        $inObj = [ordered] @{
                                                            'VM Name' = $VMSetting.Name
                                                            'Credentials' = ConvertTo-EmptyToFiller $VMSetting.Credentials
                                                            'Role' = ConvertTo-EmptyToFiller ($VMSetting.Role -join ", ")
                                                            'Test Script' = ConvertTo-EmptyToFiller ($VMSetting.TestScript.PredefinedApplication -join ", ")
                                                            'Startup Options' = SWitch ($VMSetting.StartupOptions) {
                                                                "" {"-"; break}
                                                                $Null {"-"; break}
                                                                default {$VMSetting.StartupOptions | ForEach-Object {"Allocated Memory: $($_.AllocatedMemory)`r`nHeartbeat Check: $(ConvertTo-TextYN $_.VMHeartBeatCheckEnabled)`r`nMaximum Boot Time: $($_.MaximumBootTime)`r`nApp Init Timeout: $($_.ApplicationInitializationTimeout)`r`nPing Check: $(ConvertTo-TextYN $_.VMPingCheckEnabled)"}}
                                                            }
                                                        }

                                                        $OutObj += [pscustomobject]$inobj

                                                        $TableParams = @{
                                                            Name = "Application Group VM Settings - $($VMSetting.Name)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning "SureBackup Application Group VM Settings $($VMSetting.Name) Section: $($_.Exception.Message)"
                                                }
                                            }

                                        }
                                    }
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "SureBackup Application Group VM Settings Section: $($_.Exception.Message)"
                            }
                        }
                    }
                    if ((Get-VBRVirtualLab).count -gt 0) {
                        try {
                            Section -Style Heading4 'Virtual Labs' {
                                Paragraph "The following section provides a summary about SureBackup Virtual Lab."
                                BlankLine
                                $OutObj = @()
                                try {
                                    $SureBackupVLs = Get-VBRVirtualLab
                                    foreach ($SureBackupVL in $SureBackupVLs) {
                                        Write-PscriboMessage "Discovered $($SureBackupVL.Name) Virtual Lab."
                                        $inObj = [ordered] @{
                                            'Name' = $SureBackupVL.Name
                                            'Platform' = $SureBackupVL.Platform
                                            'Physical Host' = $SureBackupVL.Server.Name.split(".")[0]
                                            'Physical Host Version' = $SureBackupVL.Server.Info.Info
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    }
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning "SureBackup Virtual Labs $($SureBackupVL.Name) Section: $($_.Exception.Message)"
                                }

                                $TableParams = @{
                                    Name = "Virtual Lab - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 30, 15, 20, 35
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                if ($InfoLevel.Infrastructure.SureBackup -ge 2) {
                                    try {
                                        $SureBackupVLs = Get-VBRViVirtualLabConfiguration | Sort-Object -Property Name
                                        if ($SureBackupVLs) {
                                            Section -Style Heading5 "vSphere Virtual Labs Configuration" {
                                                foreach ($SureBackupVL in $SureBackupVLs) {
                                                    try {
                                                        Section -Style Heading6 "$($SureBackupVL.Name) Settings" {
                                                            $OutObj = @()
                                                            Write-PscriboMessage "Discovered $($SureBackupVL.Name) Virtual Lab."
                                                            $inObj = [ordered] @{
                                                                'Host' = $SureBackupVL.Server.Name
                                                                'Resource Pool' = $SureBackupVL.DesignatedResourcePoolName
                                                                'VM Folder' =  $SureBackupVL.DesignatedVMFolderName
                                                                'Cache Datastore' = $SureBackupVL.CacheDatastore
                                                                'Proxy Appliance Enabled' = ConvertTo-TextYN $SureBackupVL.ProxyApplianceEnabled
                                                                'Proxy Appliance' = $SureBackupVL.ProxyAppliance
                                                                'Networking Type' = $SureBackupVL.Type
                                                                'Production Network' = $SureBackupVL.NetworkMapping.ProductionNetwork.NetworkName
                                                                'Isolated Network' = $SureBackupVL.NetworkMapping.IsolatedNetworkName
                                                                'Routing Between vNics' = ConvertTo-TextYN $SureBackupVL.RoutingBetweenvNicsEnabled
                                                                'Multi Host' = ConvertTo-TextYN $SureBackupVL.IsMultiHost
                                                                'Static IP Mapping' = ConvertTo-TextYN $SureBackupVL.StaticIPMappingEnabled
                                                            }

                                                            $OutObj += [pscustomobject]$inobj

                                                            $TableParams = @{
                                                                Name = "Virtual Lab Settings - $($SureBackupVL.Name)"
                                                                List = $true
                                                                ColumnWidths = 40, 60
                                                            }
                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Table @TableParams
                                                            try {
                                                                Section -Style NOTOCHeading6 -ExcludeFromTOC "vNIC Settings" {
                                                                    $OutObj = @()
                                                                    foreach ($NetworkOption in $SureBackupVL.NetworkOptions) {
                                                                        $inObj = [ordered] @{
                                                                            'Isolated Network' = $NetworkOption.NetworkMappingRule.IsolatedNetworkName
                                                                            'VLAN ID' = $NetworkOption.NetworkMappingRule.VLANID
                                                                            'DHCP Enabled' = ConvertTo-TextYN $NetworkOption.DHCPEnabled
                                                                            'Network Properties' = "IP Address: $($NetworkOption.IPAddress)`r`nSubnet Mask: $($NetworkOption.SubnetMask)`r`nMasquerade IP: $($NetworkOption.MasqueradeIPAddress)`r`nDNS Server: $($NetworkOption.DNSServer)"
                                                                        }

                                                                        $OutObj += [pscustomobject]$inobj
                                                                    }

                                                                    $TableParams = @{
                                                                        Name = "vNIC Settings - $($SureBackupVL.Name)"
                                                                        List = $false
                                                                        ColumnWidths = 45, 10, 10, 35
                                                                    }
                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Sort-Object -Property 'VLAN ID' | Table @TableParams
                                                                }
                                                            }
                                                            catch {
                                                                Write-PscriboMessage -IsWarning "SureBackup vSphere $($SureBackupVL.Name) vNIC Settings Section: $($_.Exception.Message)"
                                                            }
                                                            try {
                                                                if ($SureBackupVL.IpMappingRule) {
                                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC "IP Address Mapping" {
                                                                        $OutObj = @()
                                                                        foreach ($NetworkOption in $SureBackupVL.IpMappingRule) {
                                                                            $inObj = [ordered] @{
                                                                                'Production Network' = $NetworkOption.ProductionNetwork.Name
                                                                                'Isolated IP Address' = $NetworkOption.IsolatedIPAddress
                                                                                'Access IP Address' = $NetworkOption.AccessIPAddress
                                                                                'Notes' = ConvertTo-EmptyToFiller $NetworkOption.Note
                                                                            }

                                                                            $OutObj += [pscustomobject]$inobj
                                                                        }

                                                                        if ($HealthCheck.Infrastructure.BestPractice) {
                                                                            $OutObj | Where-Object { $Null -like $_.'Notes'} | Set-Style -Style Warning -Property 'Notes'
                                                                        }

                                                                        $TableParams = @{
                                                                            Name = "IP Address Mapping - $($SureBackupVL.Name)"
                                                                            List = $false
                                                                            ColumnWidths = 30, 15, 15, 40
                                                                        }
                                                                        if ($Report.ShowTableCaptions) {
                                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                        }
                                                                        $OutObj | Sort-Object -Property 'Production Network' | Table @TableParams
                                                                        if ($HealthCheck.Infrastructure.BestPractice) {
                                                                            if ($OutObj | Where-Object { $Null -like $_.'Notes' }) {
                                                                                Paragraph "Health Check:" -Bold -Underline
                                                                                BlankLine
                                                                                Paragraph {
                                                                                    Text "Best Practice:" -Bold
                                                                                    Text "It is a general rule of good practice to establish well-defined notes. This helps to speed up the fault identification process, as well as enabling better documentation of the environment."
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            catch {
                                                                Write-PscriboMessage -IsWarning "SureBackup vSphere $($SureBackupVL.Name) IP Address Mapping Section: $($_.Exception.Message)"
                                                            }
                                                        }
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning "SureBackup vSphere $($SureBackupVL.Name) Settings Section: $($_.Exception.Message)"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning "SureBackup vSphere Virtual Labs Configuration Section: $($_.Exception.Message)"
                                    }
                                    try {
                                        $SureBackupVLs = try {Get-VBRHvVirtualLabConfiguration | Sort-Object -Property Name} catch {$Null}
                                        if ($SureBackupVLs) {
                                            Section -Style Heading5 "Hyper-V Virtual Labs Configuration" {
                                                foreach ($SureBackupVL in $SureBackupVLs) {
                                                    try {
                                                        Section -Style Heading6 "$($SureBackupVL.Name) Settings" {
                                                            $OutObj = @()
                                                            Write-PscriboMessage "Discovered $($SureBackupVL.Name) Virtual Lab."
                                                            $inObj = [ordered] @{
                                                                'Host' = $SureBackupVL.Server.Info.DNSName
                                                                'Path' =  $SureBackupVL.Path
                                                                'Proxy Appliance Enabled' = ConvertTo-TextYN $SureBackupVL.ProxyApplianceEnabled
                                                                'Proxy Appliance' = $SureBackupVL.ProxyAppliance
                                                                'Networking Type' = $SureBackupVL.Type
                                                                'Isolated Network' = $SureBackupVL.IsolatedNetworkOptions.IsolatedNetworkName
                                                                'Static IP Mapping' = ConvertTo-TextYN $SureBackupVL.StaticIPMappingEnabled
                                                            }

                                                            $OutObj += [pscustomobject]$inobj

                                                            $TableParams = @{
                                                                Name = "Virtual Lab Settings - $($SureBackupVL.Name)"
                                                                List = $true
                                                                ColumnWidths = 40, 60
                                                            }
                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Table @TableParams
                                                            try {
                                                                Section -Style NOTOCHeading6 -ExcludeFromTOC "vNIC Settings" {
                                                                    $OutObj = @()
                                                                    foreach ($NetworkOption in $SureBackupVL.IsolatedNetworkOptions) {
                                                                        $inObj = [ordered] @{
                                                                            'Isolated Network' = $NetworkOption.IsolatedNetworkName
                                                                            'VLAN ID' = $NetworkOption.IsolatedNetworkVLanID
                                                                            'DHCP Enabled' = ConvertTo-TextYN $NetworkOption.DHCPEnabled
                                                                            'Network Properties' = "IP Address: $($NetworkOption.IPAddress)`r`nSubnet Mask: $($NetworkOption.SubnetMask)`r`nMasquerade IP: $($NetworkOption.MasqueradeIPAddress)`r`nDNS Server: $($NetworkOption.DNSServer)"
                                                                        }

                                                                        $OutObj += [pscustomobject]$inobj
                                                                    }

                                                                    $TableParams = @{
                                                                        Name = "vNIC Settings - $($SureBackupVL.Name)"
                                                                        List = $false
                                                                        ColumnWidths = 45, 10, 10, 35
                                                                    }
                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Sort-Object -Property 'VLAN ID' | Table @TableParams
                                                                }
                                                            }
                                                            catch {
                                                                Write-PscriboMessage -IsWarning "SureBackup Hyper-V $($SureBackupVL.Name) vNIC Settings Section: $($_.Exception.Message)"
                                                            }
                                                            try {
                                                                if ($SureBackupVL.StaticIPMappingEnabled) {
                                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC "IP Address Mapping" {
                                                                        $OutObj = @()
                                                                        foreach ($NetworkOption in $SureBackupVL.StaticIPMappingRule) {
                                                                            $inObj = [ordered] @{
                                                                                'Production Network' = $NetworkOption.ProductionNetwork.NetworkName
                                                                                'Isolated IP Address' = $NetworkOption.IsolatedIPAddress
                                                                                'Access IP Address' = $NetworkOption.AccessIPAddress
                                                                                'Notes' = $NetworkOption.Note
                                                                            }

                                                                            $OutObj += [pscustomobject]$inobj
                                                                        }

                                                                        if ($HealthCheck.Infrastructure.BestPractice) {
                                                                            $OutObj | Where-Object { $Null -like $_.'Notes'} | Set-Style -Style Warning -Property 'Notes'
                                                                        }

                                                                        $TableParams = @{
                                                                            Name = "IP Address Mapping - $($SureBackupVL.Name)"
                                                                            List = $false
                                                                            ColumnWidths = 30, 15, 15, 40
                                                                        }
                                                                        if ($Report.ShowTableCaptions) {
                                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                        }
                                                                        $OutObj | Sort-Object -Property 'Production Network' | Table @TableParams
                                                                        if ($HealthCheck.Infrastructure.BestPractice) {
                                                                            if ($OutObj | Where-Object { $Null -like $_.'Notes' }) {
                                                                                Paragraph "Health Check:" -Bold -Underline
                                                                                BlankLine
                                                                                Paragraph {
                                                                                    Text "Best Practice:" -Bold
                                                                                    Text "It is a general rule of good practice to establish well-defined notes. This helps to speed up the fault identification process, as well as enabling better documentation of the environment."
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            catch {
                                                                Write-PscriboMessage -IsWarning "SureBackup Hyper-V $($SureBackupVL.Name) IP Address Mapping Section: $($_.Exception.Message)"
                                                            }
                                                        }
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning "SureBackup $($SureBackupVL.Name) Settings Section: $($_.Exception.Message)"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning "SureBackup Hyper-V Virtual Labs Configuration Section: $($_.Exception.Message)"
                                    }
                                }
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "SureBackup Virtual Labs Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "SureBackup Configuration Document: $($_.Exception.Message)"
        }
    }
    end {}
}