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
import hudson.tasks.test.AbstractTestResultAction

@NonCPS
def testStatuses() {
    AbstractTestResultAction testResultAction = currentBuild.rawBuild.getAction(AbstractTestResultAction.class)
    if (testResultAction != null) {
        def total = testResultAction.totalCount
        def failed = testResultAction.failCount
        def skipped = testResultAction.skipCount
        def passed = total - failed - skipped
        int percent = (total > 0) ? (passed * 100) / (total - skipped) : 0
        testStatus = "Tests passed: ${passed}, Failed: ${failed} ${testResultAction.failureDiffString}, Skipped: ${skipped}, Total: ${total} (${percent}%)"
    } else {
        testStatus = "Could not find test results!"
    }
    return testStatus
}

@NonCPS
def isTestSuccessful() {
    AbstractTestResultAction testResultAction = currentBuild.rawBuild.getAction(AbstractTestResultAction.class)
    if (testResultAction != null && testResultAction.failCount > 0) {
        return false
    }
    return true
}

node("Job_distributor") {

    def aborted = false
    def TAGS = "${params.TAGS}"
    def filename = ""

    // Select bot credentials for specific Wire conversation based on job name
    credentialsId = "JENKINSBOT_IOS_REGRESSION"

    // Select grid
    hubUrl = "http://192.168.2.200:4444/wd/hub"
    is_simulator = true
    deviceName = "iPhone 11"
    platformVersion = "16.4"
    tablet = false
    nodeLabels = "iOS_node200"
    MAX_PARALLEL = 5

    withCredentials([
            file(credentialsId: 'KUBECONFIG_anta', variable: 'KUBECONFIG_anta'),
            file(credentialsId: 'KUBECONFIG_bella', variable: 'KUBECONFIG_bella'),
            file(credentialsId: 'KUBECONFIG_chala', variable: 'KUBECONFIG_chala'),
            file(credentialsId: 'KUBECONFIG_foma', variable: 'KUBECONFIG_foma'),
            file(credentialsId: 'KUBECONFIG_gudja_offline_ios', variable: 'KUBECONFIG_gudja_offline_ios'),
            file(credentialsId: 'KUBECONFIG_bund_next_column_1', variable: 'KUBECONFIG_bund_next_column_1'),
            file(credentialsId: 'KUBECONFIG_bund_qa_column_1', variable: 'KUBECONFIG_bund_qa_column_1'),
            string(credentialsId: "${credentialsId}", variable: 'JENKINSBOT_SECRET'),
            string(credentialsId: 'BLACKLIST_S3_SECRET', variable: 'BLACKLIST_S3_SECRET'),
            string(credentialsId: 'OKTA_API_KEY', variable: 'OKTA_API_KEY'),
            string(credentialsId: 'KEYCLOAK_PASSWORD', variable: 'KEYCLOAK_PASSWORD'),
            string(credentialsId: 'LH_SERVICE_AUTH_TOKEN', variable: 'LH_SERVICE_AUTH_TOKEN'),
            string(credentialsId: "TESTINY_API_KEY_IOS", variable: 'TESTINY_API_KEY'),
            string(credentialsId: 'STRIPE_API_KEY', variable: 'STRIPE_API_KEY')]) {

        // Checkout
        stage('Checkout & Clean') {
            checkout([$class: 'GitSCM', branches: [[name: '*/${Branch}']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'zautomation'], [$class: 'SparseCheckoutPaths', sparseCheckoutPaths: [[path: 'tests/common'], [path: 'tests/ios'], [path: 'tests/pom.xml'], [path: 'tests/tools']]], [$class: 'CheckoutOption', timeout: 30], [$class: 'CloneOption', depth: 0, noTags: true, reference: '', shallow: true, timeout: 30], [$class: 'BuildChooserSetting', buildChooser: [$class: 'DefaultBuildChooser']]], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'zautomation', url: 'git@github.com:zinfra/zautomation.git']]])

            echo("Installing kubectl if not already installed")
            kubeCtlSetup = readFile("${WORKSPACE}/zautomation/tests/common/kubectlSetup.sh")
            sh kubeCtlSetup
            if (params.TESTINY_RUN_NAME != "") {
                if (params.test == "") {
                    echo("Tag git branch with Testiny run name")
                    def tagname = params.TESTINY_RUN_NAME.replaceAll("\\s","").replaceAll("\\(","_").replaceAll("\\)","_")
                    sshagent(credentials: ['zautomation-writeable']) {
                        sh returnStatus: true, script: "cd zautomation && git tag iOS-${tagname}"
                        sh returnStatus: true, script: "cd zautomation && git push origin iOS-${tagname}"
                    }
                }
            }
        }

        // TODO: Move this back into the test stage when a solution is found that does not override Wire.ipa in a second parallel run
        lock("${Grid}") {

            stage('Download build from S3 to grid nodes') {
                load('zautomation/tests/ios/RetrieveIPA.Jenkinsfile.groovy').setIPAFromS3(track, appBuildNumber, is_simulator)

                // Work on selenium grid nodes
                nodes = nodesByLabel(nodeLabels)
                nodes.each {
                    node(it) {
                        // Cleanup the workspace before getting the ipa ready
                        sh "rm -rf $WORKSPACE/Payload"
                        sh "rm -rf $WORKSPACE/Wire.ipa"

                        // TODO: Find a better place for saving the ipa (maybe containing the grid name)
                        env.OLD_APP_PATH = "$WORKSPACE/Previous/Payload/Wire.app"
                        env.APP_PATH = "$WORKSPACE/Payload/Wire.app"

                        // Download builds via s3 proxy
                        sh "curl http://192.168.2.39:8000/z-lohika/${S3AppPath} -o \"$WORKSPACE/Wire.ipa\""

                        // grab wire.app from the ipa
                        sh "unzip -o $WORKSPACE/Wire.ipa"

                        // Gather bundle id from ipa
                        env.BUNDLE_ID = sh returnStdout: true, script: "plutil -extract CFBundleIdentifier raw Payload/Wire.app/Info.plist -o - | tr -d '\\n'"
                        echo("BUNDLE_ID: " + env.BUNDLE_ID)

                        echo("Delete old version")
                        sh "rm -rf ${OldS3AppPath}"

                        echo("Download old version")
                        if ("${OldS3AppPath}" == "") {
                            echo("No OldS3AppPath given.")
                        } else {
                            // Download old build via s3 proxy
                            sh "curl http://192.168.2.39:8000/z-lohika/${OldS3AppPath} -o \"$WORKSPACE/Previous.ipa\""
                            sh "unzip -o $WORKSPACE/Previous.ipa -d $WORKSPACE/Previous/"
                        }

                        // See section "Files generated by test runs" on http://appium.io/docs/en/drivers/ios-xcuitest/
                        // If it fails we shutdown the simulator first and try deleting them again
                        sh returnStatus: true, script: 'rm -rf $HOME/Library/Logs/CoreSimulator/* || xcrun simctl shutdown booted && rm -Rf $HOME/Library/Logs/CoreSimulator/*'

                        // Delete cached ipa files to prevent installation error "Failed to load Info.plist from bundle at"
                        sh 'rm -rf /var/folders/* || true'

                        // Delete all files used by former history backup tests
                        sh 'find $HOME/Library/Developer/CoreSimulator/Devices/ -name *.ios_wbu -delete'
                    }
                }
            }

            // Set build description
            filename = env.S3AppPath.tokenize('/')[-1]
            currentBuild.description = filename + "\n" + TAGS

            // Keep build forever when RC is made
            if (params.TESTINY_RUN_NAME != "") {
                currentBuild.description = params.TESTINY_RUN_NAME + "\n" + currentBuild.description
                currentBuild.keepLog = true
            }

            withMaven(jdk: 'AdoptiumJDK11', maven: 'M3', mavenOpts: '-Xmx1024m -XX:MaxPermSize=128m', mavenLocalRepo: '.repository', options: [junitPublisher(disabled: true), jacocoPublisher(disabled: true)]) {

                stage('Build common') {
                    env.RC_TESTS_COMMENT_PATH = "$WORKSPACE/rc_comment.txt"
                    sh 'echo "${JOB_NAME} ${BUILD_DISPLAY_NAME} - Cucumber Report: ${JENKINS_URL}job/${JOB_NAME}/${BUILD_NUMBER}/cucumber-html-reports/" > $RC_TESTS_COMMENT_PATH'

                    sh """
mvn clean install \\
-f "$WORKSPACE/zautomation/tests/common/pom.xml" \\
-DbackendType="${backendType}" \\
-DtestinyProjectName="Wire iOS" \\
-DtestinyRunName="$TESTINY_RUN_NAME" \\
-DrcTestsCommentPath="${RC_TESTS_COMMENT_PATH}" \\
-DcallingServiceUrl='loadbalanced' \\
-Dcom.wire.calling.env='${CALLING_SERVICE_ENV}' \\
-DsyncIsAutomated=true
"""
                }

                // This is needed because of https://issues.jenkins-ci.org/browse/JENKINS-7180
                def RERUN = currentBuild.getRawBuild().actions.find { it instanceof ParametersAction }?.parameters.find {
                    it.name == 'surefire.rerunFailingTestsCount'
                }?.value

                // This is needed when we want the tests to only run on a specific device
                if (!browserName.isEmpty()) {
                    env.MAX_PARALLEL = 1
                }

                if (tablet) {
                    stage('Build ios') {
                        sh "mvn -DskipTests=true clean install -f \"$WORKSPACE/zautomation/tests/ios/pom.xml\""
                    }

                    stage('Run tests') {
                        try {
                            timeout(time: 6, unit: 'HOURS') {
                                realtimeJUnit(keepLongStdio: true, testDataPublishers: [[$class: 'JUnitFlakyTestDataPublisher']], testResults: 'zautomation/tests/ios-tablet/target/xml-reports/TEST*.xml') {
                                    sh """
mvn clean integration-test \\
-f "$WORKSPACE/zautomation/tests/ios-tablet/pom.xml" \\
-P isOnGrid \\
-DUrl='${hubUrl}' \\
-Dpicklejar.parallelism='${MAX_PARALLEL}' \\
-DisSimulator=${is_simulator} \\
-DenableAppiumOutput=false \\
-Dpicklejar.tags='$TAGS' \\
-DappPath="${APP_PATH}" \\
-DoldAppPath="${OLD_APP_PATH}" \\
-DdeviceName="${deviceName}" \\
-DplatformVersion='${platformVersion}' \\
-DrealBuildNumber='${REAL_BUILD_NUMBER}' \\
-DbundleId='${BUNDLE_ID}' \\
-Dsurefire.rerunFailingTestsCount=${RERUN} \\
-Dtest="${params.test}" \\
-DbrowserName="${browserName}"
"""
                                }
                            }
                        } catch (e) {
                            print e
                            if (e instanceof hudson.AbortException) {
                                aborted = true
                            }
                        }
                    }
                } else {

                    stage('Run tests') {
                        try {
                            timeout(time: 6, unit: 'HOURS') {
                                realtimeJUnit(keepLongStdio: true, testDataPublishers: [[$class: 'JUnitFlakyTestDataPublisher']], testResults: 'zautomation/tests/ios/target/xml-reports/TEST*.xml') {
                                    sh """
mvn clean integration-test \\
-f "$WORKSPACE/zautomation/tests/ios/pom.xml" \\
-P isOnGrid \\
-DUrl='${hubUrl}' \\
-Dpicklejar.parallelism='${MAX_PARALLEL}' \\
-DisSimulator=${is_simulator} \\
-Dpicklejar.tags='$TAGS' \\
-DappPath="${APP_PATH}" \\
-DoldAppPath="${OLD_APP_PATH}" \\
-DdeviceName="${deviceName}" \\
-DplatformVersion='${platformVersion}' \\
-DrealBuildNumber='${REAL_BUILD_NUMBER}' \\
-DbundleId='${BUNDLE_ID}' \\
-Dsurefire.rerunFailingTestsCount=${RERUN} \\
-Dtest="${params.test}" \\
-DbrowserName="${browserName}"
"""
                                }
                            }
                        } catch (e) {
                            print e
                            if (e instanceof hudson.AbortException) {
                                aborted = true
                            }
                        }
                    }
                }
            }

        } // End of lock

        stage('Generate test results') {
            try {
                // Generate Jenkins cucumber HTML reports and archive JSON
                archiveArtifacts artifacts: '**/target/*report*.json', followSymlinks: false
                if (tablet) {
                    cucumber failedFeaturesNumber: -1, failedScenariosNumber: -1, failedStepsNumber: -1, fileIncludePattern: '**/target/*report*.json', jsonReportDirectory: "${WORKSPACE}/zautomation/tests/ios-tablet/", mergeFeaturesById: true, pendingStepsNumber: -1, skippedStepsNumber: -1, sortingMethod: 'ALPHABETICAL', undefinedStepsNumber: -1
                } else {
                    cucumber failedFeaturesNumber: -1, failedScenariosNumber: -1, failedStepsNumber: -1, fileIncludePattern: '**/target/*report*.json', jsonReportDirectory: "${WORKSPACE}/zautomation/tests/ios/", mergeFeaturesById: true, pendingStepsNumber: -1, skippedStepsNumber: -1, sortingMethod: 'ALPHABETICAL', undefinedStepsNumber: -1
                }
            } catch (e) {
                print e
                if (e instanceof hudson.AbortException) {
                    aborted = true
                }
            }
            try {
                // Generate zip-able files
                if (!tablet) {
                    // Zip and archive cucumber HTML reports
                    node("built-in") {
                        def foldername = env.JOB_NAME
                        def down = "../.."
                        if (foldername.indexOf("/") > -1) {
                            foldername = env.JOB_NAME.replace("/", "/jobs/")
                            down = "../../.."
                        } else {
                            foldername = env.JOB_BASE_NAME
                        }
                        sh returnStatus: true, script: 'rm -rf cucumber-report*.zip'
                        zip archive: true, defaultExcludes: false, dir: "${down}/jobs/${foldername}/builds/${BUILD_NUMBER}/cucumber-html-reports/", overwrite: true, zipFile: "cucumber-report_iOS_build_${REAL_BUILD_NUMBER}.zip"
                    }
                }
            } catch (e) {
                print e
                if (e instanceof hudson.AbortException) {
                    aborted = true
                }
            }
        }

        stage('Report test results') {
            def testResult = testStatuses()
            if (isTestSuccessful()) {
                if (!aborted) {
                    wireSend secret: env.JENKINSBOT_SECRET, message: "✅ **${JOB_NAME} ${BUILD_DISPLAY_NAME}**\n${filename}\n${TAGS}\nSee [JUnit Reports](${BUILD_URL}testReport/) or [Cucumber Reports](${BUILD_URL}cucumber-html-reports)\n${testResult}"
                } else {
                    wireSend secret: env.JENKINSBOT_SECRET, message: "⚠️ **${JOB_NAME} ${BUILD_DISPLAY_NAME} was aborted**\n${filename}\n${TAGS}\nSee [Console log](${BUILD_URL}console)\n${testResult}"
                }
            } else {
                wireSend secret: env.JENKINSBOT_SECRET, message: "❌ **${JOB_NAME} ${BUILD_DISPLAY_NAME}**\n${filename}\n${TAGS}\nSee [JUnit Reports](${BUILD_URL}testReport/) or [Cucumber Reports](${BUILD_URL}cucumber-html-reports)\n${testResult}"
            }
        }

    }

}
