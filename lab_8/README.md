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

# Etap II

Na **wszystkich** maszynach konfigurujemy pakiet `munin-node` a na maszynie **server** również pakiet `munin` tak aby obserwował wszystkie trzy maszyny. Na serwerze wymagane jest aby program `munin-cron` był uruchamiany co 5 minut. Do konfiguracji serwera www należy dodać odpowiednie wpisy aby rezultaty działania programu pojawiły się pod adresem `/munin`.

# Etap III

Na **wszystkich** maszynach zainstalowane są moduły `nagios-nrpe-server` a na maszynie **server** moduł `nagios-nrpe-plugin`. Należy zdefiniować pliki konfiguracyjne w katalogu `/etc/nagios3/config.d/` aby program monitorował wszystkie trzy maszyny obserwując połączenie z maszynami ping zajętość dysków oraz działanie usługi ssh. Do konfiguracji serwera www należy dodać odpowiednie wpisy aby rezultaty działania programu pojawiły się pod adresem `/nagios3`.

# Etap IV

Wyłączamy jedną z maszyn **host1** lub **host2** i obserwujemy jak szybko zareagują poszczególne programy na to zdarzenie.

# Sugestie
- Należy dodać użytkownika xymon do grupy adm aby miał prawo odczytu logów systemowych.
- Ponieważ w dytrybucji Ubuntu głównym plikiem logów jest `/var/log/syslog` a nie `/var/log/messages` należy dokonać odpowiedniej modyfikacji w pliku `client-local.cfg`.
- W konfiguracji `munin-node` wskazane jest użycie host name np. host1.asu aby mieć pewność, że będzie identyczne z użytym w konfiguracji serwera.
- Hało użytkownika nagiosadmin należy zdefiniować w pliku `/etc/nagios3/htpasswd.users`.
- Warto skorzystać z dostarczanych przez niektóre pakiety gotowych plików konfiguracyjnych dla serwera apache (umieszczanych zazwyczaj w katalogu `/etc/pakiet/apache.conf`) wklejając je lub włączając przy pomocy dyrektywy include do aktualnej konfiguracji serwera.
- W wersji Apache 2.4 dyrektywy: Order deny,allow Allow from all należy zastąpić przez Require all granted