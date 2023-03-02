#!/bin/bash

#
# Wire
# Copyright (C) 2018 Wire Swiss GmbH
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


#!/usr/bin/env bash

ROOT_DIR=$(git rev-parse --show-toplevel)
HOOK_SRC_DIR=$ROOT_DIR/.githooks
HOOK_DST_DIR=$ROOT_DIR/.git/hooks
PRECO_DST_FILE=$HOOK_DST_DIR/pre-push


echo "Clean previous installed hooks"
if [ -f $PRECO_DST_FILE ] ; then
    rm $PRECO_DST_FILE
fi

echo "Install new hook"
cp $HOOK_SRC_DIR/pre-push $PRECO_DST_FILE

chmod +x $HOOK_DST_DIR/*
echo "Installation done"