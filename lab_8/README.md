# Setup

```s
/dyd/asu/monitor.pl
VirtualBox
```

## Wstęp

Zadanie polega na skonfigurowaniu monitorowania trzech maszyn Linuxowych: **host1**, **host2**, **server** o adresach `192.168.1.10`, `192.168.1.20`, `192.168.1.1`. Maszyna **server** ma pełnić rolę serwera monitorującego funkcjonowanie pozostałych maszyn i usług usług na wszystkich maszynach. Maszyna **server** ma zdefiniowanie forwardowanie portu 80 na port 8000 maszyny uxn* dzięki temu można uzyskać dostęp do działającego na niej serwera apache2 łącząc się przy pomocy przeglądarki z lokalnym portem 8000 czyli pod adresem http://localhost:8000/

# Dostępne konta

Maszyny wirtualne:
- konto **root** - hasło **root**


# Etap I

Na **wszystkich** maszynach należy skonfigurować pakiet `xymon-client` wskazując jako serwer adres IP maszyny server. Na maszynie server konfigurujemy program xymon tak aby obserwował wszystkie trzy maszyny i działające na nich usługi ssh oraz działającą na maszynie server usługę www. W konfiguracji serwera apache2 dodajemy wpisy umożliwiające dostęp do efektów działania programu xymon pod adresem: `/xymon`.

**Uwaga:** Strasznie mi się nie chce :(

## Na każdej z maszyn

```s
usermod -a -G adm xymon
```

## Server

**/etc/xymon/hosts.cfg**
```s
...
#127.0.0.1       localhost # bd ...
127.0.0.1       localhost # ssh bd ...
192.168.1.10    host1 # ssh
192.168.1.20    host2 # ssh
...
```

```s
cd /usr/lib/xymon/server/etc/

wget --no-check-certificate https://xymon.sourceforge.io/xymon/help/xymon-apacheconf.txt

mv xymon-apacheconf.txt xymon-apache.conf

sed -i 's/usr\/local/usr\/lib/g' xymon-apache.conf

echo "Include /usr/lib/xymon/server/etc/xymon-apache.conf" >> /etc/apache2/apache2.conf

service xymon restart
service apache2 restart
```

## Testowanie

Wchodzimy w firefox na http://localhost:8000/xymon/

Czekamy około 5 min i powinny maszyny się pojawić.

# Etap II

Na **wszystkich** maszynach konfigurujemy pakiet `munin-node` a na maszynie **server** również pakiet `munin` tak aby obserwował wszystkie trzy maszyny. Na serwerze wymagane jest aby program `munin-cron` był uruchamiany co 5 minut. Do konfiguracji serwera www należy dodać odpowiednie wpisy aby rezultaty działania programu pojawiły się pod adresem `/munin`.

## Host1

**/etc/munin/munin-node.conf**
```s
...
allow ^127\.0\.0\.1$
allow ^:::1$
allow ^192\.168\.1\.1$ # <- to dodajemy
...
# host_name localhost.localdomain
host_name host1.asu  # <- to dodajemy
...
```

```s
service munin-node restart
```

Na host2 analogicznie.

## Server

**/etc/munin/munin.conf**
```s
...
[localhost.localdomain]
    address 127.0.0.1
    use_node_name yes

[host1.asu]
    address 192.168.1.10
    use_node_name yes

[host2.asu]
    address 192.168.1.20
    use_node_name yes
...
```

**/etc/munin/apache.conf**
Należy zamienić wszystkie wystąpienia:
```s
    Order deny,allow
    Allow from localhost...
```
na:
```s
    Require all granted
```

```s
echo "Include /etc/munin/apache.conf" >> /etc/apache2/apache2.conf

service reload apache2
service munin restart
```

**/etc/cron.d/munin**

Generalnie może już to istnieć:
```s
...
*/5 * * * *  munin-cron --config /etc/munin/munin.conf
```

## Testowanie

Wchodzimy w firefox na http://localhost:8000/munin/

Czekamy około 5 min i powinny maszyny się pojawić.

# Etap III

Na **wszystkich** maszynach zainstalowane są moduły `nagios-nrpe-server` a na maszynie **server** moduł `nagios-nrpe-plugin`. Należy zdefiniować pliki konfiguracyjne w katalogu `/etc/nagios3/config.d/` aby program monitorował wszystkie trzy maszyny obserwując połączenie z maszynami ping zajętość dysków oraz działanie usługi ssh. Do konfiguracji serwera www należy dodać odpowiednie wpisy aby rezultaty działania programu pojawiły się pod adresem `/nagios3`.

## HostN

**/etc/nagios/nrpe.cfg**
```s
...
# allowed_hosts=127.0.0.1
allowed_hosts=127.0.0.1,192.168.1.1
...
```

```s
service nagios-nrpe-server restart
```

## Server

**/etc/nagios3/conf.d/localhost_nagios2.cfg**
```s
...
define host{
    use                 generic-host
    host_name           localhost
    alias               localhost
    address             127.0.0.1
}
define host{
    use                 generic-host
    host_name           host1
    alias               host1
    address             192.168.1.10
}
define host{
    use                 generic-host
    host_name           host2
    alias               host2
    address             192.168.1.20
}
...
define service{
    use                     generic-service
    host_name               localhost
    service_description     Disk Space
    check_command           check_all_disks!20%!10%
}
define service{
    use                     generic-service
    host_name               host1
    service_description     Disk Space
    check_command           check_all_disks!20%!10%
}
define service{
    use                     generic-service
    host_name               host2
    service_description     Disk Space
    check_command           check_all_disks!20%!10%
}
...
define service{
    use                     generic-service
    host_name               localhost
    service_description     SSH
    check_command           check_ssh
}
define service{
    use                     generic-service
    host_name               host1
    service_description     SSH
    check_command           check_ssh
}
define service{
    use                     generic-service
    host_name               host2
    service_description     SSH
    check_command           check_ssh
}
```

```s
htpasswd /etc/nagios3/htpasswd.users nagiosadmin

echo "Include /etc/nagios3/apache2.conf" >> /etc/apache2/apache2.conf

service apache2 restart
```

## Testowanie

Wchodzimy w firefox na http://localhost:8000/nagios3/

Logujemy się na konto `nagiosadmin` i hasło podane wcześniej.

Czekamy około 5 min i powinny maszyny się pojawić.

# Etap IV

Wyłączamy jedną z maszyn **host1** lub **host2** i obserwujemy jak szybko zareagują poszczególne programy na to zdarzenie.

## Rozwiązanie

Wyłączamy **host2** -> ***PROFIT***

# Sugestie
- Należy dodać użytkownika xymon do grupy adm aby miał prawo odczytu logów systemowych.
- Ponieważ w dytrybucji Ubuntu głównym plikiem logów jest `/var/log/syslog` a nie `/var/log/messages` należy dokonać odpowiedniej modyfikacji w pliku `client-local.cfg`.
- W konfiguracji `munin-node` wskazane jest użycie host name np. host1.asu aby mieć pewność, że będzie identyczne z użytym w konfiguracji serwera.
- Hało użytkownika nagiosadmin należy zdefiniować w pliku `/etc/nagios3/htpasswd.users`.
- Warto skorzystać z dostarczanych przez niektóre pakiety gotowych plików konfiguracyjnych dla serwera apache (umieszczanych zazwyczaj w katalogu `/etc/pakiet/apache2.conf`) wklejając je lub włączając przy pomocy dyrektywy include do aktualnej konfiguracji serwera.
- W wersji Apache 2.4 dyrektywy: `Order deny,allow` `Allow from all` należy zastąpić przez Require all granted
