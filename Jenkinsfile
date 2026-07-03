pipeline {
    agent any 
    
    options {
        // timeout(time: 90, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    triggers {
        // cron('H 0 * * *')
        pollSCM('H/5 * * * *')
    }
    
    stages {
        stage('Execute Containerized Tests') {
            steps {
                echo 'Spawning clean Ubuntu environment and running tests...'
                
                // We use the official riot/riotbuild container which comes with all toolchains pre-installed
                bat 'docker run --rm -v "%WORKSPACE%":/build riot/riotbuild bash /build/ci-test.sh'
            }
        }
    }

    post {
        always {
            echo 'Cleaning up Windows host workspace...'
            cleanWs deleteDirs: true, notFailBuild: true
        }
    }
}
