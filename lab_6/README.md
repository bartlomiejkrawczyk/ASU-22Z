# Setup

```s
/dyd/asu/firewall.pl
VirtualBox
```

## Wstęp

Zadanie polega na skonfigurowaniu czterech maszyn Linuxowych: **host1**, **host2**, **firewall** i **client**. Maszyny **host1** i **host2** tworzą sieć wewnetrzną oddzieloną od reszty świata maszyną **firewall**. Resztę świata reprezentuje maszyna **client**.

Interfejsy maszyn, brama i serwer DNS skonfigurowane sa zgodnie z tabelą:

| maszyna  | eth0         | eth1         | eth2 | brama       | DNS         |
|----------|--------------|--------------|------|-------------|-------------|
| host1    | 192.168.1.10 |              |      | 192.168.1.1 | 192.168.1.1 |
| host2    | 192.168.1.20 |              |      | 192.168.1.1 | 192.168.1.1 |
| firewall | 192.168.1.1  | 192.168.2.10 | dhcp | dhcp        | dhcp        |
| client   | 192.168.2.20 | dhcp         |      | dhcp        | dhcp        |

Na maszynach uruchomione są usługi:
| maszyna  | usługa               | numer portu |
|----------|----------------------|-------------|
| host1    | www                  | 80          |
| host2    | ssh                  | 22          |
| firewall | dns (caching server) | 53          |

# Dostępne konta

Maszyny wirtualne:
- konto **root** - hasło **root**
- konto **user** - hasło **user**

# Etap I

Na maszynie firewall należy zapisać reguły programu iptables powodujące:
1. Zablokowanie bezpośredniego dostępu do sieci 192.168.1.0/24 z innych sieci.
2. Przekierowanie portów 80 z host1 i 22 z host2 tak, by były dostępne z innych sieci (a w szczególności z 192.168.2.0/24).
3. Ograniczenie usługi DNS na maszynie firewall tylko do sieci 192.168.1.0/24.
4. Połączenie sieci 192.168.1.0/24 ze światem.

## Rozwiązanie

### Firewall

Zapisz podstawową konfigurację:
```s
iptables-save > ~/iptables-default
```

1. Zablokowanie bezpośredniego dostępu do sieci `192.168.1.0/24` z innych sieci. && 4. Połączenie sieci `192.168.1.0/24` ze światem.

```s
iptables -A FORWARD -i eth2 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -j ACCEPT
iptables -t nat -A POSTROUTING -j MASQUERADE
```

2. Przekierowanie portów 80 z host1 i 22 z host2 tak, by były dostępne z innych sieci (a w szczególności z `192.168.2.0/24`).

Przekierowanie portu 80 z host1:
```s
iptables -t nat -A PREROUTING -p tcp -i eth1 --dport 80 -j DNAT --to-destination 192.168.1.10:80
iptables -t nat -A PREROUTING -p tcp -i eth2 --dport 80 -j DNAT --to-destination 192.168.1.10:80
```

Przekierowanie portu 22 z host2:
```s
iptables -t nat -A PREROUTING -p tcp -i eth1 --dport 22 -j DNAT --to-destination 192.168.1.20:22
iptables -t nat -A PREROUTING -p tcp -i eth2 --dport 22 -j DNAT --to-destination 192.168.1.20:22
```

3. Ograniczenie usługi DNS na maszynie firewall tylko do sieci `192.168.1.0/24`.

Akceptacja dla sieci wewnętrznej:
```s
iptables -A INPUT -p udp --dport 53 -s 192.168.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -s 192.168.1.0/24 -j ACCEPT
```

Odrzucanie wszystkich pozostałych połączeń na port 53:
```s
iptables -A INPUT -p udp --dport 53 -j DROP
iptables -A INPUT -p tcp --dport 53 -j DROP
```


## Testowanie

| Z maszyny | Polecenie                         | Wynik      | Uwagi                                  |
|-----------|-----------------------------------|------------|----------------------------------------|
| client    | elinks firewall.                  | działa     | Kropka po nazwie!                      |
| client    | ssh user@firewall                 | działa     | Powoduje zalogowanie na maszynie host2 |
| client    | elinks 192.168.1.10               | nie działa |                                        |
| client    | ssh user@192.168.1.20             | nie działa |                                        |
| client    | dig @firewall mion.elka.pw.edu.pl | nie działa |                                        |
| host1     | elinks www.elka.pw.edu.pl         | działa     |                                        |
| host1     | ssh login@mion.elka.pw.edu.pl     | działa     |                                        |
| host2     | elinks www.elka.pw.edu.pl         | działa     |                                        |
| host2     | ssh login@mion.elka.pw.edu.pl     | działa     |                                        |


# Komendy

Na maszynie **firewall** zainstalowany jest pakiet **iptables-persistent**
```s
iptables-save > /etc/iptables/rules.v4
iptables-save # is used to dump the contents of IP or IPv6 Table in easily parseable format either to STDOUT or to a specified file.
elinks # console http browser
dig # DNS lookup utility
```

# Reguły iptables

## Oznaczenia używane w opisach

| oznaczenie | opis                                                                                                                                               |
|------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| **tbl**    | Tabela. Możliwe wartości: **filter**, **nat**, **mangle**, **raw**.  Pewnie będzie **filter** i **nat**.                                           |
| **chn**    | Łańcuch. Możliwe wartości: **INPUT**, **OUTPUT** i **FORWARD** dla tabeli **filter**, **PREROUTING**, **OUTPUT** i **POSTROUTING** dla tabeli nat. |
| **nr**     | Numer reguły w łańcuchu.                                                                                                                           |
| **tgt**    | Przeznaczenie pakietu. Zapewne wartości tego parametru to: **ACCEPT** i **DROP** (w tabeli **filter**) oraz **REDIRECT** (w tabeli **nat**).       |
| **prot**   | Protokół. Możliwe wartości: **tcp**, **udp**, **icmp**.                                                                                            |
| **addr**   | Adres IP w postaci: a.b.c.d lub a.b.c.d/m, gdzie a, b, c, d są liczbami z zakresu 0-255, m jest liczbą jedynek w masce sieci.                      |


## Podstawowe opcje

| flagi      | opis                                                                                                                              |
|------------|-----------------------------------------------------------------------------------------------------------------------------------|
| -t tbl     | Tabela, której dotyczy reguła. Ominięcie tej opcji spowoduje przyjęcie tabeli filter jako domyślnej.                              |
| -L [chn]   | Wyświetlenie listy reguł w łańcuchu **chn** (lub we wszystkich łańcuchach danej tabeli w przypadku ominięcia parametru **chn**).  |
| -F [chn]   | Usunięcie wszystkich reguł z łańcucha **chn** (lub ze wszystkich łańcuchów danej tabeli w przypadku ominięcia parametru **chn**). |
| -A chn     | Wstawienie reguły na końcu łańcucha **chn**.                                                                                      |
| -I chn nr  | Wstawienie reguły w pozycji **nr** w łańcuchu **chn**. Ominięcie parametru **nr** jest równoznaczne z przyjęciem wartości **1**.  |
| -D chn nr  | Usunięcie pozycji o numerze **nr** z łańcucha **chn**. Zamiast numeru reguły można też podać pełną specyfikację usuwanej reguły.  |
| -P chn tgt | Ustawienie domyślnej polityki: akceptacja (**ACCEPT**) lub usunięcie (**DROP**).                                                  |

## Przydatne opcje


| flagi   | opis                                                                                |
|---------|-------------------------------------------------------------------------------------|
| -p prot | Protokół, którego dotyczy reguła.                                                   |
| -s addr | Adres źródłowy datagramu.                                                           |
| -d addr | Adres docelowy datagramu.                                                           |
| -j tgt  | Określenie przeznaczenia pakietu: akceptacja (**ACCEPT**) lub usunięcie (**DROP**). |

