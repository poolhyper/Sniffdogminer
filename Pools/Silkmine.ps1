. .\Include.ps1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
 
 
 $silkmineCoins_Request = [PSCustomObject]@{} 
 
 
 try { 
     $silkmine_Request = Invoke-RestMethod "https://silkmine.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
     $silkmineCoins_Request = Invoke-RestMethod "http://silkmine.com/api/currencies" -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
 } 
 catch { 
     Write-Warning "Sniffdog howled at ($Name) for a failed API check. " 
     return 
 }
 
 if (($silkmine_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
     Write-Warning "SniffDog sniffed near ($Name) but ($Name) Pool API had no scent. " 
     return 
 } 
  
$Location = "US"



$silkmine_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$silkmine_Request.$_.hashrate -gt 0} | foreach {
    $silkmine_Host = "$_.mine.silkmine.com"
    $silkmine_Port = $silkmine_Request.$_.port
    $silkmine_Algorithm = Get-Algorithm $silkmine_Request.$_.name
    $silkmine_Coin = $silkmine_Request.$_.coins
    $silkmine_Fees = $silkmine_Request.$_.fees
    $silkmine_Workers = $silkmine_Request.$_.workers


    $Divisor = 1000000
	
    switch($silkmine_Algorithm)
    {
        
#	"sha256"{$Divisor *= 1000000}
    "blake2s"{$Divisor *= 1000}
	"lyra2v2"{$Divisor *= 1000}
	"myr-gr"{$Divisor *= 1000}
	"neoscrypt"{$Divisor *= 1000}
	"nist5"{$Divisor *= 1000}
    "phi"{$Divisor *= 1000}
	"qubit"{$Divisor *= 1000}
#	"scrypt"{$Divisor *= 1000}
    "qubit"{$Divisor *= 1000}
    "skein"{$Divisor *= 1000}
	"tribus"{$Divisor *= 1000}
	"x17"{$Divisor /= 1000}
#    "yescrypt"{$Divisor /= 1000}
        
         
    }

    if((Get-Stat -Name "$($Name)_$($silkmine_Algorithm)_Profit") -eq $null){$Stat = Set-Stat -Name "$($Name)_$($silkmine_Algorithm)_Profit" -Value ([Double]$silkmine_Request.$_.estimate_last24h/$Divisor*(1-($silkmine_Request.$_.fees/100)))}
    else{$Stat = Set-Stat -Name "$($Name)_$($silkmine_Algorithm)_Profit" -Value ([Double]$silkmine_Request.$_.estimate_current/$Divisor *(1-($silkmine_Request.$_.fees/100)))}
	
    if($Wallet)
    {
        [PSCustomObject]@{
            Algorithm = $silkmine_Algorithm
            Info = "$silkmine_Coin - Coin(s)"
            Price = $Stat.Live
            Fees = $silkmine_Fees
            StablePrice = $Stat.Week
	    Workers = $silkmine_Workers
            MarginOfError = $Stat.Fluctuation
            Protocol = "stratum+tcp"
            Host = $silkmine_Host
            Port = $silkmine_Port
            User = $Wallet
            Pass = "ID=$RigName,c=$Passwordcurrency"
            Location = $Location
            SSL = $false
        }
    }
}
