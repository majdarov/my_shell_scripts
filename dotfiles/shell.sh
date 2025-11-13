# Примечание: в этом скрипте нет никакой путаницы. Этот скрипт устанавливает предпочитаемую мной оболочку
# конфигурацию и должен быть доступен для загрузки из любой оболочки, подобной Bash, или
# из Z-оболочки.

# Если мы не запускаемся в интерактивном режиме, не продолжайте загружать этот файл.

case $- in
	*i*) ;;
	  *) return ;;
esac

if [ -x ~/.shell.d ]; then
  for config in ~/.shell.d/*; do
    [ -r "${config}" ] && source "${config}"
  done
  unset config
fi

if command -v "vim">/dev/null 2>&1; then
  VISUAL="vim"
  EDITOR="vim"
fi

stty -ixon

set_ps1 "deb_git" || true
