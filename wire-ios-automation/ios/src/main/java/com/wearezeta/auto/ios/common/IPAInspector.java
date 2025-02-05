package com.wearezeta.auto.ios.common;

import com.dd.plist.NSDictionary;
import com.dd.plist.PropertyListParser;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

public class IPAInspector {

    private byte[] plist;
    private String bundleId;

    public IPAInspector(String path) {
        final File fPath = new File(path);
        if (path.toLowerCase().endsWith(".app")) {
            // no need to extract. Just load Info.plist as byte[]
            final File plistFile = new File(fPath.getAbsolutePath(), "Info.plist");
            try {
                plist = Files.readAllBytes(plistFile.toPath());
            } catch (IOException e) {
                throw new RuntimeException("Could not read " + fPath.getAbsolutePath(), e);
            }
        } else if (path.toLowerCase().endsWith(".ipa")) {
            // extract Info.plist from .ipa
            try {
                ZipFile zipFile = new ZipFile(fPath);
                ZipEntry zipEntry = zipFile.getEntry("Payload/Wire.app/Info.plist");
                InputStream is = zipFile.getInputStream(zipEntry);
                plist = new byte[is.available()];
                is.read(plist);
                is.close();
            } catch (Exception e) {
                throw new RuntimeException("Could not extract Info.plist from " + fPath.getAbsolutePath(), e);
            }
        } else {
            throw new IllegalArgumentException(
                    String.format("Only .ipa and .app packages are supported. %s is given instead", path));
        }
    }

    public String getBundleId() {
        if (bundleId == null) {
            bundleId = parseProperty(plist, "CFBundleIdentifier");
        }
        return this.bundleId;
    }

    private static String parseProperty(byte[] plist, String propertyName) {
        final NSDictionary rootDict;
        try {
            rootDict = (NSDictionary) PropertyListParser.parse(plist);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
        return rootDict.objectForKey(propertyName).toString();
    }
}
