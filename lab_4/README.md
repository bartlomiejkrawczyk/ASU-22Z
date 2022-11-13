# Setup

```s
/dyd/asu/ldap.pl
VirtualBox
```

# Dostępne konta

Maszyny wirtualne:
- konto **root** - hasło **root**
- konto **user** - hasło **user**

Serwer LDAP:
- konto **admin** - hasło **admin**

# Przy założeniu adresów

| maszyna | rodzaj                   |
|---------|--------------------------|
| host1   | serwer OpenLDAP / klient |
| host2   | klient                   |


# Etap I

Należy też dodać do bazy LDAP konto użytkownika:
- login: `jan`
- hasło: `jan`
- uid: `5000`
- gid: `5000`
- katalog domowy: `/home/users/jan`
- powłoka logowania: `/bin/bash`

Wraz z innymi niezbędnymi obiektami LDAP (np. grupami). Zgodnie z przykładami pokazanymi w dokumentacji.

Katalog domowy użytkownika został utworzony na maszynie **host1** z `uid=5000` i `gid=5000`. I jest on automatycznie montowany na maszynie **host2**.

## Rozwiązanie

### Host1

**~/jan.ldif**
```s
dn: ou=People,dc=ia,dc=pw,dc=edu,dc=pl
ou: People
objectClass: organizationalUnit
structuralObjectClass: organizationalUnit

dn: uid=jan,ou=People,dc=ia,dc=pw,dc=edu,dc=pl
uid: jan
cn: Jan Kowalski
# objectClass: inetOrgPerson ?
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: jan
loginShell: /bin/bash
uidNumber: 5000
gidNumber: 5000
homeDirectory: /home/users/jan
gecos: Jan Kowalski,,,
sn: Kowalski
givenName: Jan
displayName: Jan Kowalski
structuralObjectClass: account
```

```s
ldapadd -x -D cn=admin,dc=asu,dc=ia,dc=pw,dc=edu,dc=pl -W -f ~/jan.ldif
```

# Etap II

Na obu maszynach **host1** i **host2** należy skonfigurować uwierzytelnianie użytkowników przez LDAP.

Po skonfigurowaniu LDAP użytkownik powinien móc się zalogować zarówno na maszynie **host1**, jak i na **host2**. Konfiguracja powinna być trwała.


## Rozwiązanie

### Host2

```s
sudo auth-client-config -t nss -p lac_ldap
sudo pam-auth-update
```

# Komendy

```s
auth-client-config
getent
ldapadd
pam-auth-update
slapcat
```