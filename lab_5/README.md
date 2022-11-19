# Setup

```s
/dyd/asu/mail.pl
VirtualBox
```

# Dostępne konta

Maszyny wirtualne:
- konto **root** - hasło **root**
- konto **ewa** - hasło **ewa**
- konto **jan** - hasło **jan**

Na nam maszynie host1 utworzona jest już domena DNS `asu.ia.pw.edu.pl`.

# Etap I

Należy skonfigurować program `postfix` do obsługi adresów w postaci:
- `użytkownik@asu.ia.pw.edu.pl`
- `użytkownik@host1.asu.ia.pw.edu.pl`

Oraz program `Dovecot Server` do obsługi protokołu `IMAP`.

## Rozwiązanie

Postępujemy według https://ubuntu.com/server/docs/mail-postfix - Basic Configuration.

### Host1

Dodajemy użytkowników **root**, **jan** i **ewa** oraz adres sieci `192.168.4.0/24`
```s
sudo dpkg-reconfigure postfix
```
The user interface will be displayed. On each screen, select the following values:
- Internet Site
- asu.ia.pw.edu.pl
- jan
- asu.ia.pw.edu.pl, localhost.localdomain, localhost
- No
- 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 192.168.0.0/24
- 0
- +
- all

**/etc/postfix/main.cf**:
```s
...
home_mailbox = mail/
...
```

```s
service postfix restart
```

**/etc/dovecot/dovecot.conf:**
```s
...
protocols = imap
```

**/etc/dovecot/conf.d/10-mail.conf:**
```s
...
# mail_location = maildir:~/
mail_location = maildir:~/mail
...
```

```s
service dovecot restart
```

# Etap II

Zdefiniować aliasy pocztowe:
- e.nowak dla konta ewa
- j.kowalski dla konta jan

## Rozwiązanie

1. W pliku /etc/aliases dodać dwie linie 'e.nowak: ewa' i 'j.kowalski: jan', następnie zaktualizować poleceniem '$newaliases'

### Host1

**/etc/aliases:**
```s
...
e.nowak: ewa
j.kowalski: jan
```

```s
newaliases
```

# Etap III

Na obu maszynach host1 i host2 należy skonfigurować klienta poczty `alpine` tak aby korzystał z servera **host1** poprzez protokół `IMAP`.

Foldery z pocztą odebraną i wysłaną powinny prezentować spójną zawartość na obu maszynach. Konfiguracja powinna być trwała.

## Rozwiązanie

Konfigurujemy program `alpine` na obu hostach logując się zarówno dla **jan** i **ewa**, czyli łącznie 4 razy
1. Uruchamiamy `alpine`, wchodzimy do `S Setup -> C Config` i ustawiamy według przykładu:

```s
Personal Name               = ewa
SMTP Domain                 = asu.ia.pw.edu.pl
SMTP Server (for sending)   = host1.asu.ia.pw.edu.pl
SMTP Server (for news)      = <No Value Set>
Inbox Path                  = [host1.asu.ia.pw.edu.pl:143/user=ewa] inbox
...

[Composer preferences]
[X] Allow Changing From
[ ] ...
```

2. `S Setup -> L connectionList` ustawiamy według przykładu (możliwe że pole mail/ powinno być puste lub bez /)

```s
Nickname:   Mail
Server:     host1.asu.ia.pw.edu.pl:143/user=ewa
Path:       mail/
View:
```

Tak ustawiamy dla Ewy i Jana, potem z poziomu alpine wysyłamy maila i powinno chodzić.

# Komendy

```s
/etc/postfix/main.cf
/etc/aliases
newaliases
alpine
.pine-passfile
```
