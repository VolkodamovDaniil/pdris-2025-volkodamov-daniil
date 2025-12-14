pipeline {
    agent any
    
    tools {
        jdk 'jdk17'
        maven 'maven'
    }
    
    environment {
        // Используем автоматически установленные пути
        NEXUS_URL = "nexus:8081"
        NEXUS_CREDENTIALS_ID = "nexus_cred"
        SONAR_TOKEN = credentials('sonar_token')
    }

    stages {
        stage('Environment Check') {
            steps {
                sh """
                    echo "=== Environment Check ==="
                    echo "Java version:"
                    java -version
                    echo "Maven version:"
                    mvn -version
                    echo "Current directory:"
                    pwd
                    echo "Tools are automatically configured by Jenkins"
                """
            }
        }
        
        stage('Git Clone') {
            steps {
                git branch: 'main', 
                url: 'https://github.com/VolkodamovDaniil/my-jenkins-app.git'
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                script {
                    try {
                        withSonarQubeEnv('sonarqube') {
                            sh """
                                mvn sonar:sonar \
                                -Dsonar.projectKey=my-jenkins-app \
                                -Dsonar.host.url=http://sonarqube:9000 \
                                -Dsonar.login=${SONAR_TOKEN}
                            """
                        }
                    } catch (Exception e) {
                        echo "SonarQube analysis skipped: ${e.message}"
                    }
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                sh 'mvn test'
            }
        }
        
        stage('Generate Allure Report') {
            steps {
                script {
                    try {
                        sh 'mvn allure:report 2>/dev/null || echo "Allure report generation failed"'
                        
                        allure([
                            includeProperties: false,
                            jdk: '',
                            results: [[path: 'target/allure-results']]
                        ])
                    } catch (Exception e) {
                        echo "Allure report skipped: ${e.message}"
                        junit 'target/surefire-reports/*.xml'
                    }
                }
            }
        }
        
        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }
        
        stage('Deploy to Nexus') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    def artifactId = pom.artifactId
                    def version = pom.version
                    def jarFile = "target/${artifactId}-${version}.jar"
                    
                    echo "Uploading ${jarFile} to Nexus..."
                    
                    sh "ls -la ${jarFile} || echo 'JAR file not found!'"
                    
                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: NEXUS_URL,
                        groupId: pom.groupId,
                        version: version,
                        repository: 'maven-releases',
                        credentialsId: NEXUS_CREDENTIALS_ID,
                        artifacts: [
                            [artifactId: artifactId,
                             classifier: '',
                             file: jarFile,
                             type: 'jar']
                        ]
                    )
                    
                    echo "Artifact successfully deployed to Nexus"
                }
            }
        }
    }
}