def gridNodes = []

// Default values for appium + node (Override in the next conditional block if needed)
env.NODEVERSION = "node-v18"
env.APPIUMVERSION = "2.5.2"

if ("${GRID}" == "iOS-realdevice") {
    env.HUB = "iOS_node070"
    env.HUBHOST = "192.168.2.70"
    env.HUBPORT = 4444
    env.WDALOCALPORT = 8101
    env.APPIUMPORT = 4730
    // node cannot be updated higher than xcode 14.0.1 which only comes with iOS 16.0
    gridNodes.add([label: "iOS_node070", GRIDDEVICETYPE: "phone", DEVICE_PER_NODE: 1, IS_SIMULATOR: false, DEVICENAME: "iPhone 11", PLATFORMVERSION: "16.2"])
} else if ("${GRID}" == "iOS-phones-arm64") {
    env.HUB = "iOS_node200"
    env.HUBHOST = "192.168.2.200"
    env.HUBPORT = 4444
    env.WDALOCALPORT = 8101
    env.APPIUMPORT = 4730
    gridNodes.add([label: "iOS_node200", GRIDDEVICETYPE: "phone", DEVICE_PER_NODE: 5, IS_SIMULATOR: true, DEVICENAME: "iPhone 11", PLATFORMVERSION: "17.5", RUNTIME: "com.apple.CoreSimulator.SimRuntime.iOS-17-5"])
} else if ("${GRID}" == "iOS-tablets-arm64") {
    env.HUB = "iOS_node201"
    env.HUBHOST = "192.168.2.201"
    env.HUBPORT = 4444
    env.WDALOCALPORT = 8101
    env.APPIUMPORT = 4730
    gridNodes.add([label: "iOS_node201", GRIDDEVICETYPE: "tablet", DEVICE_PER_NODE: 3, IS_SIMULATOR: true, DEVICENAME: "iPad Air (5th generation)", PLATFORMVERSION: "16.4", RUNTIME: "com.apple.CoreSimulator.SimRuntime.iOS-16-4"])
} else if ("${GRID}" == "iOS-phones-arm64-fast") {
    env.HUB = "iOS_node203"
    env.HUBHOST = "192.168.2.203"
    env.HUBPORT = 4444
    env.WDALOCALPORT = 8101
    env.APPIUMPORT = 4730
    gridNodes.add([label: "iOS_node203", GRIDDEVICETYPE: "phone", DEVICE_PER_NODE: 15, IS_SIMULATOR: true, DEVICENAME: "iPhone 15", PLATFORMVERSION: "17.5", RUNTIME: "com.apple.CoreSimulator.SimRuntime.iOS-17-5"])
} else {
    error("Could not find configuration for ${GRID}")
}

node(env.HUB) {

    env.NODEPORT = 5555
    env.DEVICEIDS
    env.LAUNCH_PATH = "/Library/LaunchDaemons"

    // Print xcode version on node
    xcodeVersion = sh returnStdout: true, script: 'xcodebuild -version'
    echo(xcodeVersion)

    stage('Hub: Stop and cleanup') {

        echo("Unload former grid hub")
        try {
            String output = sh label: 'Get plist files of grid hub', returnStdout: true, script: "ls -1 /Library/LaunchDaemons/com.wire.ios.phone.grid.plist 2>/dev/null"
            print(output)
            for (String nodePlist : output.split("\n")) {
                sh label: 'Unload plist', returnStdout: true, script: "sudo launchctl unload -w $nodePlist"
            }
        } catch (e) {
            print("Unload plist of node failed or no former plists found!");
        }

        echo("Delete old plist files and logs")
        try {
            sh label: 'Delete old plist files', returnStdout: true, script: "sudo rm -f /Library/LaunchDaemons/com.wire.ios.phone.grid.plist"
            sh label: 'Delete old grid logs', returnStdout: true, script: "sudo rm -rf /Users/jenkins/selenium/ios-phone-hub.* || true"
        } catch (e) {
            print("Delete old plist files or logs failed!");
        }

    }

    gridNodes.each { entry ->
        env.GRIDDEVICETYPE = entry["GRIDDEVICETYPE"]
        node(entry["label"]) {
            stage(entry["label"] + ": Stop nodes and cleanup") {
                echo("Unload former grid nodes (selenium relay)")
                try {
                    String output = sh label: 'Get plist files of grid nodes', returnStdout: true, script: "ls -1 /Library/LaunchDaemons/com.wire.ios.node.* 2>/dev/null"
                    print(output)
                    for (String nodePlist : output.split("\n")) {
                        sh label: 'Unload plist of node', returnStdout: true, script: "sudo launchctl unload -w $nodePlist"
                    }
                } catch (e) {
                    print("Unload plist of node failed or no former plists found!");
                }

                echo("Unload former grid nodes (appium)")
                try {
                    String output = sh label: 'Get plist files of grid nodes', returnStdout: true, script: "ls -1 /Library/LaunchDaemons/com.wire.ios.appium.* 2>/dev/null"
                    print(output)
                    for (String nodePlist : output.split("\n")) {
                        sh label: 'Unload plist of node', returnStdout: true, script: "sudo launchctl unload -w $nodePlist"
                    }
                } catch (e) {
                    print("Unload plist of node failed or no former plists found!");
                }

                echo("Delete old plist files and logs (selenium relay & appium)")
                try {
                    sh label: 'Delete nodeconfig files and logs', returnStdout: true, script: "sudo rm -rf /Users/jenkins/selenium/*.log || true"
                    sh label: 'Delete serverconfig files and logs', returnStdout: true, script: "sudo rm -rf /Users/jenkins/selenium/*.err || true"
                    sh label: 'Delete plist files', returnStdout: true, script: "sudo rm -rf /Library/LaunchDaemons/com.wire.ios.appium.* || true"
                    sh label: 'Delete plist files', returnStdout: true, script: "sudo rm -rf /Library/LaunchDaemons/com.wire.ios.node.* || true"
                } catch (e) {
                    error("Delete old plist files or logs failed!");
                }
            }
        }
    }

    stage('Hub: Prepare needed software') {
        // download selenium-standalone-server if needed
        try {
            sh script: """
            mkdir -p /Users/jenkins/selenium/
            if [ ! -e /Users/jenkins/selenium/selenium-server-4.7.0.jar ] ; then
                curl -L https://github.com/SeleniumHQ/selenium/releases/download/selenium-4.7.0/selenium-server-4.7.0.jar -o /Users/jenkins/selenium/selenium-server-4.7.0.jar
            fi
        """
        } catch (e) {
            error("Downloading selenium standalone server failed!");
        }
        // download applesimutils if needed
        try {
            sh script: """
            mkdir -p /Users/jenkins/selenium/
            if [ ! -e /Users/jenkins/selenium/applesimutils/0.9.9/bin/applesimutils ] ; then
                rm -rf /Users/jenkins/selenium/applesimutils.tar.gz
                ARCH=""
                # Set architecture prefix if on M1 machine
                if uname -m | grep arm64; then
                  ARCH="arm64_"
                fi
                curl -L https://github.com/wix/AppleSimulatorUtils/releases/download/0.9.9/applesimutils-0.9.9.\${ARCH}big_sur.bottle.tar.gz -o /Users/jenkins/selenium/applesimutils.tar.gz
                cd /Users/jenkins/selenium/
                tar -zvxf applesimutils.tar.gz
                sudo xattr -rd com.apple.quarantine /Users/jenkins/selenium/applesimutils/0.9.9/bin/applesimutils
            fi
        """
        } catch (e) {
            error("Downloading applesimutils failed! " + e);
        }
    }

    stage('Create grid config file and start') {
        // create plist file for grid
        sh '''
        GRIDPLIST=com.wire.ios.${GRIDDEVICETYPE}.grid
        cat <<EOF > $GRIDPLIST.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$GRIDPLIST</string>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
        <dict>
	       <key>NetworkState</key>
	       <true/>
        </dict>
        <key>ThrottleInterval</key>
        <integer>30</integer>
        <key>WorkingDirectory</key>
        <string>/Users/jenkins/selenium/</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/bin/java</string>
		<string>-jar</string>
		<string>selenium-server-4.7.0.jar</string>
		<string>hub</string>
		<string>--host</string>
		<string>0.0.0.0</string>
		<string>--port</string>
		<string>$HUBPORT</string>
        <string>--session-request-timeout</string>
        <string>240</string>
	</array>
	<key>StandardErrorPath</key>
	<string>/Users/jenkins/selenium/ios-$GRIDDEVICETYPE-hub.err</string>
	<key>StandardOutPath</key>
	<string>/dev/null</string>
</dict>
</plist>
EOF
        sudo mv $GRIDPLIST.plist $LAUNCH_PATH/
        sudo chown root:wheel $LAUNCH_PATH/$GRIDPLIST.plist
        '''

        // load grid hub
        try {
            sh label: 'Load plist of grid', returnStdout: true, script: "sudo launchctl load -w /Library/LaunchDaemons/com.wire.ios.${GRIDDEVICETYPE}.grid.plist"
        } catch (e) {
            error("Load plist of grid failed!");
        }
    }

    gridNodes.each { entry ->
        env.LABEL = entry["label"]
        env.GRIDDEVICETYPE = entry["GRIDDEVICETYPE"]
        env.DEVICE_PER_NODE = entry["DEVICE_PER_NODE"]
        env.PLATFORMVERSION = entry["PLATFORMVERSION"]
        env.RUNTIME = entry["RUNTIME"]
        env.DEVICENAME = entry["DEVICENAME"]
        node(entry["label"]) {
            stage(entry["label"] + ": Create config files and start nodes") {

                // download selenium-standalone-server if needed
                try {
                    sh script: """
                        mkdir -p /Users/jenkins/selenium/
                        if [ ! -e /Users/jenkins/selenium/selenium-server-4.7.0.jar ] ; then
                            curl -L https://github.com/SeleniumHQ/selenium/releases/download/selenium-4.7.0/selenium-server-4.7.0.jar -o /Users/jenkins/selenium/selenium-server-4.7.0.jar
                        fi
                    """
                } catch (e) {
                    error("Downloading selenium standalone server failed!");
                }

                // Install Carthage
                sh([script: """
                    if [ "`/usr/local/bin/carthage version`" != '0.38.0' ]; then
                        curl -L https://github.com/Carthage/Carthage/releases/download/0.38.0/Carthage.pkg -o Carthage.pkg
                        sudo installer -pkg Carthage.pkg -target /
                    fi
                """])

                nodejs(env.NODEVERSION) {
                    sh '[ "$(appium -v)" == ${APPIUMVERSION} ] || npm install -g appium@${APPIUMVERSION}'

                    // Need to run this once to make appium find the driver
                    sh returnStatus: true, script: '${NODEJS_HOME}/bin/appium driver install xcuitest'
                    // Unfortunately it is impossible to pin the version of the driver, we just get latest through update:
                    sh returnStatus: true, script: '${NODEJS_HOME}/bin/appium driver update xcuitest --unsafe'

                    env.PATH = "${env.NODEJS_HOME}/bin:/usr/local/bin:/usr/bin:/Users/jenkins/selenium/applesimutils/0.9.9/bin/:${env.PATH}"
                    echo "PATH = " + env.PATH
                    def udids = []

                    if (entry["IS_SIMULATOR"]) {
                        // Delete all devices with missing runtime etc.
                        sh "xcrun simctl delete unavailable"
                        sh "sudo xcrun simctl delete unavailable"
                        // Get udid of available device with certain device name
                        def output = sh label: 'Get iOS phone/tablet UDIDs', returnStdout: true, script: 'xcrun simctl list -j devices available'
                        def json = readJSON text: output
                        def sims = json["devices"][env.RUNTIME]
                        for (sim in sims) {
                            if (sim["name"] == env.DEVICENAME) {
                                def udid = sim["udid"]
                                udids.add(udid)
                                echo("Simulators with udid " + udid)
                                // If device is not booted then boot it up
                                if (sim["state"] != "Booted") {
                                    sh "xcrun simctl boot ${udid}"
                                }
                            }
                        }
                        echo(udids.size() + " simulators found on jenkins node " + entry["label"])
                        // TODO: Create simulators if no available ones with the platformVersion and name are existing
                        while (udids.size() < (env.DEVICE_PER_NODE as Integer)) {
                            def newUDID = sh returnStdout: true, script: 'xcrun simctl create "${DEVICENAME}" "${DEVICENAME}" "${RUNTIME}"'
                            udids.add(newUDID)
                        }
                    } else {
                        def output = sh label: 'Get real device iOS phone/tablet UDIDs', returnStdout: true, script: 'system_profiler SPUSBDataType -json'
                        def json = readJSON text: output
                        def devices = []
                        def dataType = json.SPUSBDataType._items*._items.flatten()
                        dataType.each {
                            if (it != null) {
                                def name = it["_name"]
                                if (name == "iPhone") {
                                    devices.add(it)
                                }
                            }
                        }
                        for (device in devices) {
                            if (device["serial_num"] != null) {
                                def serial_num = device["serial_num"]
                                def udid = serial_num.substring(0, 8) + "-" + serial_num.substring(8, serial_num.length())
                                udids.add(udid)
                                echo("Real device with udid " + udid)
                            }
                        }
                        echo(udids.size() + " real devices found on jenkins node " + entry["label"])
                    }
                    env.DEVICEIDS = udids.join(" ")

                    print(DEVICEIDS)

                    sh 'mkdir -p /Users/jenkins/selenium/'

                    // create new grid node config files
                    sh '''
    DEVICECOUNT=0
    for UDID in $DEVICEIDS ; do
        ((DEVICECOUNT++))
        ((WDALOCALPORT++))
        ((APPIUMPORT++))
        ((NODEPORT++))

        IPADDRESS=`ifconfig en0 inet | tail -1 | cut -d ' ' -f 2`
        SERVERCONFIG=/Users/jenkins/selenium/serverconfig-localhost-$GRIDDEVICETYPE${DEVICECOUNT}
        NODECONFIG=/Users/jenkins/selenium/nodeconfig-ios-$GRIDDEVICETYPE${DEVICECOUNT}
        mkdir -p /Users/jenkins/selenium/WDA/$UDID

        cat <<EOF > $NODECONFIG.toml
[server]
port = $NODEPORT

[node]
detect-drivers = false

[relay]
url = "http://localhost:$APPIUMPORT"
status-endpoint = "/status"
configs = [
  "1", "{\\"platformName\\": \\"ios\\", \\"adbExecTimeout\\": 40000,\\"version\\": \\"$PLATFORMVERSION\\", \\"wdaLocalPort\\": $WDALOCALPORT}"
]

EOF

SERVERPLIST=com.wire.ios.appium.${GRIDDEVICETYPE}${DEVICECOUNT}.plist
     echo "SERVERPLIST = $SERVERPLIST"

     cat <<EOF > $SERVERPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>EnvironmentVariables</key>
        <dict>
	        <key>PATH</key>
	        <string>$PATH</string>
	        <key>HOME</key>
	        <string>/Users/jenkins/</string>
        </dict>
        <key>UserName</key>
        <string>jenkins</string>
        <key>Label</key>
        <string>com.wire.ios.node.${GRIDDEVICETYPE}${DEVICECOUNT}</string>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>ProgramArguments</key>
        <array>
                <string>${NODEJS_HOME}/bin/appium</string>
                <string>--relaxed-security</string>
                <string>-p</string>
                <string>$APPIUMPORT</string>
                <string>--log-timestamp</string>
                <string>--log-no-colors</string>
                <string>--default-capabilities</string>
                <string>{"appium:udid":"$UDID","appium:wdaLocalPort":$WDALOCALPORT,"appium:derivedDataPath":"/Users/jenkins/selenium/WDA/$UDID"}</string>
        </array>
        <key>StandardErrorPath</key>
        <string>$SERVERCONFIG.err</string>
        <key>StandardOutPath</key>
        <string>$SERVERCONFIG.log</string>
</dict>
</plist>

EOF

    sudo mv $SERVERPLIST $LAUNCH_PATH/
    sudo chown root:wheel $LAUNCH_PATH/$SERVERPLIST
    
    NODEPLIST=com.wire.ios.node.${GRIDDEVICETYPE}${DEVICECOUNT}.plist
    echo "NODEPLIST = $NODEPLIST"
    
     cat <<EOF > $NODEPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$NODEPLIST</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>30</integer>
    <key>WorkingDirectory</key>
    <string>/Users/jenkins/selenium/</string>
    <key>UserName</key>
    <string>jenkins</string>
    <key>ProgramArguments</key>
    <array>
       <string>/usr/bin/java</string>
       <string>-jar</string>
       <string>selenium-server-4.7.0.jar</string>
       <string>node</string>
       <string>--config</string>
       <string>$NODECONFIG.toml</string>
       <string>--hub</string>
       <string>http://$HUBHOST:$HUBPORT</string>
    </array>
    <key>StandardErrorPath</key>
    <string>$NODECONFIG.err</string>
    <key>StandardOutPath</key>
    <string>$NODECONFIG.log</string>
</dict>
</plist>

EOF

    sudo mv $NODEPLIST $LAUNCH_PATH/
    sudo chown root:wheel $LAUNCH_PATH/$NODEPLIST
    done
    '''
                }
            }

            stage('Start new grid and nodes') {

                // load appium server nodes
                try {
                    String output = sh label: 'Get new plist files of appium servers', returnStdout: true, script: 'ls -1 /Library/LaunchDaemons/* | grep "com.wire.ios.appium.${GRIDDEVICETYPE}*"'
                    print(output)
                    for (String serverPlist : output.split("\n")) {
                        sh label: 'Load plist of node', returnStdout: true, script: "sudo launchctl load -w $serverPlist"
                    }
                } catch (e) {
                    error("Load new plist of node failed!");
                }

                sleep 5

                // load grid nodes
                try {
                    String output = sh label: 'Get new plist files of nodes', returnStdout: true, script: 'ls -1 /Library/LaunchDaemons/* | grep "com.wire.ios.node.${GRIDDEVICETYPE}*"'
                    print(output)
                    for (String nodePlist : output.split("\n")) {
                        sh label: 'Load plist of node', returnStdout: true, script: "sudo launchctl load -w $nodePlist"
                    }
                } catch (e) {
                    error("Load new plist of node failed!");
                }
            }
        }
    }
}

