# Setup

```s
/dyd/asu/www.pl
VirtualBox
```

## Wstęp


# Dostępne konta

Maszyny wirtualne:
- konto **root** - hasło **root**
- konto **user** - hasło **user**

# Etap I

Na maszynie apache należy skonfigurować server www apache2. Należy utworzyć trzy serwery wirtualne asu1.asu.ia.pw.edu.pl, asu2.asu.ia.pw.edu.pl i asu3.asu.ia.pw.edu.pl. Dla każdego z serwerów trzeba stworzyć jedną stronę z nazwą tego serwera. Dostęp do serwera asu1 powinni mieć wszyscy natomiast do serwera asu2 tylko użytkownicy mający hasła w pliku /var/www/htpasswd (należy go stworzyć i założyć konta ada i igor), a do server-a asu3 tylko użytkownicy zdefiniowani w usłudze LDAP. Do stworzenia stron serwerów należy użyć plik /var/www/index.shtml. Wykorzystuje on „Server Side Includes” (SSI) co wymaga kilku dodatkowych poleceń konfiguracyjnych w definicji serwera wirtualnego aby zdefiniowana w nim tabelka pokazywała poprawne dane.

## Rozwiązanie

- https://www.liquidweb.com/kb/configure-apache-virtual-hosts-ubuntu-18-04/
- https://ubiq.co/tech-blog/how-to-enable-server-side-includes-ssi-in-apache/
- http://ubuntu.flowconsult.at/en/apache2-ssi-installation/

### Podstawowa konfiguracja stron
```s
mkdir -p /var/www/asu1.asu.ia.pw.edu.pl/public_html
mkdir -p /var/www/asu2.asu.ia.pw.edu.pl/public_html
mkdir -p /var/www/asu3.asu.ia.pw.edu.pl/public_html

cp /var/www/index.shtml /var/www/asu1.ia.pw.edu.pl/public_html/
cp /var/www/index.shtml /var/www/asu2.ia.pw.edu.pl/public_html/
cp /var/www/index.shtml /var/www/asu3.ia.pw.edu.pl/public_html/

# ln -s /etc/apache2/mods-available/include.load /etc/apache2/mods-enabled
# ln -s /etc/apache2/mods-available/auth_basic.load /etc/apache2/mods-enabled
a2enmod authnz_ldap

cd /etc/apache2/sites-available
cp ./000-default.conf ./asu1.asu.ia.pw.edu.pl.conf
cp ./000-default.conf ./asu2.asu.ia.pw.edu.pl.conf
cp ./000-default.conf ./asu3.asu.ia.pw.edu.pl.conf
```

**/etc/apache2/sites-available/asuN.asu.ia.pw.edu.pl.conf**
```s
...
# DocumentRoot /var/www/html
DocumentRoot /var/www/asuN.asu.ia.pw.edu.pl/public_html
...
```

**/etc/apache2/apache2.conf**
```s
...
# <Directory /var/www/>
# 	...
# </Directory>

<Directory /var/www/>
	Options +Indexes +FollowSymLinks +MultiViews +Includes
	AllowOverride None
    Require all granted
    DirectoryIndex index.shtml
	AddType text/html .shtml
	AddOutputFilter INCLUDES .shtml
</Directory>
...
```

**/etc/apache2/sites-available/asu1.asu.ia.pw.edu.pl**
```s
<VirtualHost *:80>
    ...
    ServerName asu1.asu.ia.pw.edu.pl
    ...
</VirtualHost>
```

```s
htpasswd -b -c /var/www/htpasswd ada ada
htpasswd -b /var/www/htpasswd igor igor
cat /var/www/htpasswd
```

**/etc/apache2/sites-available/asu2.asu.ia.pw.edu.pl**
```s
<VirtualHost *:80>
    ...
    ServerName asu2.asu.ia.pw.edu.pl
    ...
    <Directory /var/www>
        AuthType Basic
        AuthName "Restricted Content"
        AuthUserFile /var/www/htpasswd
        Require valid-user
    </Directory>
</VirtualHost>
```

**/etc/apache2/sites-available/asu3.asu.ia.pw.edu.pl**
```s
<VirtualHost *:80>
    ...
    ServerName asu3.asu.ia.pw.edu.pl
    ...
    <Directory /var/www>
        Order deny,allow
        Deny from All
        AuthName "LDAP"
        AuthType Basic
        AuthBasicProvider ldap
        AuthzLDAPAuthoritative off # Tutaj jest jeszcze jakiś problem
        AuthLDAPUrl ldap://asu.ia.pw.edu.pl/ou=People,dc=asu,dc=ia,dc=pw,dc=edu,dc=pl?uid
        Require valid-user
        Satisfy any
    </Directory>
</VirtualHost>
```


```s
a2dissite ./000-default.conf
a2ensite ./asu1.asu.ia.pw.edu.pl.conf
a2ensite ./asu2.asu.ia.pw.edu.pl.conf
a2ensite ./asu3.asu.ia.pw.edu.pl.conf
service apache2 restart
```

```s
elinks asu1.asu.ia.pw.edu.pl
elinks asu2.asu.ia.pw.edu.pl
elinks asu3.asu.ia.pw.edu.pl
```

# Etap II

Podobnie jak w etapie 1 na maszynie nginx należy skonfigurować serwer www nginx i utworzyć dwa servery wirtualne: asu4.asu.ia.pw.edu.pl i asu5.asu.ia.pw.edu.pl. Dostęp do serwera asu4 powinni mieć wszyscy natomiast do serwera asu5 tylko użytkownicy mający hasła w pliku /var/www/htpasswd (należy go stworzyć i założyć konta ada i igor),

## Rozwiązanie

```s
htpasswd -b -c /var/www/htpasswd ada ada
htpasswd -b /var/www/htpasswd igor igor
cat /var/www/htpasswd
```

# Etap III

Na maszynie proxy należy uruchomić tzw. reverse proxy wykorzystując serwer apache2 tak aby przy połączeniu na adres: http://localhost:8000/asuN/ był widoczny server http://asuN.asu.ia.pw.edu.pl/ (gdzie N=1, 2, 3, 4, 5). Uwaga! Na maszynie proxy zainstalowane są dwa serwery apache2 i nginx konkurujace o port 80. Należy przekonfigurować serwer nginx aby używał portu 81.


## Rozwiązanie


# Etap IV

Na maszynie proxy należy uruchomić tzw. reverse proxy wykorzystując serwer nginx na porcie 81 tak aby przy połączeniu na adres: http://localhost:8010/asuN/ był widoczny server http://asuN.asu.ia.pw.edu.pl/ (gdzie N=1, 2, 3, 4, 5).


## Rozwiązanie



# Komendy
