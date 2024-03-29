New-NetFirewallRule -DisplayName "Allow-Inbound-TCP9000" -Direction Inbound -Protocol TCP -LocalPort 9000 -Action Allow
New-NetFirewallRule -DisplayName "Allow-Inbound-TCP9001" -Direction Inbound -Protocol TCP -LocalPort 9001 -Action Allow
mkdir C:\minio
cd C:\minio
Invoke-WebRequest -Uri https://dl.min.io/client/mc/release/windows-amd64/mc.exe -OutFile mc.exe
Invoke-WebRequest -Uri https://dl.min.io/server/minio/release/windows-amd64/minio.exe -OutFile minio.exe
Invoke-WebRequest -Uri https://www.gnupg.org/ftp/gcrypt/gnutls/w32/gnutls-3.6.0-w64.zip -OutFile gnutls-3.6.0-w64.zip
Invoke-WebRequest -Uri https://github.com/winsw/winsw/releases/download/v2.11.0/WinSW.NET461.exe -OutFile minio-service.exe 

mkdir C:\minio\gnutils
Expand-Archive -Path C:\minio\gnutls-3.6.0-w64.zip -DestinationPath C:\minio\gnutils
$ENV:Path+=";C:\minio\gnutils\win64-build\bin"

mkdir $env:USERPROFILE\.minio\certs
cd $env:USERPROFILE\.minio\certs
C:\minio\gnutils\win64-build\bin\certtool.exe --generate-privkey --outfile private.key

echo @"
# X.509 Certificate options
#
# DN options

# The organization of the subject.
organization = "Example Inc."

# The organizational unit of the subject.
#unit = "sleeping dept."

# The state of the certificate owner.
state = "Example"

# The country of the subject. Two letter code.
country = "EX"

# The common name of the certificate owner.
cn = "Sally Certowner"

# In how many days, counting from today, this certificate will expire.
expiration_days = 365

# X.509 v3 extensions

# DNS name(s) of the server
dns_name = "$Env:COMPUTERNAME"

# (Optional) Server IP address
ip_address = "127.0.0.1"

# Whether this certificate will be used for a TLS server
tls_www_server
"@ >cert.cnf
ls -r -file -filter *.cnf | % { (get-content -encoding Default $_.FullName) -join "`r`n" | set-content -encoding Default $_.FullName }
C:\minio\gnutils\win64-build\bin\certtool.exe --generate-self-signed --load-privkey .\private.key --template .\cert.cnf --outfile .\public.crt
mkdir $env:USERPROFILE\mc\certs\CAs
cp  $env:USERPROFILE\.minio\certs\public.crt $env:USERPROFILE\mc\certs\CAs
certutil -addstore ROOT $env:USERPROFILE\.minio\certs\public.crt

mkdir C:\minio\data1
mkdir C:\minio\data2
mkdir C:\minio\data3
mkdir C:\minio\data4


$env:CONSOLE_MINIO_SERVER = $Env:COMPUTERNAME
$env:CONSOLE_MINIO_SERVER = $Env:CONSOLE_MINIO_SERVER+=":9000"
$env:CONSOLE_MINIO_SERVER = "https://"+$Env:CONSOLE_MINIO_SERVER
write-host $env:CONSOLE_MINIO_SERVER

cd C:\minio
echo @"
<service>
  <id>MinIO</id>
  <name>MinIO</name>
  <description>MinIO is a high performance object storage server</description>
  <executable>minio.exe</executable>
  <env name="MINIO_ROOT_USER" value="minioadminuser"/>
  <env name="MINIO_ROOT_PASSWORD" value="minioadminuser"/>
  <env name="MINIO_SERVER_URL" value="$env:CONSOLE_MINIO_SERVER" />
  <arguments>server C:\minio\data1 C:\minio\data2 C:\minio\data3 C:\minio\data4 --console-address ":9001"</arguments>
  <logmode>rotate</logmode>
  <serviceaccount>
    <domain>$Env:COMPUTERNAME</domain>
    <user>Administrator</user>
    <password>Password00!</password>
    <allowservicelogon>true</allowservicelogon>
  </serviceaccount>

</service>
"@ >minio-service.xml
./minio-service.exe install
start-service minio
Start-Sleep 10

C:\minio\mc.exe alias rm local
$env:URLHOST = $Env:COMPUTERNAME
$env:URLHOST = $Env:URLHOST+=":9000"
write-host $env:URLHOST

C:\minio\mc.exe alias set local https://$env:URLHOST minioadminuser minioadminuser

echo @"
{
	"Version": "2012-10-17",
	"Statement": [{
			"Action": [
				"admin:ServerInfo"
			],
			"Effect": "Allow",
			"Sid": ""
		},
		{
			"Action": [
				"s3:ListenBucketNotification",
				"s3:PutBucketNotification",
				"s3:GetBucketNotification",
				"s3:ListMultipartUploadParts",
				"s3:ListBucketMultipartUploads",
				"s3:ListBucket",
				"s3:HeadBucket",
				"s3:GetObject",
				"s3:GetBucketLocation",
				"s3:AbortMultipartUpload",
				"s3:CreateBucket",
				"s3:PutObject",
				"s3:DeleteObject",
				"s3:DeleteBucket",
				"s3:PutBucketPolicy",
				"s3:DeleteBucketPolicy",
				"s3:GetBucketPolicy"
			],
			"Effect": "Allow",
			"Resource": [
				"arn:aws:s3:::*"
			],
			"Sid": ""
		}
	]
}
"@ >s3user.json
$targetpath = "C:\minio\s3user.json"
(Get-Content $targetpath) -Join "`r`n" | Set-Content $targetpath
C:\minio\mc.exe admin policy add local/ s3user s3user.json
del C:\minio\s3user.json

C:\minio\mc.exe admin info local
start https://$env:URLHOST
Write-Host Done. credential is minioadminuser. Hit any key -NoNewLine
[Console]::ReadKey() | Out-Null

