#!/bin/bash
set -e

spinner_pid=

TEMPLATE_APP_NAME="My Application"
TEMPLATE_NAMESPACE="com.myapplication"

app_name=""
namespace=""

function start_spinner() {
  spinchars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

  { while :; do for X in "${spinchars[@]}"; do
    echo -en "\r$1 $X"
    sleep 0.1
  done; done & } 2>/dev/null
  spinner_pid=$!
}

function stop_spinner() {
  { kill -9 $spinner_pid && wait; } 2>/dev/null
  echo -en "\033[2K\r"
}

function main() {
  ask_namespace
  ask_app_name
  rename_namespace
  rename_app_name
  find_and_move_namespace

  echo "> Success! please sync gradle."
}

function ask_namespace() {
  read -e -p "> Write your namespace or bundle id (e.g. com.utsman.ganteng): " namespace
  if [[ $namespace =~ ^[a-z]+\.[a-z]+\.[a-z]+$ ]]; then
    return
  else
    echo "Invalid package name."
    ask_namespace
  fi
}

function ask_app_name() {
  read -e -p "> Write your app name id (e.g. Utsman ganteng): " app_name
  if echo "$app_name" | grep -qE '^[A-Za-z ]+$'; then
    return
  else
    echo "Invalid app name. Only alphabets and spaces are allowed."
    ask_app_name
  fi
}

function rename_namespace() {
  start_spinner "> Find and replace namespace"
  sleep 3
  find . -type f -exec sed -i "s/$TEMPLATE_NAMESPACE.$TEMPLATE_APP_NAME/$namespace/g" {} +
  find . -type f -exec sed -i "s/$TEMPLATE_NAMESPACE/$namespace/g" {} +

  stop_spinner
}

function rename_app_name() {
  start_spinner "> Find and replace app name"
  sleep 3
  find . -type f -exec sed -i "s/$TEMPLATE_APP_NAME/$app_name/g" {} +
  stop_spinner
}

# shellcheck disable=SC2001
function find_and_move_namespace() {
  start_spinner "> Find and replace directory"
  sleep 3

  last_template_namespace=$(echo "$TEMPLATE_NAMESPACE" | cut -d'.' -f2)
  find_template_dir_namespace=$(find . -type d -name "com" -exec test -d "{}/$last_template_namespace" \; -print)
  template_dir_namespace="$find_template_dir_namespace/$last_template_namespace"

  replacement_namespace=$(echo "$namespace" | sed 's#\.#/#g')
  replacement_directory=$(echo "$template_dir_namespace" | sed "s#com/$last_template_namespace#$replacement_namespace#")

  mv "$template_dir_namespace" "$replacement_directory"
#  echo "$replacement_directory"
  stop_spinner
}

main "$@"
exit
