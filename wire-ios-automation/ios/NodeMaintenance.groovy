node('built-in') {

    env.NODE_LABELS = "ios_tablet || ios"

    def jenkinsbot_secret = ""
    withCredentials([string(credentialsId: "JENKINSBOT_IOS", variable: 'JENKINSBOT_SECRET')]) {
        jenkinsbot_secret = env.JENKINSBOT_SECRET
    }

    nodes = nodesByLabel label: "$NODE_LABELS", offline: true

    stage('Check availability of nodes') {
        nodes.each {
            echo("Checking if node " + it + " is online...")
            if (Jenkins.instance.getNode(it).toComputer().isOnline()) {
                echo("Checking if node " + it + " is busy...")
                for (slave in hudson.model.Hudson.instance.slaves) {
                    if (slave.name.equals(it)) {
                        final comp = slave.getComputer()
                        if (comp.isOnline()) {
                            if (comp.countBusy() > 0) {
                                currentBuild.result = 'ABORTED'
                                error(slave.getNodeName() + " seems to be busy. Aborting the build...")
                            }
                        }
                    }
                }
            } else {
                echo("Node " + it + " is offline!")
            }
        }
    }

    def offline_nodes = []

    stage('Do maintenance') {
        def jobs = [:]

        for (int i = 0; i < nodes.size(); i++) {
            def nodeIndex = i
            jobs[nodes[nodeIndex]] = {
                if (Jenkins.instance.getNode(nodes[nodeIndex]).toComputer().isOnline()) {
                    node(nodes[nodeIndex]) {
                        echo("Reboot OS on node " + nodes[nodeIndex] + "...")
                        env.JENKINS_NODE_COOKIE = "dontKillMe"
                        sh '(sleep 5 && sudo shutdown -r now) &'
                        sleep 5
                    }
                    echo("Wait until node " + nodes[nodeIndex] + " shuts down...")
                    try {
                        timeout(1) {
                            waitUntil {
                                return !Jenkins.instance.getNode(nodes[nodeIndex]).toComputer().isOnline()
                            }
                        }
                    } catch (e) {
                        echo("Not restarted?")
                    }
                    echo("Wait until node " + nodes[nodeIndex] + " comes back...")
                    try {
                        timeout(3) {
                            waitUntil {
                                return Jenkins.instance.getNode(nodes[nodeIndex]).toComputer().isOnline()
                            }
                        }
                    } catch (e) {
                        echo("Node " + nodes[nodeIndex] + " is still offline!")
                        offline_nodes.add(nodes[nodeIndex])
                    }
                } else {
                    // The old script went to the parallels host machine and killed the parallels process
                    echo("Node " + nodes[nodeIndex] + " is offline!")
                    offline_nodes.add(nodes[nodeIndex])
                }
            }
        }
        parallel jobs
    }

    if (offline_nodes.size() > 0) {
        echo("Offline nodes: " + offline_nodes.join(","))
        wireSend secret: "$jenkinsbot_secret", message: "Several iOS nodes are offline: " + offline_nodes.join(", ")
    }

}