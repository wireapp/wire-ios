#!/bin/sh

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

# WARNING: You may have to run Clean in Xcode after changing CODE_SIGN_IDENTITY!

# Verify that $CODE_SIGN_IDENTITY is set
if [ -z "${CODE_SIGN_IDENTITY}" ] ; then
    echo "CODE_SIGN_IDENTITY needs to be set for framework code-signing!"

    # if [ "${CONFIGURATION}" = "Release" ] ; then
    #     exit 1
    # else
        # Code-signing is optional for non-release builds.
        exit 0
    # fi
fi

# if [ -z "${CODE_SIGN_ENTITLEMENTS}" ] ; then
#     echo "CODE_SIGN_ENTITLEMENTS needs to be set for framework code-signing!"
# 
#     # if [ "${CONFIGURATION}" = "Release" ] ; then
#     #     exit 1
#     # else
#         # Code-signing is optional for non-release builds.
#         exit 0
#     # fi
# fi

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

FRAMEWORK_DIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

# Loop through all frameworks
FRAMEWORKS=`find "${FRAMEWORK_DIR}" -type d -name "*.framework" -or -name "*.dylib" | sed -e "s/\(.*framework\)/\1\/Versions\/A\//"`
RESULT=$?
if [[ $RESULT != 0 ]] ; then
    exit 1
fi

echo "Found:"
echo "${FRAMEWORKS}"

for FRAMEWORK in $FRAMEWORKS;
do
    echo "Signing '${FRAMEWORK}'"

    if [ -z "${CODE_SIGN_ENTITLEMENTS}" ] ; then
        `codesign --force --verbose --sign "${CODE_SIGN_IDENTITY}" "${FRAMEWORK}"`
    else
        `codesign --force --verbose --sign "${CODE_SIGN_IDENTITY}" --entitlements "${CODE_SIGN_ENTITLEMENTS}" "${FRAMEWORK}"`
    fi

    RESULT=$?
    if [[ $RESULT != 0 ]] ; then
        exit 1
    fi
done

# restore $IFS
IFS=$SAVEIFS
