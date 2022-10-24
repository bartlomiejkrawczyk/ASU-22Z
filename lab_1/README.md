# Setup

```shell
/dyd/asu/net.pl
```

# Dostępne konta

- konto **root** - hasło **root**
- konto **user** - hasło **user**

# Etap I

Po zalogowaniu sie na konto root należy skonfigurować interfejsy zgodnie z tabelą:

| maszyna | eth0         | eth1        | eth2 |
|---------|--------------|-------------|------|
| host1   | 192.168.1.10 | dhcp        |      |
| host1   | 192.168.2.20 | dhcp        |      |
| host1   | 192.168.1.1  | 192.168.2.1 | dhcp |

Należy też dodać wpisy do tablic routingu tak aby łączność pomiędzy maszynami **host1** i **host2** odbywała się poprzez maszynę **router**.

Przy pomocy poleceń *ping* i *tracroute* należy sprawdzić czy maszny **host1** i **host2** mają ze sobą połączenie przez maszynę **router**. Należy też sprawdzić łączność z resztą świata np. z serwerem *mion.elka.pw.edu.pl* - *194.29.160.35*.

## Potrzebna wiedza

### - Polecenie **ifconfig**

```shell
ifconfig interface [address_family] [address] [up] [down] [netmask mask] [broadcast address]
```
- address family - rodzina adresów
- address - adres interfejsu
- up down - włączenie/wyłączenie interfejsu
- netmask - maska podsieci
- broadcast - adres broadcast-owy

### - Polecenie **ip route**

```shell 
ip route add ADDR/BITS via GW 	# dodanie trasy do interfejsu
ip route add default   via GW 	# dodanie trasy domyślnej przez router
```

## Rozwiązanie

### Host1
```shell
ifconfig eth0 192.168.1.10 netmask 255.255.255.0 up
dhclient eth1
ip route add 192.168.2.0/24 via 192.168.1.1
```
### Host2
```shell
ifconfig eth0 192.168.2.20 netmask 255.255.255.0 up
dhclient eth1
ip route add 192.168.1.0/24 via 192.168.2.1
```
### Router
```shell
ifconfig eth0 192.168.1.1 netmask 255.255.255.0 up
ifconfig eth1 192.168.2.1 netmask 255.255.255.0 up
dhclient eth2
```
W przypadku gdyby nie działały testy:
```shell
sysctl net.ipv4.ip_forward=1
```

# Etap II

Należy zapisać konfigurację w plikach `/etc/hosts`, `/etc/network/interfaces`, tak aby po restarcie maszyny automatycznie konfigurowały interfejsy i routing.

## Potrzebna wiedza

### - Plik **/etc/hosts**

```shell
IP-address official-host-name nicknames...
```

- IP-address - adres IP
- official-host-name - oficjalna nazwa maszyny
- nicknames - alternatywne nazwy maszyny

#### Przykład:
```shell
127.0.0.1 localhost
148.81.31.9 abc.ghi.pw.edu.pl abc

# The following lines are desirable for IPv6 capable hosts
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

148.81.31.1 csd
148.81.31.2 csd1
148.81.31.3 csd2
148.81.31.4 csd3
```

### - Plik **/etc/network/interfaces**

#### Przykład:

```shell
# The loopback network interface
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
	address 194.29.180.10/27
	gateway 194.29.180.30
	dns-nameservers 194.29.180.10 194.29.180.22
	dns-search elka.pw.edu.pl

auto eth0:1
iface eth0:1 inet static
address 192.168.133.33/24

allow-hotplug 	eth1
iface eth1 inet dhcp
```

## Rozwiązanie

### Host1

- **/etc/hosts**
```shell
192.168.2.20	host2
192.168.1.1		router
```
- **/etc/network/interfaces**
```shell
# The loopback network interface
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
	address 192.168.1.10
	netmask 255.255.255.0
	up ip route add 192.168.2.0/24 via 192.168.1.1

auto eth1
iface eth1 inet dhcp
```

### Host2

- **/etc/hosts**
```shell
192.168.1.10	host1
192.168.2.1		router
```
- **/etc/network/interfaces**
```shell
# The loopback network interface
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
	address 192.168.2.20
	netmask 255.255.255.0
	up ip route add 192.168.1.0/24 via 192.168.2.1

auto eth1
iface eth1 inet dhcp
```

### Router

- **/etc/hosts**
```shell
192.168.1.10	host1
192.168.2.20	host2
```
- **/etc/network/interfaces**
```shell
# The loopback network interface
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
	address 192.168.1.1
	netmask 255.255.255.0

auto eth1
iface eth1 inet static
	address 192.168.2.1
	netmask 255.255.255.0

auto eth2
iface eth2 inet dhcp
```

W przypadku gdyby nie działały testy:
- **/etc/sysctl.conf**
```shell
net.ipv4.ip_forward=1
```

# Etap III

Na maszynie **host1** należy zainstalować skonfigurować server **FTP** (pakiet `vsftpd`) a na maszynie **host2** klienta (pakiet `ftp`). Konfiguracja powinna umożliwiać zalogowanemu użytkownikowi *user* zapis danych w swoim katalogu domowym.

### Host1
```shell
apt-get update
apt-get install vsftpd
```

- **/etc/vsftpd.conf**
```shell
local_enable=YES
write_enable=YES
```

Restart serwisu:
```shell
service vsftpd restart
```
	
### Host2
```shell
apt-get update
apt-get install ftp
echo DUPA DUPA DUPA > test.txt
```

Odpalić shell `ftp`:
```shell
ftp host1
```

i dalej w shellu:
```shell
put test.txt
bye
```

W katalogu domowym **user** na maszynie **host1** znajduje się plik `test.txt`
