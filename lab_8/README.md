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

## Na host1 i host2

**/etc/xymon/localclient.cfg**
```s
# DEFAULT
HOST=192.168.1.1
    ...
```

Nie wiem gdzie są pliki konfiguracyjne z logami :(

## Server

**/etc/xymon/analysis.cfg**
```s
# DEFAULT
HOST=192.168.1.1
    ...
```

**/etc/xymon/client-local.cfg**
```s
sed -i 's/messages/syslog/g' client-local.cfg
```

**/etc/xymon/hosts.cfg**
```s
127.0.0.1       localhost
192.168.1.10    host1
192.168.1.20    host2
```

**/etc/apache2/sites-available/000-default.conf**
```s
    DocumentRoot /var/www
    Alias "/xymon" "/var/lib/xymon/www" # <- dodajemy
```

**/etc/apache2/apache2.conf**
```s
<Directory /var/lib/xymon/www>
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
```


```s
service apache2 restart
```

# Etap II

Na **wszystkich** maszynach konfigurujemy pakiet `munin-node` a na maszynie **server** również pakiet `munin` tak aby obserwował wszystkie trzy maszyny. Na serwerze wymagane jest aby program `munin-cron` był uruchamiany co 5 minut. Do konfiguracji serwera www należy dodać odpowiednie wpisy aby rezultaty działania programu pojawiły się pod adresem `/munin`.

## Server
https://www.howtoforge.com/tutorial/server-monitoring-with-munin-and-monit-on-debian/
https://ubuntu.com/server/docs/tools-munin

```s
ln -s /etc/munin/apache2.conf /etc/apache2/conf-enabled/
service reload apache2
```
ale trzeba jeszcze podmieniać ręcznie `Order deny,allow` `Allow from all` na `Require all granted`. Chyba można też zmodyfikować te dwa pliki i będzie ten sam efekt:

**/etc/apache2/apache2.conf**
```s
<Directory /var/cache/munin/www>
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
```

**/etc/apache2/sites-available/000-default.conf**
```s
    DocumentRoot /var/www
    Alias "/munin" "/var/cache/munin/www" # <- dodajemy
```

**/etc/munin/munin-node.conf**
```s
host_name server.asu
```

```s
# service reload m
```

???

**/etc/cron.d/munin**
```s
...
*/5 * * * *     munin-cron --config /etc/munin/munin.conf
```

# Etap III

Na **wszystkich** maszynach zainstalowane są moduły `nagios-nrpe-server` a na maszynie **server** moduł `nagios-nrpe-plugin`. Należy zdefiniować pliki konfiguracyjne w katalogu `/etc/nagios3/config.d/` aby program monitorował wszystkie trzy maszyny obserwując połączenie z maszynami ping zajętość dysków oraz działanie usługi ssh. Do konfiguracji serwera www należy dodać odpowiednie wpisy aby rezultaty działania programu pojawiły się pod adresem `/nagios3`.

https://ubuntu.com/server/docs/tools-nagios

```s
ln -s /etc/nagios3/apache2.conf /etc/apache2/conf-enabled/nagios.conf
service reload apache2
```

```s
htpasswd /etc/nagios3/htpasswd.users nagiosadmin
```

???


# Etap IV

Wyłączamy jedną z maszyn **host1** lub **host2** i obserwujemy jak szybko zareagują poszczególne programy na to zdarzenie.

## Rozwiązanie

Wyłączamy **host2** -> PROFIT

# Sugestie
- Należy dodać użytkownika xymon do grupy adm aby miał prawo odczytu logów systemowych.
- Ponieważ w dytrybucji Ubuntu głównym plikiem logów jest `/var/log/syslog` a nie `/var/log/messages` należy dokonać odpowiedniej modyfikacji w pliku `client-local.cfg`.
- W konfiguracji `munin-node` wskazane jest użycie host name np. host1.asu aby mieć pewność, że będzie identyczne z użytym w konfiguracji serwera.
- Hało użytkownika nagiosadmin należy zdefiniować w pliku `/etc/nagios3/htpasswd.users`.
- Warto skorzystać z dostarczanych przez niektóre pakiety gotowych plików konfiguracyjnych dla serwera apache (umieszczanych zazwyczaj w katalogu `/etc/pakiet/apache2.conf`) wklejając je lub włączając przy pomocy dyrektywy include do aktualnej konfiguracji serwera.
- W wersji Apache 2.4 dyrektywy: `Order deny,allow` `Allow from all` należy zastąpić przez Require all granted
