/*

TAGS as String parameter
Grid as Choice parameter
Track as Choice parameter: dev, release, avs, qa-playground
AppBuildNumber as String parameter
CALLING_SERVICE_ENV as Choice parameter with choices: master, dev
TESTINY_RUN_NAME as String parameter
Branch as String parameter main
surefire.rerunFailingTestsCount as String parameter 1
test as String parameter
 */

@NonCPS
def sortByModified(list) {
    list.sort {
        it.getLastModified()
    }
}

def setIPAFromS3(def track, def appBuildNumber, def is_simulator) {
    if (track == "Development") {
        // Track "Development": AppBuildNumber can be set to build number or "latest"
        if (is_simulator) {
            S3_FOLDER = "ios/development/simulator/"
        } else {
            S3_FOLDER = "ios/development/device/debug/"
        }
        GLOB = 'Wire-development-develop-*/*.ipa'
        // Get list of files on S3
        def files = []
        withAWS(region: 'eu-west-1', credentials: "S3_CREDENTIALS") {
            files = s3FindFiles bucket: "z-lohika", path: S3_FOLDER, onlyFiles: true, glob: GLOB
        }
        print("Found:")
        files.each {
            print(it.path)
        }
        if (appBuildNumber == "latest") {
            print("Get latest develop build...")
            files = sortByModified(files)
            env.S3AppPath = S3_FOLDER + files[-1].path
        } else {
            print("Find develop build with matching build number...")
            files.each {
                if (it.name.contains("${appBuildNumber}")) {
                    env.S3AppPath = S3_FOLDER + it.path
                }
            }
            if (env.S3AppPath == null) {
                error("Could not find develop build in ${S3_FOLDER} with name containing ${appBuildNumber}")
            }
        }
    } else if (track == "S3") {
        if ("${appBuildNumber}".endsWith(".ipa") == 0) {
            error("AppBuildNumber does needs to end with .ipa: ${appBuildNumber}")
        }
        if (appBuildNumber.startsWith("ios/") == 0) {
            error("AppBuildNumber should look like this: ios/development/simulator/Wire-development-develop-simulator-10310/Wire-development-develop-simulator-10310.ipa")
        }
        env.S3AppPath = appBuildNumber
    } else if (track == "Release") {
        print("Trying to get latest release...")
        S3_FOLDER = "ios/release/testflight/"
        GLOB = 'Wire-beta-release*-simulator-*/*.ipa'
        withAWS(region: 'eu-west-1', credentials: "S3_CREDENTIALS") {
            files = s3FindFiles bucket: "z-lohika", path: S3_FOLDER, onlyFiles: true, glob: GLOB
        }
        print("Search complete")
        print("Found:")
        files.each {
            print(it.path)
        }

        if (appBuildNumber == "latest") {
            print("Get latest release build...")
            files = sortByModified(files)
            env.S3AppPath = S3_FOLDER + files[-1].path
        } else {
            print("Find develop build with matching build number...")
            files.each {
                if (it.name.contains("${appBuildNumber}")) {
                    env.S3AppPath = S3_FOLDER + it.path
                }
            }
            if (env.S3AppPath == null) {
                error("Could not find develop build in ${S3_FOLDER} with name containing ${appBuildNumber}")
            }
        }
    } else {
        error("Track ${track} is not known. Please use either 'Development', or 'S3'")
    }

    echo("S3AppPath: " + env.S3AppPath)

    env.REAL_BUILD_NUMBER = (env.S3AppPath =~ /([0-9]+).ipa/) [0] [1]
    echo("REAL_BUILD_NUMBER: " + env.REAL_BUILD_NUMBER)
    return env.S3AppPath
}

return this