def devices = [
        "Roku 3 172.27.0.230" : [
                roku_dev_target: "172.27.0.230",
                devpassword    : "1234",
                labels         : ["roku", "roku_functional_tests"]
        ],
        "Roku 3 172.27.0.78"  : [
                roku_dev_target: "172.27.0.78",
                devpassword    : "1234",
                labels         : ["roku", "roku_functional_tests"]
        ],
        "Roku Ultra Simon"    : [
                roku_dev_target: "172.27.0.57",
                devpassword    : "1234",
                labels         : ["roku", "roku_functional_tests"]
        ],
        "Roku Streaming Stick": [
                roku_dev_target: "172.27.0.178",
                devpassword    : "1234",
                labels         : ["roku", "roku_signing"]
        ],
        "Arya": [
                roku_dev_target: "172.27.0.61",
                devpassword    : "1234",
                labels         : ["roku", "roku_functional_tests"]
        ]
]

pipeline {
    agent any
    options {
        skipDefaultCheckout true
    }

    stages {
        // Triggered by a pull request being opened on the truex-roku-google-ad-manager-reference-app repository
        // Clones truex-roku-google-ad-manager-reference-app repository on the branch that triggered this build
        stage('Clone Source Repositories') {
            when {
                // ignore commits added by Jenkins CI (build increments, for example)
                not { changelog '^Jenkins-CI:' }
                beforeAgent true
            }
            steps {
                echo "(>'-')> <('-'<) ^('-')^ v('-')v(>'-')> (^-^)"
                echo "<('-')> Beginning Clone Source Repositories stage of truex-roku-google-ad-manager-reference-app <('-')>"
                echo "(>'-')> <('-'<) ^('-')^ v('-')v(>'-')> (^-^)"

                dir('truex-roku-google-ad-manager-reference-app') {
                    echo "Cloning reference app repository on branch $env.BRANCH_NAME..."
                    checkout scm
                }

                echo "(>'-')> <('-'<) ^('-')^ v('-')v(>'-')> (^-^)"
                echo "<('-')> Completed Clone Source Repositories stage of truex-roku-google-ad-manager-reference-app <('-')>"
                echo "(>'-')> <('-'<) ^('-')^ v('-')v(>'-')> (^-^)"
            }
        }
        // Sets up environment variables (JAVA_HOME, PATH), writes .rokuTarget test file in whakapapa and southback
        stage('Build') {
            when {
                not { changelog '^Jenkins-CI:' }
                beforeAgent true
            }
            stage('Build TAR-Roku') {
                steps {
                    echo "(>'-')> <('-'<) ^('-')^ v('-')v(>'-')> (^-^)"
                    echo "<('-')> Beginning Build stage of truex-roku-google-ad-manager-reference-app <('-')>"
                    echo "(>'-')> <('-'<) ^('-')^ v('-')v(>'-')> (^-^)"

                    dir('truex-roku-google-ad-manager-reference-app') {
                        echo "Installing truex-roku-google-ad-manager-reference-app Channel..."
                        sh 'make install'
                        echo "<('-')> truex-roku-google-ad-manager-reference-app Channel installed <('-')>"
                    }

                    echo "(>'-')> <('-'<) ^('-')^ v('-')v(>'-')> (^-^)"
                    echo "<('-')> Completed Build stage of truex-roku-google-ad-manager-reference-app <('-')>"
                    echo "(>'-')> <('-'<) ^('-')^ v('-')v(>'-')> (^-^)"
                }
            }
        }
        stage('Smoke Test') {
        }
    }
}
