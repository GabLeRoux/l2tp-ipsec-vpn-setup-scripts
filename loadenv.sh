#!/usr/bin/env bash

loadenv () {
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
	export $(cat ${1:-$DIR/.env} | xargs)
}