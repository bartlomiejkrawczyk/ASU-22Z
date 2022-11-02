# Setup

```s
/dyd/asu/dns.pl
VirtualBox
```

# Dostępne konta

- konto **root** - hasło **root**
- konto **user** - hasło **user**

# Przy założeniu adresów

| maszyna | ip           |
|---------|--------------|
| host1   | 192.168.4.10 |
| host2   | 192.168.4.20 |

Sprawdzić najpierw adres:
```s
ip a
```

# Etap I

Po zalogowaniu sie na maszynę **host1** należy skonfigurować serwer główny domeny `asu.ia.pw.edu.pl` oraz domeny odwrotnej `4.168.192.in-addr.arpa`.

Na maszynie **host2** należy skonfigurować resolver tak aby korzystał z tego serwera.

Przy pomocy poleceń `nslookup`, `ping` należy sprawdzić poprawność działania serwera.

## Rozwiązanie

### Host1
Pobierz pliki (`/etc/bind/*`) na których można się wzorować:
```s
sudo apt-get install bind9
sudo apt-get install dnsutils
```

**/etc/bind/named.conf.local**
```s
zone "asu.ia.pw.edu.pl" {
    type master;
    file "/etc/bind/master.asu.dns";
};

zone "4.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/master.asu.dns.inv";
};
```

Można wzorować się na plikach:
- `/etc/bind/db.local`
- `/etc/bind/db.127`

**/etc/bind/master.asu.dns**
```s
$TTL    86400
@   IN  SOA asu.ia.pw.edu.pl. root.asu.ia.pw.edu.pl. (
            2022110300      ; Serial - yyyymmddxx
            3600            ; Refresh - 1h
            600             ; Retry - 10m
            86400           ; Expire - 24h
            600)            ; Negative Cache TTL - 10m

@       IN  NS  host1
@       IN  A   192.168.4.10
host1   IN  A   192.168.4.10

host2   IN  A   192.168.4.20
```

**/etc/bind/master.asu.dns.inv**
```s
$TTL    86400
@   IN  SOA asu.ia.pw.edu.pl. root.asu.ia.pw.edu.pl. (
            2022110300      ; Serial - yyyymmddxx
            3600            ; Refresh - 1h
            600             ; Retry - 10m
            86400           ; Expire - 24h
            600)            ; Negative Cache TTL - 10m

@       IN  NS  host1.asu.ia.pw.edu.pl.
10      IN  PTR host1.asu.ia.pw.edu.pl.

20      IN  PTR host2.asu.ia.pw.edu.pl.
```

```s
named-checkconf named.conf.local
named-checkzone "asu.ia.pw.edu.pl" master.asu.dns
named-checkzone "4.168.192.in-addr.arpa" master.asu.dns.inv
systemctl start bind9
```

**/etc/resolv.conf**
```s
nameserver 127.0.0.1
```

```s
sudo resolvconf -u
host -t SOA asu.ia.pw.edu.pl
host -t NS asu.ia.pw.edu.pl
host host1.asu.ia.pw.edu.pl
host host2.asu.ia.pw.edu.pl
nslookup 192.168.4.10
nslookup 192.168.4.20
```

### Host2

**/etc/resolv.conf**
```s
nameserver 192.168.4.10
```

```s
host -t SOA asu.ia.pw.edu.pl
host -t NS asu.ia.pw.edu.pl
host host1.asu.ia.pw.edu.pl
host host2.asu.ia.pw.edu.pl
nslookup 192.168.4.10
nslookup 192.168.4.20
```

# Etap II

W tym etapie na maszynie **host2** konfigurujemy serwer pomocniczy (ang. slave) obydwu domen. I ponownie sprawdzamy poprawność jego działania.

## Rozwiązanie

### Host2

**/etc/bind/named.conf.local**
```s
zone "asu.ia.pw.edu.pl" {
    type slave;
    file "/etc/bind/slave.asu.dns";
    masters { 192.168.4.10 };
};

zone "4.168.192.in-addr.arpa" {
    type slave;
    file "/etc/bind/slave.asu.dns.inv";
    masters { 192.168.4.10 };
};
```

```s
named-checkconf named.conf.local
systemctl restart bind9
cat /etc/bind/slave.asu.dns
cat /etc/bind/slave.asu.dns.inv
```


**/etc/resolv.conf**
```s
nameserver 127.0.0.1
```

```s
host www.asu.ia.pw.edu.pl
host host1.asu.ia.pw.edu.pl
host host2.asu.ia.pw.edu.pl
nslookup 192.168.4.10
nslookup 192.168.4.20
```

# Etap III

Na maszynie **host1** należy skonfigurować server NFS i wyeksportować katalog `/pub` a na maszynie **host2** klienta montującego ten katalog w katalogu: **host1**.

Konfiguracja powinna być zapisana w odpowiednich plikach tak aby po restarcie maszyn eksport i montowanie wykonały się automatycznie.

## Rozwiązanie

### Host1
```s
sudo apt-get install nfs-kernel-server
cd /
mkdir pub
```

**/etc/exports**
```s
/pub 192.168.4.20/24(rw,sync,no_root_squash)
```

```s
exportfs -a
```

### Host2
```s
sudo apt-get install nfs-common
cd /
mkdir host1
```

**/etc/fstab**
```s
# <file system>         <mount point>   <type>  <options>   <dump>  <pass>
asu.ia.pw.edu.pl:/pub   /host1          nfs     defaults    0       0
```

```s
mount -a
```
