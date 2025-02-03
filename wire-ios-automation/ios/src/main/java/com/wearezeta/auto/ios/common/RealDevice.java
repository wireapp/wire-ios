package com.wearezeta.auto.ios.common;

import com.wearezeta.auto.common.CommonUtils;
import com.wearezeta.auto.common.Config;

import java.util.*;

public class RealDevice {
    private static Optional<String> udid = Optional.empty();

    private static RealDevice instance = null;

    public static synchronized RealDevice getInstance() {
        if (instance == null) {
            instance = new RealDevice();
        }
        return instance;
    }

    public static String getUDID() {
        if(!udid.isPresent()) {
            udid = Config.current().getUDID(RealDevice.class);
        }

        if (!udid.isPresent()) {
            for (String deviceName : new String[]{"iPhone", "iPad"}) {
                final String result;
                try {
                    result = CommonUtils.executeOsXCommandWithOutput(new String[]{
                            "/bin/bash",
                            "-c",
                            "system_profiler SPUSBDataType | sed -n '/"
                                    + deviceName
                                    + "/,/Serial/p' | grep 'Serial Number:' | awk -F ': ' '{print $2}'"}).trim();
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
                if (result.length() > 0) {
                    udid = Optional.of(result);
                    break;
                }
            }
        }
        return udid.orElseThrow(
                () -> new IllegalStateException("No connected iOS devices can be detected")
        );
    }

}
