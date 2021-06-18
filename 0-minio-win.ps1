New-NetFirewallRule -DisplayName "Allow-Inbound-TCP9000" -Direction Inbound -Protocol TCP -LocalPort 9000 -Action Allow
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
certtool.exe --generate-privkey --outfile private.key

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
dns_name = "localhost"

# (Optional) Server IP address
ip_address = "127.0.0.1"

# Whether this certificate will be used for a TLS server
tls_www_server
"@ >cert.cnf
ls -r -file -filter *.cnf | % { (get-content -encoding Default $_.FullName) -join "`r`n" | set-content -encoding Default $_.FullName }
certtool.exe --generate-self-signed --load-privkey private.key --template cert.cnf --outfile public.crt
mkdir $env:USERPROFILE\mc\certs\CA
cp  $env:USERPROFILE\.minio\certs\public.crt $env:USERPROFILE\mc\certs\CA

mkdir C:\minio\data1
mkdir C:\minio\data2
mkdir C:\minio\data3
mkdir C:\minio\data4

cd C:\minio
echo @"
<service>
  <id>MinIO</id>
  <name>MinIO</name>
  <description>MinIO is a high performance object storage server</description>
  <executable>minio.exe</executable>
  <env name="MINIO_ROOT_USER" value="minioadminuser"/>
  <env name="MINIO_ROOT_PASSWORD" value="minioadminuser"/>
  <arguments>server C:\minio\data1 C:\minio\data2 C:\minio\data3 C:\minio\data4</arguments>
  <logmode>rotate</logmode>
  <serviceaccount>
  <username>localhost\Administrator</username>
  <password>Password00!</password>
  <allowservicelogon>true</allowservicelogon>
</serviceaccount>
</service>
"@ >minio-service.xml
./minio-service.exe install
start-service minio
Start-Sleep 10

C:\minio\mc.exe alias rm local
C:\minio\mc.exe alias set local http://localhost:9000 minioadminuser minioadminuser
C:\minio\mc.exe admin info local
Write-Host Done. credential is minioadminuser.Hit any key -NoNewLine
[Console]::ReadKey() | Out-Null

