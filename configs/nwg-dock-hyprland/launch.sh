  #---------------#
 # HyprArch Dock #
#---------------#

config="$HOME/.config/gtk-4.0/settings.ini"
killall nwg-dock-hyprland
prefer_dark_theme="$(grep 'gtk-application-prefer-dark-theme' "$config" | sed 's/.*\s*=\s*//')"
style="style.css"

# Start command
nwg-dock-hyprland -i 40 -w 10 -mb 3 -ml 3 -mr 3 -hl "top" -x -p "left" -nolauncher -s $style -c "wofi --show-drun"

# -a <string> -- Alignment in full width/height: "start", "center", or "end" (default "center")
#                Выравнивание по всей ширине/высоте: «start», «center» или «end» (по умолчанию «center»)

# -c <string> -- Command assigned to the launcher button (default "nwg-drawer")
#                Команда, назначенная кнопке запуска (по умолчанию «nwg-drawer»)

# -d -- Auto-hide: show dock when hotspot hovered, close when left or a button clicked
#       Автоматическое скрытие: отображать док при наведении курсора на горячую точку, закрывать при уходе курсора или нажатии кнопки

# -debug -- Turn on debug messages
#           Включить отладочные сообщения

# -f -- Take full screen width/height
#       Занять всю ширину/высоту экрана

# -g <string> -- Quote-delimited, space-separated class list to ignore in the dock
#                Список классов, разделенных кавычками и пробелами, которые следует игнорировать в доке

# -hd <int> -- Hotspot delay [ms]; smaller values mean faster mouse pointer response to show dock; set 0 to disable (default 20)
#              Задержка горячей точки [мс]; меньшие значения означают более быструю реакцию указателя мыши на отображение дока; установите значение 0, чтобы отключить (по умолчанию 20)

# -hl <string> -- Hotspot layer: "overlay" or "top" (default "overlay")
#                 Слой горячих точек: «overlay» или «top» (по умолчанию «overlay»)

# -i <int> -- Icon size (default 48)
#             Размер значка (по умолчанию 48)

# -ico <string> -- Alternative name or path for the launcher icon
#                  Альтернативное имя или путь к значку программы запуска

# -iw <string> -- Ignore running applications on these workspaces based on workspace name or ID, e.g., "special,10"
#                 Игнорировать запущенные приложения в этих рабочих пространствах на основе имени или ID рабочего пространства, например «special,10».

# -l <string> -- Layer: "overlay", "top", or "bottom" (default "overlay")
#                Слой: «overlay», «top» или «bottom» (по умолчанию «overlay»)

# -lp <string> -- Launcher button position: "start" or "end" (default "end")
#                 Положение кнопки запуска: «start» или «end» (по умолчанию «end»)

# -m -- Allow multiple instances of the dock (skip lock file check)
#       Разрешить несколько экземпляров дока (пропустить проверку файла блокировки)

# -mb <int> -- Margin bottom
# -ml <int> -- Margin left
# -mr <int> -- Margin right
# -mt <int> -- Margin top

# -nolauncher -- Don't show the launcher button
#                Не показывать кнопку запуска

# -o <string> -- Name of output to display the dock on
#                Имя дисплея для отображения дока

# -p <string> -- Position: "bottom", "top", "left", or "right" (default "bottom")
#                Положение: «bottom», «top», «left» или «right» (по умолчанию «bottom»)

# -r -- Leave program resident, but without hotspot
#       Оставить программу резидентной, но без хотспота

# -s <string> -- Styling: CSS file name (default "style.css")

# -v -- Display version information
#       Отображение информации о версии

# -w <int> -- Number of workspaces in use (default 10)
#             Количество используемых рабочих пространств (по умолчанию 10)

# -x -- Set exclusive zone: move other windows aside; overrides the "-l" argument
#       Установить эксклюзивную зону: отодвинуть другие окна в сторону; отменяет действие аргумента «-l».
