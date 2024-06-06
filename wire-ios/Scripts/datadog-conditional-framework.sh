#!/bin/sh
set -x

if [[ ${DATADOG_IMPORT} -eq 1 ]]; then
    echo "KEEP COPY OF DATADOG FRAMEWORK";
else
    echo "REMOVE TRACE OF DATADOG FRAMEWORK";

    rm -rf "$BUILT_PRODUCTS_DIR/DatadogCore.o"
    rm -rf "$BUILT_PRODUCTS_DIR/DatadogCrashReporting.o"
    rm -rf "$BUILT_PRODUCTS_DIR/DatadogInternal.o"
    rm -rf "$BUILT_PRODUCTS_DIR/DatadogLogs.o"
    rm -rf "$BUILT_PRODUCTS_DIR/DatadogPrivate.o"
    rm -rf "$BUILT_PRODUCTS_DIR/DatadogTrace.o"
    rm -rf "$BUILT_PRODUCTS_DIR/DatadogRUM.o"
    
    
    rm -rf "$BUILT_PRODUCTS_DIR/DatadogCore.swiftmodule"
    rm -rf "$BUILT_PRODUCTS_DIR/DatadogCrashReporting.swiftmodule"
    rm -rf "$BUILT_PRODUCTS_DIR/DatadogLogs.swiftmodule"
    rm -rf "$BUILT_PRODUCTS_DIR/DatadogRUM.swiftmodule"
    rm -rf "$BUILT_PRODUCTS_DIR/DatadogInternal.swiftmodule"
    rm -rf "$BUILT_PRODUCTS_DIR/DatadogTrace.swiftmodule"

    rm -rf "$BUILT_PRODUCTS_DIR/Datadog_DatadogCore.bundle"
    rm -rf "$BUILT_PRODUCTS_DIR/Datadog_DatadogCrashReporting.bundle"
    rm -rf "$BUILT_PRODUCTS_DIR/Datadog_DatadogRUM.bundle"

    rm -rf "$BUILT_PRODUCTS_DIR/Wire.app/Datadog_DatadogCore.bundle"
    rm -rf "$BUILT_PRODUCTS_DIR/Wire.app/Datadog_DatadogCrashReporting.bundle"
    rm -rf "$BUILT_PRODUCTS_DIR/Wire.app/Datadog_DatadogRUM.bundle"
    
    rm -rf "$BUILT_PRODUCTS_DIR/Wire.app/PlugIns/Wire Notification Service Extension.appex/Datadog_DatadogCore.bundle"
    rm -rf "$BUILT_PRODUCTS_DIR/Wire.app/PlugIns/Wire Notification Service Extension.appex/Datadog_DatadogCrashReporting.bundle"
    rm -rf "$BUILT_PRODUCTS_DIR/Wire.app/PlugIns/Wire Notification Service Extension.appex/Datadog_DatadogRUM.bundle"

    rm -rf "$BUILT_PRODUCTS_DIR/Wire.app/PlugIns/Wire Share Extension.appex/Datadog_DatadogCore.bundle"
    rm -rf "$BUILT_PRODUCTS_DIR/Wire.app/PlugIns/Wire Share Extension.appex/Datadog_DatadogCrashReporting.bundle"
    rm -rf "$BUILT_PRODUCTS_DIR/Wire.app/PlugIns/Wire Share Extension.appex/Datadog_DatadogRUM.bundle"

    rm -rf "$BUILT_PRODUCTS_DIR/Wire Notification Service Extension.appex/Datadog_DatadogCore.bundle"
    rm -rf "$BUILT_PRODUCTS_DIR/Wire Notification Service Extension.appex/Datadog_DatadogCrashReporting.bundle"
    rm -rf "$BUILT_PRODUCTS_DIR/Wire Notification Service Extension.appex/Datadog_DatadogRUM.bundle"

    rm -rf "$BUILT_PRODUCTS_DIR/Wire Share Extension.appex/Datadog_DatadogCore.bundle"
    rm -rf "$BUILT_PRODUCTS_DIR/Wire Share Extension.appex/Datadog_DatadogCrashReporting.bundle"
    rm -rf "$BUILT_PRODUCTS_DIR/Wire Share Extension.appex/Datadog_DatadogRUM.bundle"
fi
