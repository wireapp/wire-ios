# Setup
## Simulator Automation Setup
        
1. Install Xcode from the Appstore. 
    - Install the additional requirements. You will be prompted when opening Xcode for the first time.
2. In Xcode, navigate to `Settings -> Locations` and set the value of **Command Line Tools** to your current Xcode version.
3. In Xcode, navigate to `Settings -> Platforms` and install **iOS** and matching simulator via **+** button
3. Install Carthage.
       
       brew install carthage
4. Install NPM with `brew install node`
5. Check [GridDeployment.groovy](GridDeployment.groovy) for currently used versions (APPIUMVERSION, XCUITESTVERSION)
6. Install **Appium** with the version above: `npm install appium@<version>` (Please don't  use `-g` option)
7. Install **Appium driver**: `npx appium driver install xcuitest` (Please don't  use `-g` option)
8. Install [applesimutils](https://github.com/wix/AppleSimulatorUtils/releases) required for setting permissions in simulator
9. If applesimutils cannot be executed run: `xattr -d com.apple.quarantine applesimutils`
```
brew tap wix/brew
brew install applesimutils
```
9. Run appium with: `PATH=$PATH:<pathtoapplesimutilsbin> npx appium`

# Test execution

## Simulator Run
* Create new Run configuration `Run -> Edit Configurations -> Add new -> Maven`
* Give the configuration the desired name (e.g. `iOS`)
* Navigate to the Parameters tab (should be open by default)
* Set Working directory to the zautomation root, for example `/Users/USERNAME/code/zautomation/tests/`
* Set Command line to `--also-make --projects ios clean install`
    * if you want to execute the iPad testcases with this configuration, this should be `--also-make --projects ios-tablet clean install`
* Click on Modify next to Java Options
 ![img.png](img.png)
* Select **Properties** and **Environment Variables**
* Add the following properties:
    * `picklejar.tags` @torun or id of desired testcase to run
    * `appPath` Path to the wire.ipa for the simulator
    * `backendType` To set the default backend
    * `deviceName` Use `xcrun simctl list` to find a simulator that Appium will match and reuse. If deviceName is not given then a simulator is newly created and destroyed for every run.
    * `Url` Set http://127.0.0.1:4723 for local execution
* Set environment variables for [Credentials](../../README.md#credentials) and [Federation](../../README.md#federation)
* Run appium with: `PATH=$PATH:<pathtoapplesimutilsbin> npx appium`
* Start the created Run Configuration in Intellij

## Real Device Automation Setup

1. Launch Xcode, go to Xcode menu option: `Preferences -> Accounts`. Add an account using Apple ID. Use `qa1@wire.com` apple ID. Login credentials for this can be found in the QA.kdbx file in our Git directory.
   After loggin in, click on "Manage Certificates..." and download all.
2. Navigate to the Applications folder. Right click on Appium and select "Open Package Contents"

   From there, open the folder `Contents/Resources/app/node_modules/appium/node_modules/appium-webdriveragent`

3. Open this folder in a terminal window and execute: `bash Scripts/bootstrap.sh -d`

4. Open the `WebDriverAgent.xcodeproj` Xcode project file in this folder

5.  - Click on the top-level project in the left side-bar, called `WebDriverAgent`.
- Click on *WebDriverAgentLib* in the **TARGETS section**
- Click on **Signing & Capabilities** in the top bar, make sure Automatically manage signing is checked and set Team value to `Zeta Project, Inc. (Ent)` and change `Bundle Identifier` to `com.wire.WebDriverAgentLib`
- Click on *WebDriverAgentRunner* in the **TARGETS** section
- Click on **Build Settings** in the top bar and change the value of `Product Bundle Identifier` to `com.wire.WebDriverAgentRunner`
- Click on **Signing & Capabilities** in the top bar, make sure Automatically manage signing is checked and change the team value to `Zeta Project, Inc. (Ent)`
- Click on *IntegrationApp* in the **TARGETS section**
- Click on **Signing & Capabilities** in the top bar, make sure Automatically manage signing is checked and set Team value to `Zeta Project, Inc. (Ent)` and change `Bundle Identifier` to `com.wire.WebDriverAgentLib`

  Note: If you are running in to signing issues, try out the Troubleshooting section in this document. If this does not fix it, you could try clearing the keychain of old signing certificates, or installing Appium again.

6. Try to build WebDriverAgentRunner with your real device as a target. It will ask for keychain access a few times during the first run. If this passes, the setup inside Xcode is finished.

## Real device Run
* Go to `Run -> Edit Configurations`
* Duplicate the iOS Simulator run configuration and give the configuration the desired name (e.g. `iOS Real`)
* Go to **Runner**
* Change the following properties:
    * `picklejar.tags` 
            
          @torun or id of desired testcase to run
    * `appPath` 
    
            Path to the wire.ipa for the real device
    * `platformVersion` 
    
            The installed version of iOS on the device you want to test on
    * `deviceName`
            
            Name of the real device you want to execute the testcase on (Example: iPhone X) 
    * `isSimulator`
            
            Should be set to false
        
    * `UDID`
            
            UDID of the connected device         
* Start Appium: `npx appium`
* Start the created Run Configuration in Intellij

## Debug runs
* Go to `Run -> Edit Configurations`
* Duplicate the run configuration with which you want to debug and give the configuration the desired name (e.g. `iOS debug`)
* Navigate to the Parameters tab (should be open by default)
* Set Working directory to the ios project root, for example ` /Users/USERNAME/IdeaProjects/zautomation/tests/ios`
* Set Command line to `clean -Dmaven.surefire.debug test` 
* Set Profiles to `iOS`
* Add a new Run Configuration by clicking on the `+` in the left upper toolbar and select `Remote`
    * The default values are valid here
* Add a breakpoint to the desired line of code that you want to debug
* Start Appium Desktop
* Enter `localhost` for the Host field
* Click on Start Server
* Start the created Debug Run Configuration in Intellij
* Start the Remote run configuration

# Finding locators
There are two possibilities for finding locators with [Appium-Inspector](https://github.com/appium/appium-inspector/releases):
-   By running a testcase with a break point, and attaching the appium server to this session
-   by starting an appium session directly through appium inspector

The benefit of using a break point is that it can take care of setting up the test, so that you don't need to manually create the circumstances in which the locator will show. It can however, be a bit tricky to connect to the session sometimes.

### By running a test

* Run a testcase which has a breakpoint in debug mode
        
        Alternative possibillity: you can add a step `And I wait for 200 seconds` 
        to make the test execution pause for X seconds, which can be quicker than 
        starting a debug run. Just make sure to remove this before commiting. 
* Open the active Appium Desktop server
* Press **Command + n**
* Click **Attach to session...** 
* Click the refresh button on the drop-down bar below until the Session ID shows up
* Click Attach to Session

### Without running a test

* Open Appium desktop and start a server
* Press **Command + n** or press the magnifier icon
* Underneath "Desired Capabilities", add the following values:
```
{
  "platformName": "iOS",
  "platformVersion": "14.1", // The platform version of your simulator (usually resambles the xcode version)
  "app": "/Users/<Username>/Downloads/Wire.ipa", // Path to the wire.ipa for the simulator
  "deviceName": "iPhone 11", // The device name of your simulator/device
  "processArguments": { // These arguments are needed to run the app as the automation would do it (for e.g. using staging backend)
    "args": [
      "-use-app-center",
      "0",
      "--disable-interactive-keyboard-dismissal",
      "--disable-call-quality-survey",
      "-BackendEnvironmentTypeOverrideKey",
      "staging",
      "--persist-backend-type",
      "--disable-autocorrection",
      "--debug-log=Network,SessionManager,event-processing,SyncStatus,OperationStatus,Push,cryptobox,background-activity,ephemeral,Authentication",
      "-com.apple.CoreData.ConcurrencyDebug",
      "1",
      "--disable-push-alert",
      "-UseAnalytics",
      "0"
    ],
    "env": {
      "ZMLOG_TAGS": "AVS,calling"
    }
  }
}
```  
* Click on "Save as..." and save the values so that you do not have to re-enter this the next time
* Click on "Start Session"

# Special testcases

## Fast Login

If a test uses fast login the entering of credentials will be skipped by providing
the app with command line parameters `--loginemail=` and `--loginpassword=`

### Deprecated method

Fast login can be activated for a test by adding the @fastlogin tag.

But it only works when test sets the "is me" value on one of the following steps:
* User X is me
* There (?:is|are) (\d+) users? where (.*) is me
* There (?:are|is) (\d+) users? with email address only where (.*) is me
* I prepare Wire to perform fast log in by email as (.*)

**Warning:** Fast login also skips the First Time Overlay, so it is not needed to use
this step in the test after the login.

### New method

Instead of using the @fastlogin tag use the step `I sign in user <Member> with fast login`
and remove implicit and explicit setting of "is me" and `Myself`.

The step will automatically tap on login button on the welcome page.

You can only use the step if the driver was not created before.

## Upgrade
### Locally
To test upgrade testcases locally, you need to set the old build you want to upgrade from. You can do this by adding the property `oldAppPath` in the run configuration in IntelliJ. The value of this should lead to the .ipa that you want to upgrade from.

### Automation Grid
In case you want to perform upgrade tests on our automation grid, you can specify the build number of which version you want to upgrade from in the `oldBuildNumber` parameter. If this is left empty, the job will grab the fourth oldest build. In case of a RC build, it will take the previously released build by default. 

When the `AppBuildNumber` parameter is provided in the Jenkins Job, the `OldBuildNumber` needs to be provided too in case you want to test an upgrade. Otherwise, it will perform a re-install of the same version. 

# Troubleshooting

#### General
* If you are unable to sign WebDriverAgentRunner with the real device selected as a target (missing certificate iPhone Developer -name-), make sure you are added to the wildcard for our testing devices in the iOS Development team.
* If there is a project file missing in your WebDriverAgent Xcode project, you should navigate to the WebDriverAgent project location in terminal and execute the following command: `bash Scripts/bootstrap.sh -d`
This will fetch the needed dependencies using Carthage. If it only shows "Fetching dependencies" before finsihing, re-install carthage using the commands below and execute the bootstrap command again.
                
                rm -rf Carthage
                brew uninstall carthage
                brew install carthage

#### sudo: a terminal is required to read the password
* The NOPASSWD privilege for the user `jenkins` is needed on the machine. See
[Confluence](https://wearezeta.atlassian.net/wiki/spaces/QA/pages/383058074/Node+Configuration) on how to set this up.

#### Fail to lock /Users/jenkins/workspace/ios_tablet_pipeline_staging/Wire.ipa
* The job was probably canceled while it was downloading the ipa from S3. The easiest way is to login to the machine and
delete the whole workspace with `rm -rf /Users/jenkins/workspace/ios_tablet_pipeline_staging/` and then disconnect and
reconnect the node in Jenkins node settings.

#### Error running 'install': An error was encountered processing the command... Failed to load Info.plist from bundle
* The error message should contain the udid of the simulator. Use this udid to find the machine on which the affected
simulator is running. Connect to the machine and make a full reset of the simulator.

#### Real device: No signing certificate "iOS Development" found: No "iOS Development" signing certificate matching team ID "..." with a private key was found.
* Check the capability called `appium:xcodeOrgId`. It should contain the team id that you can find when logging in with
qa1@wire.com on [developer.apple.com](https://developer.apple.com/) under Membership | Team ID.

#### Real device: WebDriverAgent xcodebuild exited with code '65'
* WebDriverAgent probably could not be signed. Check if the capability `appium:xcodeOrgId` is used. In the nodeconfig
log you can find the full command for xcodebuild. When you run it on the machine you will get a log with better error
messages.

#### Real device: WebDriverAgent xcodebuild exited with code '1'
* WebDriverAgent probably could not be build through missing dependencies or something else. In the nodeconfig log you
can find the path to appium-webdriveragent node module. Go into this directory and run `./Scripts/bootstrap.sh` In the
nodeconfig log you can also find the full command for xcodebuild. When you run it on the machine you will get a log with
better error messages.

#### Real device: Xcode Project does not compile due to missing files
* Try to re-install carthage and execute the `bash Scripts/boostrap.sh -d` command again from step 4 of the real device automation setup guide. 


#### All tests freeze on simulator on the screen with the Wire shield logo with black background**
* Solution: Restart simulator

#### Simulator architecture is unsupported by the '.../Wire.app' application
* You probably have tried to run the real device builds on a simulator. Check if `is_simulator = true` for the choosen grid.

#### MacOS Big Sur: JavaSeekerTest.testGetLoadedClasses:39 NoSuchField classes
* It is possible that the update to MacOS Big Sur has resulted into the JAVA_HOME variable being set incorrectly. Try to run `- export JAVA_HOME=$(/usr/libexec/java_home)` in Terminal and see if that fixes the issue. 
