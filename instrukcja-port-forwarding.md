## Instrukcja: Port Forwarding w VirtualBox

Forwardowanie portu 22 z maszyny wirtualnej na dowolny port na hoście umożliwia połączenie się z wirtualką przez SSH. Dzięki temu można korzystać z terminala GNOME oraz łatwo kopiować i wklejać komendy, co w kilku laboratoriach znacząco ułatwia pracę. Funkcja działa od drugiego ćwiczenia wzwyż, po zestawieniu połączenia ze światem zewnętrznym.

### 1. Konfiguracja w VirtualBox

1. Wybierz odpowiednią maszynę w VirtualBox.
2. Wejdź w **Settings → Network**.
3. Wybierz interfejs, który ma ustawione `Attached to: NAT` – zazwyczaj będzie to **Adapter 2** (odpowiedzialny za połączenie z Internetem).
4. Kliknij **Advanced → Port Forwarding → + (plusik)**.
5. Dodaj nową regułę:
   - **Protocol**: TCP  
   - **Host IP**: *(pozostaw puste)*  
   - **Host Port**: np. `2137`  
   - **Guest IP**: *(pozostaw puste)*  
   - **Guest Port**: `22`

### 2. Instalacja SSH na maszynie wirtualnej

Zaloguj się do maszyny wirtualnej przez interfejs VirtualBox i zainstaluj serwer SSH:

```bash
sudo apt update && sudo apt install ssh
```

### 3. Logowanie przez SSH z hosta

Otwórz terminal w systemie gospodarza (np. GNOME Terminal: `Ctrl + Alt + T`) i połącz się przez SSH:

```bash
ssh user@localhost -p 2137
```

Zamień `user` na odpowiednią nazwę użytkownika.

> Uwaga: Możliwe jest logowanie tylko na zwykłego użytkownika. Połączenie bezpośrednio jako `root` przez SSH jest zablokowane domyślnie.
