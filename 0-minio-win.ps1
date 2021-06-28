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

cd C:\minio
echo @"
<service>
  <id>MinIO</id>
  <name>MinIO</name>
  <description>MinIO is a high performance object storage server</description>
  <executable>minio.exe</executable>
  <env name="MINIO_ROOT_USER" value="minioadminuser"/>
  <env name="MINIO_ROOT_PASSWORD" value="minioadminuser"/>
  <env name="MINIO_PROMETHEUS_AUTH_TYPE" value="public" />
  <arguments>server C:\minio\data1 C:\minio\data2 C:\minio\data3 C:\minio\data4</arguments>
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
C:\minio\mc.exe admin info local

New-NetFirewallRule -DisplayName "Allow-Inbound-TCP9000" -Direction Inbound -Protocol TCP -LocalPort 9090 -Action Allow
New-NetFirewallRule -DisplayName "Allow-Inbound-TCP9000" -Direction Inbound -Protocol TCP -LocalPort 9091 -Action Allow
cd C:\minio
Invoke-WebRequest -Uri https://github.com/minio/console/releases/latest/download/console-windows-amd64.exe -OutFile console.exe
Invoke-WebRequest -Uri https://github.com/prometheus/prometheus/releases/download/v2.28.0/prometheus-2.28.0.windows-amd64.zip -OutFile prometheus-2.28.0.windows-amd64.zip
Invoke-WebRequest -Uri https://github.com/winsw/winsw/releases/download/v2.11.0/WinSW.NET461.exe -OutFile console-service.exe

mkdir C:\minio\prometheus
cd C:\minio\prometheus
Expand-Archive -Path C:\minio\prometheus-2.28.0.windows-amd64.zip -DestinationPath C:\minio\prometheus

cp C:\minio\console-service.exe C:\minio\prometheus\prometheus-service.exe
cp C:\minio\prometheus\prometheus-2.28.0.windows-amd64\prometheus.exe C:\minio\prometheus\

$env:TARGETHOST = $Env:COMPUTERNAME
$env:TARGETHOST = $Env:TARGETHOST+=":9000"
write-host $env:TARGETHOST
echo @"
scrape_configs:
- job_name: minio-job
  metrics_path: /minio/v2/metrics/cluster
  scheme: https
  static_configs:
  - targets: ['$env:TARGETHOST']
  tls_config:
   insecure_skip_verify: true
"@ >prometheus.yml
echo @"
<service>
  <id>Prometheus</id>
  <name>Prometheus</name>
  <description>Prometheus for Minio</description>
  <executable>prometheus.exe</executable>
  <arguments>--config.file=C:\minio\prometheus\prometheus.yml --web.listen-address=:9091</arguments>
  <logmode>rotate</logmode>
  <serviceaccount>
    <domain>$Env:COMPUTERNAME</domain>
    <user>Administrator</user>
    <password>Password00!</password>
    <allowservicelogon>true</allowservicelogon>
  </serviceaccount>
</service>
"@ >prometheus-service.xml
./prometheus-service.exe install
start-service prometheus

cd C:\minio\
C:\minio\mc.exe admin user add local/ console miniosecuritykey
echo @"
{
        "Version": "2012-10-17",
        "Statement": [{
                        "Action": [
                                "admin:*"
                        ],
                        "Effect": "Allow",
                        "Sid": ""
                },
                {
                        "Action": [
                "s3:*"
                        ],
                        "Effect": "Allow",
                        "Resource": [
                                "arn:aws:s3:::*"
                        ],
                        "Sid": ""
                }
        ]
}
"@ >admin.json
$targetpath = "C:\minio\admin.json"
(Get-Content $targetpath) -Join "`r`n" | Set-Content $targetpath
C:\minio\mc.exe admin policy add local/ consoleAdmin admin.json
del C:\minio\admin.json
C:\minio\mc.exe admin policy set local/ consoleAdmin user=console

$env:CONSOLE_MINIO_SERVER = $Env:COMPUTERNAME
$env:CONSOLE_MINIO_SERVER = $Env:CONSOLE_MINIO_SERVER+=":9000"
$env:CONSOLE_MINIO_SERVER = "https://"+$Env:CONSOLE_MINIO_SERVER
write-host $env:CONSOLE_MINIO_SERVER
$env:CONSOLE_PROMETHEUS_URL = $Env:COMPUTERNAME
$env:CONSOLE_PROMETHEUS_URL = $Env:CONSOLE_PROMETHEUS_URL+=":9091"
$env:CONSOLE_PROMETHEUS_URL = "http://"+$Env:CONSOLE_PROMETHEUS_URL
write-host $env:CONSOLE_PROMETHEUS_URL

echo @"
<service>
  <id>MinIOConsole</id>
  <name>Console</name>
  <description>MinIO Console is a high performance object storage server</description>
  <executable>console.exe</executable>
  <env name="CONSOLE_OPTS" value="--port 9090"/>
  <env name="CONSOLE_PBKDF_PASSPHRASE" value="GSECRET"/>
  <env name="CONSOLE_PBKDF_SALT" value="SECRET" />
  <env name="CONSOLE_MINIO_SERVER" value="$env:CONSOLE_MINIO_SERVER" />
  <env name="CONSOLE_PROMETHEUS_URL" value="$env:CONSOLE_PROMETHEUS_URL" />
  <arguments>server</arguments>
  <logmode>rotate</logmode>
  <serviceaccount>
    <domain>$Env:COMPUTERNAME</domain>
    <user>Administrator</user>
    <password>Password00!</password>
    <allowservicelogon>true</allowservicelogon>
  </serviceaccount>
</service>
"@ >console-service.xml

./console-service.exe install
start-service console

mkdir $env:USERPROFILE\.console\certs\CAs
cp  $env:USERPROFILE\.minio\certs\public.crt $env:USERPROFILE\.console\certs\CAs

start https://$env:URLHOST

$env:URLHOST2 = $Env:COMPUTERNAME
$env:URLHOST2 = $Env:URLHOST2+=":9090"
write-host $env:URLHOST2

start http://$env:URLHOST2
Write-Host Done. credential is minioadminuser. Hit any key -NoNewLine
[Console]::ReadKey() | Out-Null

