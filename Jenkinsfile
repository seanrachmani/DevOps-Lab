pipeline {
    agent any

    options {
        disableConcurrentBuilds()
    }

    stages {
        stage('Build and test') {
            steps {
                sh 'bash scripts/ci.sh'
            }
        }
    }
}
