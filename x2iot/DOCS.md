# X2IOT Gateway Add-on

Wtyczka do Home Assistant zapewniająca zaawansowaną integrację z centralami Satel Integra (przez moduły ETHM-1 Plus lub UART), MQTT, a docelowo Modbus.

## Konfiguracja
Konfiguracja znajduje się automatycznie w chronionym katalogu `/data` tego dodatku i przeżywa aktualizacje (persistent storage). WebUI umożliwia łatwą konfigurację integracji z systemem.

## Dostęp
Po uruchomieniu wtyczki zalecamy włączenie "Pokazuj na pasku bocznym" (Show in sidebar), aby uzyskać szybki dostęp do panelu X2IOT Gateway (port 8356).

## GPIO Raspberry Pi (wejścia i wyjścia)
Dodatek ma dostęp do GPIO Raspberry Pi 3 / 4 / 5 przez `/dev/gpiochip0` (interfejs znakowy jądra). W x2iot dodaj integrację „Raspberry Pi GPIO” i ustaw piny jako wejścia / wyjścia.
Nie trzeba niczego włączać w systemie hosta.

## Czujniki temperatury DS18B20 (1-Wire)
Odczyt idzie przez sterownik jądra (`/sys/bus/w1/devices`, tylko do odczytu). Magistralę 1-Wire trzeba **raz włączyć w systemie Home Assistant OS** — dodatek nie może tego zrobić sam:

1. Otwórz plik `config.txt` na partycji rozruchowej karty / dysku HAOS (np. kartę SD w innym komputerze, partycja `hassos-boot`, albo przez dostęp SSH do hosta: `/mnt/boot/config.txt`).
2. Dopisz na końcu linię:
   - `dtoverlay=w1-gpio` — czujnik na GPIO4 (pin 7) z rezystorem 4,7 kΩ między danymi a 3,3 V,
   - albo `dtoverlay=w1-gpio-pullup` — bez zewnętrznego rezystora,
   - inny pin: `dtoverlay=w1-gpio,gpiopin=N`.
3. Uruchom Home Assistant ponownie (cały system, nie tylko dodatek).
4. W x2iot dodaj integrację „1-Wire” — czujniki `28-…` pojawią się same; dodaj je jako temperatury.

Pin 1-Wire należy wtedy do jądra — nie ustawiaj go jako wejścia / wyjścia w integracji GPIO.

## Test wydajności
W zakładce **Konfiguracja** dodatku ustaw `load_test_secs` (np. `600`) i uruchom dodatek ponownie. Zamiast zwykłej pracy x2iot wykona test na wbudowanych parametrach
(4000 wejść, 2000 wyjść, 1000 temperatur, 32 obszary, mieszanka wyzwalaczy i akcji) i dopiero potem wystartuje normalnie. Integracje i interfejs w tym czasie nie działają.
Opcja sama wraca na `0`, więc kolejny start jest już zwykły. Wynik: log dodatku i plik `load_test_*.txt` (strona „Wydajność” w x2iot).
