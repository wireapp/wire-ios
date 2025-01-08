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

@NonCPS
def sortByModified(list) {
    list.sort {
        it.getLastModified()
    }
}

node("Job_distributor") {

    def aborted = false
    def TAGS = "${params.TAGS}"
    def filename = ""

    // Select bot credentials for specific Wire conversation based on job name
    if ("${JOB_NAME}" =~ /pipeline_Regression/) {
        credentialsId = "JENKINSBOT_IOS_REGRESSION"
    } else if ("${JOB_NAME}" =~ /pipeline_Call/) {
        credentialsId = "JENKINSBOT_IOS"
    } else if ("${JOB_NAME}" =~ /pipeline_realdevice_Regression/) {
        credentialsId = "JENKINSBOT_IOS_REGRESSION"
    } else if ("${JOB_NAME}" =~ /pipeline_realdevice_Staging/) {
        credentialsId = "JENKINSBOT_IOS_STAGING"
    } else if ("${JOB_NAME}" =~ /pipeline_realdevice_exp/) {
        credentialsId = "JENKINSBOT_IOS_STAGING"
    } else if ("${JOB_NAME}" =~ /exp_pipeline/) {
        credentialsId = "JENKINSBOT_IOS_EXP"
    } else if ("${JOB_NAME}" =~ /exp2_pipeline/) {
        credentialsId = "JENKINSBOT_IOS_EXP"
    } else if ("${JOB_NAME}" =~ /knownbug|unstable/) {
        credentialsId = "JENKINSBOT_IOS_STAGING"
    } else if ("${JOB_NAME}" =~ /pipeline_RC/) {
        credentialsId = "JENKINSBOT_IOS_RC"
    } else if ("${JOB_NAME}" =~ /pipeline_Smoke/) {
        credentialsId = "JENKINSBOT_IOS_SMOKE"
    } else if ("${JOB_NAME}" =~ /_Bund_/) {
        credentialsId = "JENKINSBOT_BUND"
    } else if ("${JOB_NAME}" =~ /pipeline_large_team/) {
        credentialsId = "JENKINSBOT_IOS_REGRESSION"
    } else if ("${JOB_NAME}" =~ /pipeline_experiment/) {
        credentialsId = "JENKINSBOT_IOS_STAGING"
    } else if ("${JOB_NAME}" =~ /pipeline_regression_x86/) {
        credentialsId = "JENKINSBOT_IOS_REGRESSION"
    } else if ("${JOB_NAME}" =~ /iOS_Critical_Flows/) {
        credentialsId = "JENKINSBOT_IOS_SMOKE"
    } else if ("${JOB_NAME}" =~ /iOS_Navigation_Overhaul/) {
            credentialsId = "JENKINSBOT_IOS_SMOKE"
    } else {
        credentialsId = "JENKINSBOT_IOS_EXP"
    }

    // Select grid
    if (params.Grid == "iOS-realdevice") {
        hubUrl = "http://192.168.2.70:4444/wd/hub"
        is_simulator = false
        deviceName = "iPhone 11"
        platformVersion = "16.3"
        nodeLabels = "iOS_node070"
        MAX_PARALLEL = nodesByLabel(nodeLabels).size()
    } else if (params.Grid == "iOS-phones-arm64") {
        hubUrl = "http://192.168.2.200:4444/wd/hub"
        is_simulator = true
        deviceName = "iPhone 11"
        platformVersion = "16.4"
        nodeLabels = "iOS_node200"
        MAX_PARALLEL = 5
    } else if (params.Grid == "iOS-phones-arm64-fast") {
        hubUrl = "http://192.168.2.203:4444/wd/hub"
        is_simulator = true
        deviceName = "iPhone 11"
        platformVersion = "16.4"
        nodeLabels = "iOS_node203"
        MAX_PARALLEL = 15
    } else {
        error("Grid " + params.Grid + " is not supported yet!")
    }

    echo("Configure 1Password integration")
    def config = [
            serviceAccountCredentialId: '1PasswordServiceAccountToken',
            opCLIPath: "/usr/local/bin/"
    ]
    def secrets = [
            [envVar: 'OKTA_API_KEY', secretRef: 'op://QA automation/OKTA_API_KEY/password'],
            [envVar: 'KEYCLOAK_PASSWORD', secretRef: 'op://QA automation/KEYCLOAK_PASSWORD/password'],
            [envVar: 'LH_SERVICE_AUTH_TOKEN', secretRef: 'op://QA automation/LH_SERVICE_AUTH_TOKEN/password'],
            [envVar: 'STRIPE_API_KEY', secretRef: 'op://QA automation/STRIPE_API_KEY/password'],
            [envVar: 'MS_EMAIL', secretRef: 'op://QA automation/MS_CREDENTIALS/username'],
            [envVar: 'MS_PASSWORD', secretRef: 'op://QA automation/MS_CREDENTIALS/password'],
            [envVar: 'BLACKLIST_S3_SECRET', secretRef: 'op://QA automation/BLACKLIST_S3_SECRET/password'],
            [envVar: 'TESTINY_API_KEY', secretRef: 'op://QA automation/TESTINY_API_KEY_IOS/password'],
    ]

    // Use 1Password secrets
    withSecrets(config: config, secrets: secrets) {
        // Use Jenkins credentials
        withCredentials([
                string(credentialsId: '1PasswordServiceAccountToken', variable: 'OP_SERVICE_ACCOUNT_TOKEN'),
                file(credentialsId: 'KUBECONFIG_anta', variable: 'KUBECONFIG_anta'),
                file(credentialsId: 'KUBECONFIG_bella', variable: 'KUBECONFIG_bella'),
                file(credentialsId: 'KUBECONFIG_chala', variable: 'KUBECONFIG_chala'),
                file(credentialsId: 'KUBECONFIG_foma', variable: 'KUBECONFIG_foma'),
                file(credentialsId: 'KUBECONFIG_gudja_offline_ios', variable: 'KUBECONFIG_gudja_offline_ios'),
                file(credentialsId: 'KUBECONFIG_bund_next_column_1', variable: 'KUBECONFIG_bund_next_column_1'),
                file(credentialsId: 'KUBECONFIG_bund_qa_column_1', variable: 'KUBECONFIG_bund_qa_column_1'),
                string(credentialsId: "${credentialsId}", variable: 'JENKINSBOT_SECRET')
        ]) {

            // Checkout
            stage('Checkout & Clean') {

                echo("Checkout common")
                checkout(
                        [$class: 'GitSCM',
                         branches: [[name: '*/main']],
                         doGenerateSubmoduleConfigurations: false,
                         extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'common'],
                                      [$class: 'SparseCheckoutPaths', sparseCheckoutPaths: [[path: 'tests/common']]],
                                      [$class: 'CheckoutOption', timeout: 30],
                                      [$class: 'CloneOption', depth: 0, noTags: true, reference: '', shallow: true, timeout: 30],
                                      [$class: 'BuildChooserSetting', buildChooser: [$class: 'DefaultBuildChooser']]],
                         submoduleCfg: [],
                         userRemoteConfigs: [[credentialsId: 'zautomation', url: 'git@github.com:zinfra/zautomation.git']]])

                checkout([$class: 'GitSCM',
                          branches: [[name: '*/${Branch}']],
                          doGenerateSubmoduleConfigurations: true,
                          extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'wire-ios'],
                                       [$class: 'SparseCheckoutPaths', sparseCheckoutPaths: [[path: 'wire-ios-automation/ios'], [path: 'wire-ios-automation/tools']]],
                                       [$class: 'CheckoutOption', timeout: 30],
                                       [$class: 'CloneOption', depth: 0, noTags: true, reference: '', shallow: true, timeout: 30],
                                       [$class: 'BuildChooserSetting', buildChooser: [$class: 'DefaultBuildChooser']]],
                          submoduleCfg: [],
                          userRemoteConfigs: [[credentialsId: 'zautomation', url: 'git@github.com:wireapp/wire-ios.git']]])

                echo("Installing kubectl if not already installed")
                kubeCtlSetup = readFile("${WORKSPACE}/common/tests/common/kubectlSetup.sh")
                sh kubeCtlSetup
            }

            // TODO: Move this back into the test stage when a solution is found that does not override Wire.ipa in a second parallel run
            lock("${Grid}") {
                stage('Download build from S3 to grid nodes') {
                    // Get ipa from S3 depending on track name
                    load('wire-ios/wire-ios-automation/ios/RetrieveIPA.Jenkinsfile.groovy').setIPAFromS3(env.Track, appBuildNumber, is_simulator)
                    echo("OldS3AppPath: ${OldS3AppPath}")

                    env.REAL_BUILD_NUMBER = (env.S3AppPath =~ /([0-9]+).ipa/)[0][1]
                    echo("REAL_BUILD_NUMBER: " + env.REAL_BUILD_NUMBER)

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

                withMaven(jdk: 'JDK17', maven: 'M3', mavenOpts: '-Xmx1024m', mavenLocalRepo: '.repository', options: [junitPublisher(disabled: true), jacocoPublisher(disabled: true)]) {

                    stage('Build common') {
                        echo("Check 1Password Installation")
                        sh "sh $WORKSPACE/common/tests/common/src/main/resources/install1PasswordCLIOnNode.sh"

                        echo("Get backend connections...")
                        sh "sh $WORKSPACE/common/tests/common/src/main/resources/backendConnections.sh"

                        env.RC_TESTS_COMMENT_PATH = "$WORKSPACE/rc_comment.txt"
                        sh 'echo "${JOB_NAME} ${BUILD_DISPLAY_NAME} - Cucumber Report: ${JENKINS_URL}job/${JOB_NAME}/${BUILD_NUMBER}/cucumber-html-reports/" > $RC_TESTS_COMMENT_PATH'

                        sh """
mvn clean install \\
-f "$WORKSPACE/common/tests/common/pom.xml" \\
-DbackendType="${backendType}" \\
-DbackendConnections="${WORKSPACE}/backendConnections.json" \\
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

                    stage('Run tests') {
                        try {
                            timeout(time: 6, unit: 'HOURS') {
                                realtimeJUnit(keepLongStdio: true, testDataPublishers: [[$class: 'JUnitFlakyTestDataPublisher']], testResults: 'wire-ios/wire-ios-automation/ios/target/xml-reports/TEST*.xml') {
                                    sh """
mvn clean integration-test \\
-f "$WORKSPACE/wire-ios/wire-ios-automation/ios/pom.xml" \\
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

            } // End of lock

            stage('Generate test results') {
                try {
                    // Generate Jenkins cucumber HTML reports and archive JSON
                    archiveArtifacts artifacts: '**/target/*report*.json', followSymlinks: false
                    cucumber failedFeaturesNumber: -1, failedScenariosNumber: -1, failedStepsNumber: -1, fileIncludePattern: '**/target/*report*.json', jsonReportDirectory: "${WORKSPACE}/wire-ios/wire-ios-automation/ios/", mergeFeaturesById: true, pendingStepsNumber: -1, skippedStepsNumber: -1, sortingMethod: 'ALPHABETICAL', undefinedStepsNumber: -1
                } catch (e) {
                    print e
                    if (e instanceof hudson.AbortException) {
                        aborted = true
                    }
                }
                try {
                    // Generate zip-able files
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
}