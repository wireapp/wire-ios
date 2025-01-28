node('built-in') {

    // Select bot credentials for specific Wire conversation based on job name
    credentialsId = "JENKINSBOT_IOS_SMOKE"

    def jenkinsbot_secret = ""
    withCredentials([string(credentialsId: "${credentialsId}", variable: 'JENKINSBOT_SECRET')]) {
         jenkinsbot_secret = env.JENKINSBOT_SECRET
    }

    def commit_hash = ""
    def commit_msg = ""
    stage('Checkout wire-ios') {
      def scmVars = git branch: "$GIT_BRANCH_IOS", url: 'https://github.com/wireapp/wire-ios'
      commit_hash = scmVars.GIT_COMMIT
      commit_msg = sh returnStdout: true, script: 'git log -n 1 --pretty=format:"%an: %s"'
      commit_msg = "[${commit_msg}](https://github.com/wireapp/wire-ios/commit/${commit_hash})"
    }

    stage('Check build state') {
       try {
           withCredentials([usernameColonPassword(credentialsId: 'GITHUB_API_WEBAPP', variable: 'CREDENTIALS')]) {

               timeout(time: 3, unit: 'MINUTES') {
                   waitUntil {
                       def output = sh label: 'Get runs', returnStdout: true, script: 'curl -L -u ${CREDENTIALS} https://api.github.com/repos/wireapp/wire-ios-mono/actions/workflows/61594641/runs'
                       def json = readJSON text: output
                       if (json['message']) {
                           echo("Output: " + output)
                           error("**Trigger script failed:** " + json['message'])
                       }
                       def runs = json['workflow_runs']
                       echo("Looking for hash " + commit_hash)
                       for (run in runs) {
                           if (run['head_sha'] == commit_hash) {
                               echo("Found hash " + run['head_sha'])
                               echo("status: " + run['status'])
                               // status can be queued, in_progress, or completed
                               if (run['status'] == 'queued' || run['status'] == 'in_progress' || run['status'] == 'completed') {
                                   return true
                               }
                           }
                       }
                       sleep(20)
                       return false
                   }
               }

               timeout(time: 30, unit: 'MINUTES') {
                   waitUntil {
                       def output = sh label: 'Get runs', returnStdout: true, script: 'curl -L -u ${CREDENTIALS} https://api.github.com/repos/wireapp/wire-ios-mono/actions/workflows/61594641/runs'
                       def json = readJSON text: output
                       def runs = json['workflow_runs']
                       echo("Looking for hash " + commit_hash)
                       for (run in runs) {
                           if (run['head_sha'] == commit_hash) {
                               echo("Found hash " + run['head_sha'])
                               echo("status: " + run['status'])
                               echo("conclusion: " + run['conclusion'])
                               // conclusion can be: success, failure, neutral, cancelled, skipped, timed_out, or action_required
                               if (run['conclusion'] == 'success') {
                                   return true
                               } else if (run['conclusion'] == 'failure') {
                                   error("❌ **Build failed for branch '${GIT_BRANCH_IOS}'** See [Github Actions](" + run['url'] + ")")
                               } else if (run['conclusion'] == 'cancelled') {
                                   error("⚠️ **Build aborted for branch '${GIT_BRANCH_IOS}'** See [Github Actions](" + run['url'] + ")")
                               }
                           }
                       }
                       sleep(20)
                       return false;
                   }
               }
           }
       } catch(e) {
           wireSend secret: "$jenkinsbot_secret", message: "❌ **Github Action issue or took longer than 30 minutes** \n${commit_msg}\nSee https://github.com/wireapp/wire-webapp/branches"
           error("$e")
       }
       wireSend secret: "$jenkinsbot_secret", message: "✅ **Build finished for branch '$GIT_BRANCH_IOS'**\n${commit_msg}"
    }

    stage('Trigger test job') {
      build job: "$TEST_JOB", parameters: [string(name: 'TAGS', value: "$TAGS"), string(name: 'GIT_BRANCH', value: "$GIT_BRANCH_IOS"), string(name: 'Track', value: "Development"), string(name: 'AppBuildNumber', value: "latest")], wait: false
    }
}