# OTA Example with mutual SSL authentication 

It is based on http://www.lucadentella.it/en/2017/08/25/esp32-21-mutua-autenticazione/

1. First create a folder that will contains all the files required by OpenSSL to operate as a CA in your home directory:

```
cd ~/esp/advanced_https_ota/
mkdir myCA
cd myCA
mkdir csr certs crl newcerts private
touch index.txt
echo 1000 > serial
```

2. Create the `openssl.cnf` file with:

```
# OpenSSL root CA configuration file.

[ ca ]
default_ca = CA_default

[ CA_default ]

# default folders
dir               = C:/msys32/home/virtpc/esp/advanced_https_ota/myCA
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand

# CA private key and certificate files
private_key       = $dir/private/ca.key
certificate       = $dir/certs/ca.cer

# Certificate revocation list
crlnumber         = $dir/crlnumber
crl               = $dir/crl/ca.crl
crl_extensions    = crl_ext
default_crl_days  = 30

# Use SHA-2
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 365
preserve          = no
policy            = policy_default

[ policy_default ]
commonName              = supplied
organizationalUnitName  = optional
organizationName        = optional
localityName            = optional
stateOrProvinceName     = optional
countryName             = optional
emailAddress            = optional

[ req ]
# Settings for new requests
default_bits        = 2048
distinguished_name  = req_distinguished_name
default_md          = sha256
x509_extensions     = ca_cert

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

[ ca_cert ]
# Extensions for CA certificates
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
# Extensions for server certificates
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
# Extension for CRLs
authorityKeyIdentifier=keyid:always
```

3. Need to change a path as below:

```
# default folders
dir               = C:/msys32/home/virtpc/esp/advanced_https_ota/myCA
```

4. The private key for CA. `winpty openssl genrsa -aes256 -out private/ca.key 2048`

5. Generate root CA - `winpty openssl req -config openssl.cnf -key private/ca.key -new -x509 -days 3650 -sha256 -extensions ca_cert -out certs/ca.cer`

6. Let’s now generate the server and client certificates. The steps are the same for both:

 * generate a new private key – openssl genrsa
 * generate the CSR (Certificate Signing Request) file – openssl req
 * sign the CSR file with the CA to obtain the final certificate – openssl ca

6.1 For Server certificate:
 
```
winpty openssl genrsa -out private/esp_server.key 2048
winpty openssl req -config openssl.cnf -key private/esp_server.key -new -sha256 -out csr/esp_server.csr
winpty openssl ca -config openssl.cnf -extensions server_cert -days 365 -notext -md sha256 -in csr/esp_server.csr -out certs/esp_server.cer
```

6.2 Client certificate:
```
winpty openssl genrsa -out private/esp_client.key 2048
winpty openssl req -config openssl.cnf -key private/esp_client.key -new -sha256 -out csr/esp_client.csr
winpty openssl ca -config openssl.cnf -extensions usr_cert -days 365 -notext -md sha256 -in csr/esp_client.csr -out certs/esp_client.cer
```

 * Not necessary. The way you install the P12 file on your device depends on the specific operating system it runs: on Windows you only need to double-click the file and follow the import wizard. `winpty openssl pkcs12 -export -out esp_client.pfx -inkey private/esp_client.key -in certs/esp_client.cer`

8. Run server for OTA. This command has to be run from the folder which has the firmware.bin file. - `cd ~/esp/advanced_https_ota/build`
`winpty openssl s_server -accept 8070 -WWW -CAfile ../myCA/certs/ca.cer -key ../myCA/private/esp_server.key -cert ../myCA/certs/esp_server.cer -tls1_2`

With additional logs: `winpty openssl s_server -accept 8070 -WWW -CAfile ../myCA/certs/ca.cer -key ../myCA/private/esp_server.key -cert ../myCA/certs/esp_server.cer -tls1_2 -state -Verify 3`

9. `cd ~/esp/advanced_https_ota` -> `make flash monitor`. Check the mutual SSL authentication.





10. Detailed logs:

```
1.
winpty openssl genrsa -aes256 -out private/ca.key 2048
Generating RSA private key, 2048 bit long modulus
....+++
............................................................................................
.+++
e is 65537 (0x10001)
Enter pass phrase for private/ca.key:
Verifying - Enter pass phrase for private/ca.key:

2.
winpty openssl req -config openssl.cnf -key private/ca.key -new -x509 -days 3650 -sha256 -extensions ca_cert -out certs/ca.cer
Enter pass phrase for private/ca.key:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:RU
State or Province Name []:BASH
Locality Name []:UFA
Organization Name []:Company Root Certificate
Organizational Unit Name []:CA
Common Name []:Company Root Certificate
Email Address []:ca_root@mail.com

3.
winpty openssl genrsa -out private/esp_server.key 2048
Generating RSA private key, 2048 bit long modulus
...........................................................................+++
...........................+++
e is 65537 (0x10001)

4.
winpty openssl req -config openssl.cnf -key private/esp_server.key -new -sha256 -out csr/esp_server.csr
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:RU
State or Province Name []:BASH
Locality Name []:UFA
Organization Name []:ESP_SERVER
Organizational Unit Name []:ESP_SERVER
Common Name []:192.168.0.39
Email Address []:esp_server@mail.ru

5.
winpty openssl ca -config openssl.cnf -extensions server_cert -days 365 -notext -md sha256 -in csr/esp_server.csr -out certs/esp_server.cer
Using configuration from openssl.cnf
Enter pass phrase for C:/msys32/home/virtpc/esp/advanced_https_ota/myCA/private/ca.key:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 4106 (0x100a)
        Validity
            Not Before: Jun 23 10:44:52 2019 GMT
            Not After : Jun 22 10:44:52 2020 GMT
        Subject:
            commonName                = 192.168.0.39
            organizationalUnitName    = ESP_SERVER
            organizationName          = ESP_SERVER
            localityName              = UFA
            stateOrProvinceName       = BASH
            countryName               = RU
            emailAddress              = esp_server@mail.ru
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            Netscape Cert Type:
                SSL Server
            Netscape Comment:
                OpenSSL Generated Server Certificate
            X509v3 Subject Key Identifier:
                F1:C3:E4:76:90:62:30:C7:C0:E9:52:66:93:49:E6:43:17:A8:D0:CB
            X509v3 Authority Key Identifier:
                keyid:BA:01:72:3E:D4:BF:11:D9:6B:89:D9:EC:EE:8B:90:EA:12:57:1A:6A
                DirName:/C=RU/ST=BASH/L=UFA/O=Company Root Certificate/OU=CA/CN=Company Root
 Certificate/emailAddress=ca_root@mail.com
                serial:D5:F7:65:21:06:2F:6F:0A

            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
Certificate is to be certified until Jun 22 10:44:52 2020 GMT (365 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated

6.
winpty openssl genrsa -out private/esp_client.key 2048
Generating RSA private key, 2048 bit long modulus
...+++
..........................................+++
e is 65537 (0x10001)

7.
winpty openssl req -config openssl.cnf -key private/esp_client.key -new -sha256 -out csr/esp_client.csr
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:RU
State or Province Name []:BASH
Locality Name []:UFA
Organization Name []:ESP_DEVICE
Organizational Unit Name []:DEVICE_X
Common Name []:DEVICE_N_1536847
Email Address []:esp_device@mail.ru

8.
winpty openssl ca -config openssl.cnf -extensions usr_cert -days 365 -notext -md sha256 -in csr/esp_client.csr -out certs/esp_client.cer
Using configuration from openssl.cnf
Enter pass phrase for C:/msys32/home/virtpc/esp/advanced_https_ota/myCA/private/ca.key:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 4105 (0x1009)
        Validity
            Not Before: Jun 23 09:58:58 2019 GMT
            Not After : Jun 22 09:58:58 2020 GMT
        Subject:
            commonName                = DEVICE_N_1536847
            organizationalUnitName    = DEVICE_X
            organizationName          = ESP_DEVICE
            localityName              = UFA
            stateOrProvinceName       = BASH
            countryName               = RU
            emailAddress              = esp_device@mail.ru
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            Netscape Cert Type:
                SSL Client, S/MIME
            Netscape Comment:
                OpenSSL Generated Client Certificate
            X509v3 Subject Key Identifier:
                EB:51:F4:C9:84:4A:86:1D:30:82:84:8A:00:A1:A7:0D:8D:D1:9E:91
            X509v3 Authority Key Identifier:
                keyid:BA:01:72:3E:D4:BF:11:D9:6B:89:D9:EC:EE:8B:90:EA:12:57:1A:6A

            X509v3 Key Usage: critical
                Digital Signature, Non Repudiation, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Client Authentication, E-mail Protection
Certificate is to be certified until Jun 22 09:58:58 2020 GMT (365 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated

9.
winpty openssl s_server -accept 8070 -WWW -CAfile ../myCA/certs/ca.cer -key ../myCA/private/esp_server.key -cert ../myCA/certs/esp_server.cer -tls1_2 -state -Verify 3
verify depth is 3, must return a certificate
Using default temp DH parameters
ACCEPT
bad gethostbyaddr
SSL_accept:before/accept initialization
SSL_accept:SSLv3 read client hello A
SSL_accept:SSLv3 write server hello A
SSL_accept:SSLv3 write certificate A
SSL_accept:SSLv3 write key exchange A
SSL_accept:SSLv3 write certificate request A
SSL_accept:SSLv3 flush data
depth=1 C = RU, ST = BASH, L = UFA, O = Company Root Certificate, OU = CA, CN = Company Root Certificate, ema
ilAddress = ca_root@mail.com
verify return:1
depth=0 CN = DEVICE_N_1536847, OU = DEVICE_X, O = ESP_DEVICE, L = UFA, ST = BASH, C = RU, emailAddress = esp_
device@mail.ru
verify return:1
SSL_accept:SSLv3 read client certificate A
SSL_accept:SSLv3 read client key exchange A
SSL_accept:SSLv3 read certificate verify A
SSL_accept:SSLv3 read finished A
SSL_accept:SSLv3 write session ticket A
SSL_accept:SSLv3 write change cipher spec A
SSL_accept:SSLv3 write finished A
SSL_accept:SSLv3 flush data
FILE:advanced_https_ota.bin
ACCEPT

```

ESP log:

```
ets Jun  8 2016 00:22:57

rst:0x1 (POWERON_RESET),boot:0x16 (SPI_FAST_FLASH_BOOT)
ets Jun  8 2016 00:22:57

rst:0x10 (RTCWDT_RTC_RESET),boot:0x16 (SPI_FAST_FLASH_BOOT)
configsip: 0, SPIWP:0xee
clk_drv:0x00,q_drv:0x00,d_drv:0x00,cs0_drv:0x00,hd_drv:0x00,wp_drv:0x00
mode:DIO, clock div:2
load:0x3fff0018,len:4
load:0x3fff001c,len:6520
load:0x40078000,len:11460
load:0x40080400,len:6664
entry 0x40080764
I (29) boot: ESP-IDF v4.0-dev-917-gd1da76e36 2nd stage bootloader
I (29) boot: compile time 18:25:43
I (29) boot: Enabling RNG early entropy source...
I (35) boot: SPI Speed      : 40MHz
I (39) boot: SPI Mode       : DIO
I (43) boot: SPI Flash Size : 4MB
I (47) boot: Partition Table:
I (51) boot: ## Label            Usage          Type ST Offset   Length
I (58) boot:  0 nvs              WiFi data        01 02 00009000 00004000
I (65) boot:  1 otadata          OTA data         01 00 0000d000 00002000
I (73) boot:  2 phy_init         RF data          01 01 0000f000 00001000
I (80) boot:  3 factory          factory app      00 00 00010000 00100000
I (88) boot:  4 ota_0            OTA app          00 10 00110000 00100000
I (95) boot:  5 ota_1            OTA app          00 11 00210000 00100000
I (103) boot: End of partition table
I (107) boot: Defaulting to factory image
I (112) esp_image: segment 0: paddr=0x00010020 vaddr=0x3f400020 size=0x235a0 (144800) map
I (172) esp_image: segment 1: paddr=0x000335c8 vaddr=0x3ffb0000 size=0x03290 ( 12944) load
I (177) esp_image: segment 2: paddr=0x00036860 vaddr=0x40080000 size=0x00400 (  1024) load
I (179) esp_image: segment 3: paddr=0x00036c68 vaddr=0x40080400 size=0x093a8 ( 37800) load
I (203) esp_image: segment 4: paddr=0x00040018 vaddr=0x400d0018 size=0x8bdc4 (572868) map
I (404) esp_image: segment 5: paddr=0x000cbde4 vaddr=0x400897a8 size=0x06b14 ( 27412) load
I (425) boot: Loaded app from partition at offset 0x10000
I (425) boot: Disabling RNG early entropy source...
I (426) cpu_start: Pro cpu up.
I (429) cpu_start: Application information:
I (434) cpu_start: Project name:     advanced_https_ota
I (440) cpu_start: App version:      2
I (444) cpu_start: Compile time:     Jun 23 2019 18:51:17
I (450) cpu_start: ELF file SHA256:  4418c1dd4450cae5...
I (456) cpu_start: ESP-IDF:          v4.0-dev-917-gd1da76e36
I (463) cpu_start: Starting app cpu, entry point is 0x40081098
I (0) cpu_start: App cpu up.
I (473) heap_init: Initializing. RAM available for dynamic allocation:
I (480) heap_init: At 3FFAE6E0 len 00001920 (6 KiB): DRAM
I (486) heap_init: At 3FFB9380 len 00026C80 (155 KiB): DRAM
I (492) heap_init: At 3FFE0440 len 00003AE0 (14 KiB): D/IRAM
I (499) heap_init: At 3FFE4350 len 0001BCB0 (111 KiB): D/IRAM
I (505) heap_init: At 400902BC len 0000FD44 (63 KiB): IRAM
I (511) cpu_start: Pro cpu start user code
I (530) spi_flash: detected chip: generic
I (530) spi_flash: flash io: dio
I (530) cpu_start: Starting scheduler on PRO CPU.
I (0) cpu_start: Starting scheduler on APP CPU.
I (613) wifi: wifi driver task: 3ffc0c58, prio:23, stack:3584, core=0
I (613) system_api: Base MAC address is not set, read default base MAC address from BLK0 of EFUSE
I (613) system_api: Base MAC address is not set, read default base MAC address from BLK0 of EFUSE
I (643) wifi: wifi firmware version: ec61a20
I (643) wifi: config NVS flash: enabled
I (643) wifi: config nano formating: disabled
I (643) wifi: Init dynamic tx buffer num: 32
I (643) wifi: Init data frame dynamic rx buffer num: 32
I (653) wifi: Init management frame dynamic rx buffer num: 32
I (653) wifi: Init management short buffer num: 32
I (663) wifi: Init static rx buffer size: 1600
I (663) wifi: Init static rx buffer num: 10
I (673) wifi: Init dynamic rx buffer num: 32
I (673) example_connect: Connecting to xxxxxx...
I (763) phy: phy_version: 4100, 2a5dd04, Jan 23 2019, 21:00:07, 0, 0
I (773) wifi: mode : sta (24:0a:c4:03:bb:68)
I (2103) wifi: new:<12,2>, old:<1,0>, ap:<255,255>, sta:<12,2>, prof:1
I (3083) wifi: state: init -> auth (b0)
I (3093) wifi: state: auth -> assoc (0)
I (3093) wifi: state: assoc -> run (10)
I (3433) wifi: connected with xxxx, channel 12, bssid = _____________________
I (3433) wifi: pm start, type: 1

I (3543) wifi: ampdu: ignore deleting tx BA0
I (4103) tcpip_adapter: sta ip: 192.168.0.2, mask: 255.255.255.0, gw: 192.168.0.1
I (4103) example_connect: Connected to dlink12
I (4103) example_connect: IPv4 address: 192.168.0.2
I (4113) advanced_https_ota_example: Starting Advanced OTA example
I (11213) esp_https_ota: Starting OTA...
I (11223) esp_https_ota: Writing to partition subtype 16 at offset 0x110000
I (11223) advanced_https_ota_example: Running firmware version: 2
I (34983) esp_https_ota: Connection closed, all data received
I (34983) esp_image: segment 0: paddr=0x00110020 vaddr=0x3f400020 size=0x235a0 (144800) map
I (35093) esp_image: segment 1: paddr=0x001335c8 vaddr=0x3ffb0000 size=0x03290 ( 12944)
I (35113) esp_image: segment 2: paddr=0x00136860 vaddr=0x40080000 size=0x00400 (  1024)
I (35113) esp_image: segment 3: paddr=0x00136c68 vaddr=0x40080400 size=0x093a8 ( 37800)
I (35143) esp_image: segment 4: paddr=0x00140018 vaddr=0x400d0018 size=0x8bdc4 (572868) map
I (35573) esp_image: segment 5: paddr=0x001cbde4 vaddr=0x400897a8 size=0x06b14 ( 27412)
I (35613) esp_image: segment 0: paddr=0x00110020 vaddr=0x3f400020 size=0x235a0 (144800) map
I (35743) esp_image: segment 1: paddr=0x001335c8 vaddr=0x3ffb0000 size=0x03290 ( 12944)
I (35753) esp_image: segment 2: paddr=0x00136860 vaddr=0x40080000 size=0x00400 (  1024)
I (35763) esp_image: segment 3: paddr=0x00136c68 vaddr=0x40080400 size=0x093a8 ( 37800)
I (35793) esp_image: segment 4: paddr=0x00140018 vaddr=0x400d0018 size=0x8bdc4 (572868) map
I (36223) esp_image: segment 5: paddr=0x001cbde4 vaddr=0x400897a8 size=0x06b14 ( 27412)
I (36283) advanced_https_ota_example: ESP_HTTPS_OTA upgrade successful. Rebooting ...
I (37283) wifi: state: run -> init (0)
I (37283) wifi: pm stop, total sleep time: 9750510 us / 33849233 us

I (37283) wifi: new:<12,0>, old:<12,2>, ap:<255,255>, sta:<12,2>, prof:1
E (37283) tcpip_adapter: handle_sta_disconnected 197 esp_wifi_internal_reg_rxcb ret=0x3014
I (37293) example_connect: Wi-Fi disconnected, trying to reconnect...
E (37303) wifi: esp_wifi_connect 1134 wifi not start
I (37303) wifi: flush txESP_ERROR_CHECK failed: esp_err_t 0x3002 (ESP_ERR_WIFI_NOT_STARTED) at 0x4008948c
file: "C:/msys32/home/virtpc/esp/q
I (37323) wifi: stop sw txq
esp-idf/examples/common_components/protocol_examples_common/connect.c" line 105
fuI (37333) wifi: lmac stop hw txq
ncets Jun  8 2016 00:22:57

rst:0xc (SW_CPU_RESET),boot:0x16 (SPI_FAST_FLASH_BOOT)
configsip: 0, SPIWP:0xee
clk_drv:0x00,q_drv:0x00,d_drv:0x00,cs0_drv:0x00,hd_drv:0x00,wp_drv:0x00
mode:DIO, clock div:2
load:0x3fff0018,len:4
load:0x3fff001c,len:6520
load:0x40078000,len:11460
load:0x40080400,len:6664
entry 0x40080764
I (29) boot: ESP-IDF v4.0-dev-917-gd1da76e36 2nd stage bootloader
I (29) boot: compile time 18:25:43
I (29) boot: Enabling RNG early entropy source...
I (35) boot: SPI Speed      : 40MHz
I (39) boot: SPI Mode       : DIO
I (43) boot: SPI Flash Size : 4MB
I (47) boot: Partition Table:
I (51) boot: ## Label            Usage          Type ST Offset   Length
I (58) boot:  0 nvs              WiFi data        01 02 00009000 00004000
I (66) boot:  1 otadata          OTA data         01 00 0000d000 00002000
I (73) boot:  2 phy_init         RF data          01 01 0000f000 00001000
I (81) boot:  3 factory          factory app      00 00 00010000 00100000
I (88) boot:  4 ota_0            OTA app          00 10 00110000 00100000
I (95) boot:  5 ota_1            OTA app          00 11 00210000 00100000
I (103) boot: End of partition table
I (107) esp_image: segment 0: paddr=0x00110020 vaddr=0x3f400020 size=0x235a0 (144800) map
I (167) esp_image: segment 1: paddr=0x001335c8 vaddr=0x3ffb0000 size=0x03290 ( 12944) load
I (172) esp_image: segment 2: paddr=0x00136860 vaddr=0x40080000 size=0x00400 (  1024) load
I (174) esp_image: segment 3: paddr=0x00136c68 vaddr=0x40080400 size=0x093a8 ( 37800) load
I (198) esp_image: segment 4: paddr=0x00140018 vaddr=0x400d0018 size=0x8bdc4 (572868) map
I (399) esp_image: segment 5: paddr=0x001cbde4 vaddr=0x400897a8 size=0x06b14 ( 27412) load
I (421) boot: Loaded app from partition at offset 0x110000
I (421) boot: Disabling RNG early entropy source...
I (421) cpu_start: Pro cpu up.
I (425) cpu_start: Application information:
I (430) cpu_start: Project name:     advanced_https_ota
I (435) cpu_start: App version:      3
I (440) cpu_start: Compile time:     Jun 23 2019 18:52:37
I (446) cpu_start: ELF file SHA256:  c10dcce8aa208d6c...
I (452) cpu_start: ESP-IDF:          v4.0-dev-917-gd1da76e36
I (458) cpu_start: Starting app cpu, entry point is 0x40081098
I (450) cpu_start: App cpu up.
I (469) heap_init: Initializing. RAM available for dynamic allocation:
I (476) heap_init: At 3FFAE6E0 len 00001920 (6 KiB): DRAM
I (482) heap_init: At 3FFB9380 len 00026C80 (155 KiB): DRAM
I (488) heap_init: At 3FFE0440 len 00003AE0 (14 KiB): D/IRAM
I (494) heap_init: At 3FFE4350 len 0001BCB0 (111 KiB): D/IRAM
I (501) heap_init: At 400902BC len 0000FD44 (63 KiB): IRAM
I (507) cpu_start: Pro cpu start user code
I (525) spi_flash: detected chip: generic
I (526) spi_flash: flash io: dio
I (526) cpu_start: Starting scheduler on PRO CPU.
I (0) cpu_start: Starting scheduler on APP CPU.
I (609) wifi: wifi driver task: 3ffc0c58, prio:23, stack:3584, core=0
I (609) system_api: Base MAC address is not set, read default base MAC address from BLK0 of EFUSE
I (609) system_api: Base MAC address is not set, read default base MAC address from BLK0 of EFUSE
I (639) wifi: wifi firmware version: ec61a20
I (639) wifi: config NVS flash: enabled
I (639) wifi: config nano formating: disabled
I (639) wifi: Init dynamic tx buffer num: 32
I (639) wifi: Init data frame dynamic rx buffer num: 32
I (649) wifi: Init management frame dynamic rx buffer num: 32
I (649) wifi: Init management short buffer num: 32
I (659) wifi: Init static rx buffer size: 1600
I (659) wifi: Init static rx buffer num: 10
I (669) wifi: Init dynamic rx buffer num: 32
I (669) example_connect: Connecting to dlink12...
I (759) phy: phy_version: 4100, 2a5dd04, Jan 23 2019, 21:00:07, 0, 0
I (769) wifi: mode : sta (24:0a:c4:03:bb:68)
I (1739) wifi: new:<12,2>, old:<1,0>, ap:<255,255>, sta:<12,2>, prof:1
I (2719) wifi: state: init -> auth (b0)
I (2719) wifi: state: auth -> assoc (0)
I (2729) wifi: state: assoc -> run (10)
I (3129) wifi: connected with dlink12, channel 12, bssid = 78:54:2e:e4:eb:74
I (3129) wifi: pm start, type: 1

I (4099) tcpip_adapter: sta ip: 192.168.0.2, mask: 255.255.255.0, gw: 192.168.0.1
I (4099) example_connect: Connected to dlink12
I (4099) example_connect: IPv4 address: 192.168.0.2
I (4109) advanced_https_ota_example: Starting Advanced OTA example
I (11759) esp_https_ota: Starting OTA...
I (11759) esp_https_ota: Writing to partition subtype 17 at offset 0x210000
I (11759) advanced_https_ota_example: Running firmware version: 3
W (11769) advanced_https_ota_example: Current running version is the same as a new. We will not continue the update.
E (11779) advanced_https_ota_example: image header verification failed
E (11789) advanced_https_ota_example: ESP_HTTPS_OTA upgrade failed...

```