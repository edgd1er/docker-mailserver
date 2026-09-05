#!/bin/bash

usage() {
  echo "${0/*\//} --from <address1> [<address2> .. <addressN>]"
  echo "${0/*\//} --bounce <address1> [<address2> .. <addressN>]"
  echo "${0/*\//} --to <address1> [<address2> .. <addressN>]"
}

if [[ $# -lt 2 ]]; then
  usage 1>&2
  exit 1
fi

case $1 in
--from)
  shift
  while (($#)); do
    postqueue -p | grep -e "$1" | grep -Eo '^[A-F0-9]+' | postsuper -d -
    shift
  done
  exit
  ;;
--bounce)
  shift
  while (($#)); do
    postqueue -p | grep -E -B2 -e "$1" | grep MAILER-DAEMON | grep -Eo '^[A-F0-9]+' | postsuper -d -
    shift
  done
  exit
  ;;
--to)
  shift
  while (($#)); do
    postqueue -p | grep -E -B2 -e "$1" | grep -Eo '^[A-F0-9]+' | postsuper -d -
    shift
  done
  exit
  ;;
*)
  echo "Unknown option $1" >&2
  exit 1
  ;;
esac
