#!/usr/bin/env bash

ln -sf "$PWD/shell.sh" "$HOME/.shell.sh"
ln -sf "$PWD/shell.d" "$HOME/.shell.d"

config_files=(~/.bashrc ~/.zshrc)
for conf_file in ${config_files[@]}; do
  [ -r "${conf_file}" ] || continue
  
  source_command="[ -r ~/.shell.sh ] && source ~/.shell.sh"
  if ! grep -q "${source_command}" "${conf_file}"; then
    echo ".shell.sh is not sourced in '${conf_file}', adding this now..."
    echo "${source_command}" >> "${conf_file}"
  fi
done
