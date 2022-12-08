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

## Apache

### Dodaj rozszerzenie do obsługi m.in. `shtml` oraz `ldap`
```s
a2enmod include
a2enmod authnz_ldap
```

### Dodaj konta
```s
htpasswd -b -c /var/www/htpasswd ada ada
htpasswd -b /var/www/htpasswd igor igor
cat /var/www/htpasswd
```

### Dodaj `Includes` do opcji i rozszerzenie `shtml`
**/etc/apache2/apache2.conf**
```
<Directory /var/www/>
    Options Includes Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

AddType text/html shtml
AddOutputFilter INCLUDES shtml
```

### Stwórz pliki z konfiguracją
**/etc/apache2/sites-available/asu1.asu.ia.pw.edu.pl.conf**
```
<VirtualHost *:80>
    ServerName asu1.asu.ia.pw.edu.pl
    DocumentRoot /var/www
    DirectoryIndex index.shtml
</VirtualHost>
```

**/etc/apache2/sites-available/asu2.asu.ia.pw.edu.pl.conf**
```
<VirtualHost *:80>
    ServerName asu2.asu.ia.pw.edu.pl
    DocumentRoot /var/www
    DirectoryIndex index.shtml
    <Location />
        AuthUserFile /etc/apache2/htpasswd
        AuthName "HTPASSWD"
        AuthType Basic
        Require valid-user
    </Location>
</VirtualHost>
```

**/etc/apache2/sites-available/asu3.asu.ia.pw.edu.pl.conf**
```
<VirtualHost *:80>
    ServerName asu3.asu.ia.pw.edu.pl
    DocumentRoot /var/www
    DirectoryIndex index.shtml
    <Location />
        AuthName "LDAP"
        AuthType Basic
        AuthBasicProvider ldap
        AuthLDAPURL ldap://localhost/dc=asu,dc=ia,dc=pw,dc=edu,dc=pl?cn?sub
        Require valid-user
    </Location>
</VirtualHost>
```

### Aktywuj strony
```s
a2ensite asu1.asu.ia.pw.edu.pl.conf
a2ensite asu2.asu.ia.pw.edu.pl.conf
a2ensite asu3.asu.ia.pw.edu.pl.conf

service apache2 reload
```

## Test Na Wirtualce
```s
elinks asu1.asu.ia.pw.edu.pl
elinks asu2.asu.ia.pw.edu.pl
elinks asu3.asu.ia.pw.edu.pl
```

## Test Na Maszynie Hoście w Przeglądarce
```s
localhost:8030/asu1/
localhost:8030/asu2/
localhost:8030/asu3/
```

# Etap II

Podobnie jak w etapie 1 na maszynie nginx należy skonfigurować serwer www nginx i utworzyć dwa servery wirtualne: asu4.asu.ia.pw.edu.pl i asu5.asu.ia.pw.edu.pl. Dostęp do serwera asu4 powinni mieć wszyscy natomiast do serwera asu5 tylko użytkownicy mający hasła w pliku /var/www/htpasswd (należy go stworzyć i założyć konta ada i igor),

## Nginx

```s
htpasswd -b -c /var/www/htpasswd ada ada
htpasswd -b /var/www/htpasswd igor igor
cat /var/www/htpasswd
```

### Zmodyfikuj podstawową konfigurację nginx
```
rm /etc/nginx/sites-available/default
```

**/etc/nginx/sites-available/default**
```s
server {
    root /var/www;
    ssi on;
    index index.shtml;
    server_name asu4.asu.ia.pw.edu.pl;
}

server {
    root /var/www;
    ssi on;
    index index.shtml;
    server_name asu5.asu.ia.pw.edu.pl;
}
```

```s
nginx -t
nginx -s reload
```

## Test na Wirtalce
```s
elinks asu4.asu.ia.pw.edu.pl
elinks asu4.asu.ia.pw.edu.pl
```

## Test na Hoście
```s
localhost:8030/asu4/
localhost:8030/asu5/
```

# Etap III

Na maszynie proxy należy uruchomić tzw. reverse proxy wykorzystując serwer apache2 tak aby przy połączeniu na adres: http://localhost:8000/asuN/ był widoczny server http://asuN.asu.ia.pw.edu.pl/ (gdzie N=1, 2, 3, 4, 5). Uwaga! Na maszynie proxy zainstalowane są dwa serwery apache2 i nginx konkurujace o port 80. Należy przekonfigurować serwer nginx aby używał portu 81.

## Rozwiązanie

```s
rm /etc/apache2/sites-available/000-default.conf
```

**/etc/apache2/sites-available/000-default.conf**

```s
<VirtualHost *:80>
    ServerName localhost

    <Location /asu1/>
        ProxyPass http://asu1.asu.ia.pw.edu.pl:80/
    </Location>
    
    <Location /asu2/>
        ProxyPass http://asu2.asu.ia.pw.edu.pl:80/
    </Location>
    
    <Location /asu3/>
        ProxyPass http://asu3.asu.ia.pw.edu.pl:80/
    </Location>

    <Location /asu4/>
        ProxyPass http://asu4.asu.ia.pw.edu.pl:80/
    </Location>

    <Location /asu5/>
        ProxyPass http://asu5.asu.ia.pw.edu.pl:80/
    </Location>
</VirtualHost>
```

**Uwaga:** trzeba zmienić port nginx na 81 - jest ustawiony 80 w `/etc/nginx/sites-available/default` (w etapie 4 i tak będzie modyfikowany ten plik) lub :
```s
service nginx stop
```

### Restartujemy serwer
```s
a2enmod proxy_http

service apache2 restart
```

### Test na Wirtualce
```s
elinks proxy.asu.ia.pw.edu.pl:80/asu1/
elinks proxy.asu.ia.pw.edu.pl:80/asu2/
elinks proxy.asu.ia.pw.edu.pl:80/asu3/
elinks proxy.asu.ia.pw.edu.pl:80/asu4/
elinks proxy.asu.ia.pw.edu.pl:80/asu5/
```

### Test na hoście
```s
localhost:8000/asu1/
localhost:8000/asu2/
localhost:8000/asu3/
localhost:8000/asu4/
localhost:8000/asu5/
```

# Etap IV

Na maszynie proxy należy uruchomić tzw. reverse proxy wykorzystując serwer nginx na porcie 81 tak aby przy połączeniu na adres: http://localhost:8010/asuN/ był widoczny server http://asuN.asu.ia.pw.edu.pl/ (gdzie N=1, 2, 3, 4, 5).

## Rozwiązanie

```s
rm /etc/nginx/sites-available/default
```

**/etc/nginx/sites-available/default**
```s
server {
    listen 81;
    server_name localhost;

    location /asu1/ {
        proxy_pass http://asu1.asu.ia.pw.edu.pl:80/;
    }
    location /asu2/ {
        proxy_pass http://asu2.asu.ia.pw.edu.pl:80/;
    }
    location /asu3/ {
        proxy_pass http://asu3.asu.ia.pw.edu.pl:80/;
    }
    location /asu4/ {
        proxy_pass http://asu4.asu.ia.pw.edu.pl:80/;
    }
    location /asu5/ {
        proxy_pass http://asu5.asu.ia.pw.edu.pl:80/;
    }
}
```
