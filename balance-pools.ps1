Add-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue
## Specify TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 

## Specify your vCenter here.
    Connect-VIServer vCenterServer.your.local
    
$Clusters = get-Cluster

Function Select-size {
            
            ## Separator
                write-host "`n======================================"
            
            ## Display the cluster / vApp being worked on
                    if ($cluster) {Write-host "Cluster Name       : " -nonewline; Write-Host $Cluster      -f Green}
                                   Write-Host "Resouce Pool / vApp: " -nonewline; Write-Host $ResourcePool -f Green
                    $script:CPU_shares = $null
                    $script:RAM_shares = $null

            ## Instead of asking for shares values, just ask if it should be high, medium or low.
                    write-host -f Cyan "`nPlease classify this system."
                    $Selection = Read-Host "
                    H: High   CPU/RAM shares`
                    M: Medium CPU/RAM shares`
                    L: Low    CPU/RAM shares `
                --------------------------------------`
                    A: mAin menu`
                    Q: Quit`
                    
            Please make a selection H/M/L/A/Q"

                    Switch ($Selection)
                        {
                        'H' {$script:CPU_shares = 2000
                             $script:RAM_shares = 20}
                        'M' {$script:CPU_shares = 1000
                             $script:RAM_shares = 10}                            
                        'L' {$script:CPU_shares = 500
                             $script:RAM_shares = 5}
                        'A' {main-menu}
                        'Q' {exit}
                        default {Select-size}
                        }
 write-host `n                       
}

Function Display-CPU-Result {
                        If ($PoolCPUdiff -eq "0") {
                        write-host "CPU shares currently: " -NoNewline; write-host -f Green  $resourceCurrentCPUShares
                        write-host "CPU shares should be: " -NoNewline; write-host -f Cyan   $ResourceCPU_shares_new                    
                    }
                    Else { ## Instead of displaying the information, offer to input new values
                        write-host "======================================"
                        write-host -f cyan "Please make a selection."
                        write-host `n
                        write-host "CPU shares currently: " -NoNewline; write-host -f Yellow $resourceCurrentCPUShares
                        write-host "CPU shares should be: " -NoNewline; write-host -f Cyan   $ResourceCPU_shares_new

                        $update = read-host "
                        U: Update CPU shares from $resourceCurrentCPUShares to $ResourceCPU_shares_new`
                        N: No changes`
                    
                    Update the shares? U/N"

                        Switch ($update)
                            {
                            'U' {   if     ($ResourcePool.ExtensionData -like ('*VirtualApp*'))   {Set-vapp         -vapp         $resourcepool -NumCpuShares $ResourceCPU_shares_new}
                                    elseif ($ResourcePool.ExtensionData -like ('*ResourcePool*')) {Set-resourcepool -ResourcePool $resourcepool -NumCpuShares $ResourceCPU_shares_new}
                                    else   {Write-Host -f Red "error, no action taken"}
                                    }
                            'N' {}
                            default {Display-CPU-Result}
                            }
                        }
                    
                    write-host ""
                    }

Function Display-RAM-Result {
                    If ($PoolRAMdiff -eq "0") {
                        write-host "RAM shares currently: " -NoNewline; write-host -f Green  $RresourceCurrentRAMShares
                        write-host "RAM shares should be: " -NoNewline; write-host -f Cyan   $ResourceRAM_shares_new
                    }
                    Else { ## Instead of displaying the information, offer to input new values
                        write-host "RAM shares currently: " -NoNewline; write-host -f Yellow $RresourceCurrentRAMShares
                        write-host "RAM shares should be: " -NoNewline; write-host -f Cyan   $ResourceRAM_shares_new

                        $update = read-host "
                        U: Update RAM shares from $RresourceCurrentRAMShares to $ResourceRAM_shares_new`
                        N: No changespe`
                    
                    Update the shares? U/N"

                        Switch ($update)
                            {
                            'U' {   if     ($ResourcePool.ExtensionData -like ('*VirtualApp*'))   {Set-vapp         -vapp         $resourcepool -NumMemShares $ResourceRAM_shares_new}
                                    elseif ($ResourcePool.ExtensionData -like ('*ResourcePool*')) {Set-resourcepool -ResourcePool $resourcepool -NumMemShares $ResourceRAM_shares_new}
                                    else   {Write-Host -f Red "error, no action taken"}
                                }
                            'N' {}
                            default {Display-RAM-Result}
                            }
                    }
                    
                    write-host ""
                    }

Function Update-all-pools {
    foreach ($Cluster in $Clusters) 
        {
        
        ## Get the resource pools for this cluster, omit the hidden pool named Resources
        $Resources  = $Cluster | Get-vApp 
        $Resources += $Cluster | Get-resourcepool | where-object {$_.name -notlike "*Resources*"}
        
        if ($Resources) {
                        
            foreach ($ResourcePool in $Resources) {

            ## Get the variables I want
                    $ResourceVMs              = Get-VM -Location $ResourcePool ## All of the VMs in this pool
                    $ResourcePoweredOnvCPUs   = ($ResourceVMs | <#Where-Object {$_.PowerState -eq "PoweredOn" } |#> Measure-Object NumCpu -Sum).Sum    ## Measures vCPUs for only powered on VMs in this pool
                    $ResourcePoweredOnvRAM    = ($ResourceVMs | <#Where-Object {$_.PowerState -eq "PoweredOn" } |#> Measure-Object MemoryMB -Sum).Sum  ## Measures Memory in MB for only powered on VMs in this pool
                    $ResourceCPUCores         = ($ResourceVMs | <#Where-Object {$_.PowerState -eq "PoweredOn" } |#> Measure-Object NumCpu -Sum).Sum    ## Measures vCPU Cores for only powered on VMs in this pool
                    $resourceCurrentCPUShares = $ResourcePool.NumCpuShares
                    $RresourceCurrentRAMShares = $ResourcePool.NumMemShares

            ## Run the size selection function
                    Select-size

            ## Calculate pool shares based on information read from pool multiplied by information read from user
                    $ResourceCPU_shares_new = [int]$CPU_shares * [int]$ResourceCPUCores
                    $ResourceRAM_shares_new = [int]$RAM_shares * [int]$ResourcePoweredOnvRAM

            ## Calculate difference between current and recommended shares
                    $PoolCPUdiff = [int]$resourceCurrentCPUShares - [int]$ResourceCPU_shares_new
                    $PoolRAMdiff = [int]$RresourceCurrentRAMShares - [int]$ResourceRAM_shares_new

            Display-CPU-Result

            Display-RAM-Result

            }
        }
    }
}

Function Update-one-pool {

    $cluster = $null
    $input = Read-Host "Please enter the name of the resource pool"
    $resourcepool = get-vapp $input

                ## Get my variables
                    $ResourceVMs              = Get-VM -Location $ResourcePool ## All of the VMs in this pool
                    $ResourcePoweredOnvCPUs   = ($ResourceVMs | <#Where-Object {$_.PowerState -eq "PoweredOn" } |#> Measure-Object NumCpu -Sum).Sum    ## Measures vCPUs for only powered on VMs in this pool
                    $ResourcePoweredOnvRAM    = ($ResourceVMs | <#Where-Object {$_.PowerState -eq "PoweredOn" } |#> Measure-Object MemoryMB -Sum).Sum  ## Measures Memory in MB for only powered on VMs in this pool
                    $ResourceCPUCores         = ($ResourceVMs | <#Where-Object {$_.PowerState -eq "PoweredOn" } |#> Measure-Object NumCpu -Sum).Sum    ## Measures vCPU Cores for only powered on VMs in this pool
                    $resourceCurrentCPUShares = $ResourcePool.NumCpuShares
                    $RresourceCurrentRAMShares = $ResourcePool.NumMemShares

            ## Run the size selection function
                    Select-size

            ## Calculate pool shares based on information read from pool multiplied by information read from user
                    $ResourceCPU_shares_new = [int]$CPU_shares * [int]$ResourceCPUCores
                    $ResourceRAM_shares_new = [int]$RAM_shares * [int]$ResourcePoweredOnvRAM

            ## Calculate difference between current and recommended shares
                    $PoolCPUdiff = [int]$resourceCurrentCPUShares - [int]$ResourceCPU_shares_new
                    $PoolRAMdiff = [int]$RresourceCurrentRAMShares - [int]$ResourceRAM_shares_new

            Display-CPU-Result

            Display-RAM-Result

}

Function List-Resources {
    write-host "Resource / parent cluster"
    foreach ($Cluster in $Clusters)
    {
        ## Get the resource pools for this cluster, omit the hidden pool named Resources
        $Resources  = $Cluster | Get-vApp 
        $Resources += $Cluster | Get-resourcepool | where-object {$_.name -notlike "*Resources*"}

        foreach ($Resource in $Resources)
            {   
                write-host -f Green $Resource.Name -NoNewline; write-host " (" -NoNewline; write-host -f Cyan $Cluster.Name -NoNewline; write-host ")"
            }
    }


}


function Main-menu {
    write-host "======================================"
    write-host -f cyan "Please make a selection."

    $value = read-host "
        A: Update all vApps / Resource Pools`
        O: Update one vApp  / Resource Pool`
        L: List   all vApps / Resource Pools`
        X: Exit`

    Please make a selection (A/O/L/X)"
            Switch ($value)
                {
                'A' {Update-all-pools
                     Main-Menu}
                'O' {Update-one-pool
                     main-menu}
                'L' {List-Resources
                    Main-menu}
                'X' {exit}
                default {main-menu}
                }
                }
                
main-menu   
