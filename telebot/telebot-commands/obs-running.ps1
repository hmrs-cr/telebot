$obsProcName = "obs64"

$obsProcess = $(Get-Process -ErrorAction:Ignore $obsProcName)
if ($obsProcess) 
{
    Reply -Message "OBS is running!"
} 
else 
{
    Reply -Message "OBS is NOT running."
}