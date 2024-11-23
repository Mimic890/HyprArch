# HyprArch
# Arch Linux with Hyprland
### С этой инструкцией по устаноке вы сможите с полного нуля установить у себя оригинальный Arch Linux с Hyprland'ом

После запуска ОРИГИНАЛЬНОГО образа с официального сайта: https://archlinux.org/releng/releases/

### 1.1 Сначала для дальнейшей установки нужно подключится к сети (беспроводное подключение):
`systemctl start iwd`

`iwctl`

`station list`

`station wlan0 scan`

`station get-networks`

`station wlan0 connect 'network_name'`

`quit`
#### Для проверки подключения:
`ping google.com`
### 1.2 Для упрощенной установки на русском языке нужно установить шрифт поддерживающий русский:
`setfont cyr-sun16`
### 2.1 Запускаем упрощенную установку:
`archinstall`
### 2.2 
