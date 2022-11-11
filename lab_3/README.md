# Setup

```s
/dyd/asu/cups.pl
VirtualBox
```

# Dostępne konta

- konto **root** - hasło **root**
- konto **user** - hasło **user**

# Przy założeniu adresów

| maszyna | rodzaj         |
|---------|----------------|
| host1   | serwer wydruku |
| host2   | klient         |


# Etap I

W katalogu domowym maszyny fizycznej należy utworzyć podkatalog: `cups` nadając mu prawa zapisu dla wszystkich. W opcjach maszyny wirtualnej należy dodać ten katalog do (początkowo pustej) listy katalogów współdzielonych. Po zalogowaniu sie na maszynę host1 należy zamontować ten katalog jako `/CUPS` . Przy pomocy poleceń su i touch należy sprawdzić czy np. użytkownik **anonymous** maszyny gościa ma prawa zapisu do tego katalogu.

## Rozwiązanie

### Maszyna Gospodarz

```s
cd ~/
mkdir cups
chmod 777 cups/
echo DUPA DUPA DUPA > cups/test.txt
```

### Host1

```s
cd /
mkdir CUPS
mount -t vboxsf cups /CUPS
cd CUPS/
ls
```


**/etc/rc.local**
Montuj folder przy każdym restarcie:
```s
# ...

mount.vboxsf cups /CUPS

exit 0
```

```s
reboot
cd /CUPS/
su anonymous
touch dupa.txt
# Jeśli wyskoczy `Permission denied` to i tak sprawdzić czy plik powstał.
ls
```

# Etap II

Na maszynie **host1** należy skonfigurować serwer wydruku korzystając z pakietu `CUPS`. W konfiguracji drukarki PDF należy zmienić ścieżkę wyjściową na `/CUPS`. Następnie przy pomocy programu `elinks` należy połączyć się na adres `http://localhost:631` i w zakładce **”drukarki”** spowodować wydrukowanie strony testowej. Strona ta powinna pojawić się jako plik `.pdf` w katalogu `cups`. Wydruk ten możemy obejrzeć przy pomocy przeglądarki evince na maszynie fizycznej.

## Rozwiązanie

### Host1



**/etc/cups/cups-pdf.conf**
```s
# Podmienić następujące linie w pliku:
Out ${HOME}/PDF   -> Out /CUPS
#AnonDirName ...  -> AnonDirName /CUPS
```

```s
service cups restart
elinks http://localhost:631
```

```s
Printers -> PDF -> Maintenance__ -> Print Test Page -> Go
```

### Maszyna Gospodarz

```s
evince /cups/test.pdf
```

# Etap III

Na maszynie **host1** przy pomocy programu `elinks` zmieniamy konfigurację drukarki tak aby udostępnić ją innym maszynom. Następnie ręcznie poleceniem `service` restartujemy moduł `cups`. Chwilę później drukarka powinna być dostępna na maszynie **host2**. Co możemy sprawdzić wykonując jakiś **„wydruk”** polceniem `lp`.

## Rozwiązanie

### Host1

```s
Administration__ -> Modify Printer -> Go -> (root/root) -> Continue -> [X] Share This Printer -> Continue -> Modify Printer
Administration -> [X] Share printers connected to this system -> save & wait till resets 
```

**/etc/cups/cupsd.conf**
```s
# Znaleźć odpowiednie wpisy oraz dopisać wartości
Listen localhost:631  ->  Port 631
<Location />
    Order allow, deny
    Allow all
</Location>
```

```s
service cups restart
```

### Host2

```s
lpstat -s
lpoptions -d PDF
echo DUPA DUPA DUPA > test.txt
lp test.txt
```
