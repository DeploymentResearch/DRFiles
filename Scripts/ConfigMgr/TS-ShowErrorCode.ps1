$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
exit $tsenv.Value("ErrorReturnCode")