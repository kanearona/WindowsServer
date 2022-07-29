$FolderOutputName = "C:\UCMD\"
$Output = @()
 
#Server = $Server.trim()
$Processor = $null
$Memory = $null
$RoundMemory = $null
$Object = $null
$time= "[{0:MM-dd-yyyy} {0:HH:mm:ss}]" -f (Get-Date)
$wallix= $env:COMPUTERNAME

#--------------------DON'T FORGET TO EDIT PROBE SERVER'S ADRESS-----------------------



        #Get Server-Uptime
        function Get-Uptime {
       $os = Get-WmiObject win32_operatingsystem
       $uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
       $Display = "" + $Uptime.Days + "D:" + $Uptime.Hours + "H:" + $Uptime.Minutes + "MN" 
       Write-Output $Display
       }

        #Get Disk-Usage
        function Get-DiskUsage{

    param([String]$Name)
    
    
        $onegb= 1024*1024*1024
        $Disk= Get-PSDrive $Name

        $used= ($Disk.Used)/$onegb
        $used=[math]::round($used, 2)
        $size= ($Disk.Used + $Disk.Free)/$onegb
        $size= [math]::round($size, 2)
        $df= ($used*100)/$size
        $df= [math]::round($df, 2)
        return $df
       
}
        

        # Get-CPU-Usage
        $Processor = (Get-WmiObject  -Class win32_processor -ErrorAction Stop | Measure-Object -Property LoadPercentage -Average | Select-Object Average).Average
 
        # Get-Memory-Usage
        $Memory = Get-WmiObject -Class win32_operatingsystem -ErrorAction Stop
        $Memory = ((($Memory.TotalVisibleMemorySize - $Memory.FreePhysicalMemory)*100)/ $Memory.TotalVisibleMemorySize)
        $RoundMemory = [math]::Round($Memory, 2)


        #Format Outputs
        $Object = New-Object PSCustomObject
        $Object | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value $time
        $Object | Add-Member -MemberType NoteProperty -Name "Server name" -Value $wallix
        $Object | Add-Member -MemberType NoteProperty -Name "Uptime" -Value $(Get-Uptime)
        $Object | Add-Member -MemberType NoteProperty -Name "CPU %" -Value $Processor
        $Object | Add-Member -MemberType NoteProperty -Name "Memory %" -Value $RoundMemory
        $Object | Add-Member -MemberType NoteProperty -Name "Disk Usage C %" -Value $(Get-DiskUsage -Name C)
        $Object | Add-Member -MemberType NoteProperty -Name "Disk Usage D %" -Value $(Get-DiskUsage -Name D)
        $Object | Add-Member -MemberType NoteProperty -Name "Disk Usage E %" -Value $(Get-DiskUsage -Name E)
        $Output += $Object
        $Output | Format-Table
       

 


        #Exporting the result to an excel CSV file and send it to probe Server
       function Export {
        If ($Output)
        { 
            $filename= "C:\" + "UCMD\UCMDtnp" + (get-date -format "MM_dd_yy_HH_mm") + ".csv"
           
            #Exporting to CSV File
            $Output| Export-Csv -Path $filename -NoTypeInformation -Force
            #Exporting to Probe Server    
           & "C:\Program Files\Putty\pscp.exe" -P 22 -i C:\keytech.ppk $filename acrosspm@192.168.78.105:/home/acrosspm/digital/UCMD/TNP
  
        }
        }
        

if (Test-Path $FolderOutputName) {
   
    Export
}
else
{
  
    #PowerShell Create directory if not exists
    New-Item $FolderName -ItemType Directory
    Export
}


        
