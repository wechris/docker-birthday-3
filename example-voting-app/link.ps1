function Get-IP {
  param( [string]$container )
  $ip = ""
  while (-not ($ip)) {
    $ipconfig = $(docker exec -it $container ipconfig)
    $ip = $ipconfig | select-string IPv4 | %{$_ -replace "^.* ", ""}
    Write-Host $($ip)
    if (-not ($ip)) {
      Sleep 1
    }
  }
  Write-Host IP of $container is $ip
  return $ip
}

function Add-Link {
  param( [string]$container, [string]$hostname, [string]$ip )
  $out = $(docker exec -it $container "cmd /c echo $ip $hostname >>C:\Windows\system32\drivers\etc\hosts")
  Write-Host docker exec -it $container "cmd /c echo $ip $hostname"

  Write-Host Add link to $hostname=$ip to container $container
}


function Open-Port {
  param( [int]$port )
  if (!(Get-NetFirewallRule | where {$_.Name -eq "DockerPort$port"})) {
      New-NetFirewallRule -Name "DockerPort$port" -DisplayName "Docker on TCP/$port" -Protocol tcp -LocalPort $port -Action Allow -Enabled True
  }
}

$voting_port = 80
$result_port = 80
Open-Port($voting_port)
Open-Port($result_port)
Open-Port(5432)
Open-Port(6379)

$db_ip = Get-IP("examplevotingapp_db_1")
$redis_ip = Get-IP("examplevotingapp_redis_1")

Add-Link -container "examplevotingapp_voting-app_1" -hostname "redis" -ip $redis_ip

Add-Link -container "examplevotingapp_worker_1" -hostname "redis" -ip $redis_ip
Add-Link -container "examplevotingapp_worker_1" -hostname "db" -ip $db_ip

Add-Link -container "examplevotingapp_result-app_1" -hostname "db" -ip $db_ip
