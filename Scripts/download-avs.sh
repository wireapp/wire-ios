#!/bin/bash

#
# Wire
# Copyright (C) 2016 Wire Swiss GmbH
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


export AVS_VERSION=24
export AVS_PATH="https://github.com/wireapp/avs-binaries/releases/download"
export AVS_LIBNAME=wire-avs-ios
export AVS_BASENAME=$AVS_LIBNAME.$AVS_VERSION
export AVS_FILENAME=$AVS_BASENAME.tar.bz2
export AVS_RESOLVED_PATH=$AVS_PATH/$AVS_VERSION/$AVS_FILENAME

export LIBS_PATH=./Libraries

echo "Resolved path: "
echo $AVS_RESOLVED_PATH

if [ ! -e $LIBS_PATH ]
then
    mkdir $LIBS_PATH
fi

pushd $LIBS_PATH > /dev/null

if [ -e $AVS_LIBNAME ] 
then 
    echo "Existing AVS used"
else
    echo "Downloading AVS..."
    rm $AVS_FILENAME 2> /dev/null
    rm -rf $AVS_LIBNAME 2> /dev/null
    curl -L -o $AVS_FILENAME $AVS_RESOLVED_PATH
    mkdir $AVS_LIBNAME
    tar -xvzf $AVS_FILENAME -C $AVS_LIBNAME
    
fi

popd  > /dev/null
