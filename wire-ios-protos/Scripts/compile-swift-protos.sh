#!/bin/bash
set -e

# Note: run this script from the wire-ios-protos directory.

# 1) Find Carthage
BASE_FOLDER=`pwd`
CARTHAGE="../Carthage"
MESSAGES_PROTO_DIR="${CARTHAGE}/Checkouts/generic-message-proto/proto"

echo "Found carthage folder in ${CARTHAGE}"

# 2) Compile Protos
function compile_proto() {
protoc "$2" \
    --proto_path="$1" \
    --swift_out="${BASE_FOLDER}/Protos/" \
    --swift_opt=FileNaming=DropPath \
    --swift_opt=Visibility=Public
}

echo "ℹ️ Compililng ${MESSAGES_PROTO_DIR}/messages.proto"
compile_proto $MESSAGES_PROTO_DIR "messages.proto"

echo "ℹ️ Compililng ${MESSAGES_PROTO_DIR}/otr.proto"
compile_proto $MESSAGES_PROTO_DIR "otr.proto"

echo "ℹ️ Compililng ${MESSAGES_PROTO_DIR}/mls.proto"
compile_proto $MESSAGES_PROTO_DIR "mls.proto"

# 3) Insert Wire Header
cd Protos

for filename in ./*.swift; do
    swift ../Scripts/generate_header.swift "$filename"
done

echo "✅ Done!"
