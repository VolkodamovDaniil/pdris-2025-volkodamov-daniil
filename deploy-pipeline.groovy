pipeline {
    agent any
    
    environment {
        NEXUS_URL = "nexus:8081"
        NEXUS_CREDENTIALS_ID = "nexus_cred"
        ARTIFACT_PATH = "com/example/my-jenkins-app/1.0.0/my-jenkins-app-1.0.0.jar"
    }

    stages {
        stage('Download from Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: NEXUS_CREDENTIALS_ID,
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh '''
                        curl -u "${NEXUS_USER}:${NEXUS_PASS}" \
                             -L -o /tmp/my-jenkins-app-1.0.0.jar \
                             "${NEXUS_URL}/repository/maven-releases/${ARTIFACT_PATH}"
                    '''
                }
            }
        }

        stage('Git clone ansible') {
            steps {
                git branch: 'main', url: 'https://github.com/VolkodamovDaniil/ansible-deploy.git'
            }
        }

        stage('Run ansible') {
            steps {
                sh 'ansible-playbook -i inventory/hosts deploy.yml'
            }
        }
    }
}