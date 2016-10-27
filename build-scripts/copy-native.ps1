param([string]$packagesFolder="../../packages", [string]$targetPath)

$nativedlls = Get-ChildItem $packagesFolder -Filter native -Recurse | where { $_.psiscontainer } | gci | %{$_.FullName} 

$count = @($nativedlls).count;
Write-Host "Copying $($count) *.dll files to: $($targetPath)" -ForegroundColor Green
foreach($nativedll in $nativedlls)
{
    Copy-Item $nativedll  $targetPath
}