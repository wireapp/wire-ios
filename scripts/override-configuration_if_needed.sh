#!/bin/bash

#
# Wire
# Copyright (C) 2024 Wire Swiss GmbH
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.
#



DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

CONFIGURATION_LOCATION=wire-ios/Configuration
OVERRIDES_DIR=

usage()
{
    echo "usage: download_assets.sh [[-o | --override_with path] | [-h | --help]]"
    echo "Example: \$ download-assets.sh -o Configuration"
}

while [ "$1" != "" ]; do
    OPTION=$1
    shift

    case $OPTION in
        -o | --override_with)       OVERRIDES_DIR=$1
                                    echo "Overriding with configuration files in: ${OVERRIDES_DIR}"
                                    ;;
        -h | --help )               usage
                                    exit
                                    ;;
        * )                         usage
                                    exit 1
    esac
    shift
done

if [ ! -z "${OVERRIDES_DIR}" ]; then
    # Add trailing slash if not present so that cp would copy contents of directory
    [[ "${OVERRIDES_DIR}" != */ ]] && OVERRIDES_DIR="${OVERRIDES_DIR}/"
    echo "✅ Copying '${OVERRIDES_DIR}' over to '${CONFIGURATION_LOCATION}'"
    cp -RL "${OVERRIDES_DIR}" "${CONFIGURATION_LOCATION}"
else
    echo "No custom configuration specified, skipped copying"
fi
