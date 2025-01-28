pipeline {
    agent {
        label 'iOS_simu_node070'
    }

    options {
        disableConcurrentBuilds()
    }

    // NOTE: run every hour
    triggers {
        pollSCM 'H * * * *'
    }

    stages {
        stage('Requirements') {
            steps {
                sh 'pip3 install --user brainstem --upgrade'
                writeFile file: 'powercycle.py', text: '''import datetime
import time

from brainstem import discover
from brainstem.link import Spec
from brainstem.stem import USBHub2x4

NOW = datetime.datetime.now()

if __name__ == \'__main__\':
    stem = USBHub2x4()
    spec = discover.findFirstModule(Spec.USB)
    if spec is None:
        raise RuntimeError("No USBHub is connected!")
    stem.connectFromSpec(spec)
    print(\'Current hour is: {}\'.format(NOW.hour))
    if (NOW.hour < 10) or (NOW.hour > 20):
        print(\'Power ON for all USB ports\')
        stem.usb.setPowerEnable(0)
        stem.usb.setPowerEnable(1)
        stem.usb.setPowerEnable(2)
        stem.usb.setPowerEnable(3)
    else:
        stem.usb.setPowerDisable(0)
        stem.usb.setPowerDisable(1)
        stem.usb.setPowerDisable(2)
        stem.usb.setPowerDisable(3)
        print(\'Power OFF for all USB ports\')
'''
            }
        }
        stage('Run') {
            steps {
                sh 'python3 powercycle.py'
            }
        }
    }
}