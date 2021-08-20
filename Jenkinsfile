pipeline {
    agent any
    stages {
        stage('github repo') {
            steps {
                echo "github url"
                sh "git: 'https://github.com/jglick/simple-maven-project-with-tests'"
            }
        }
    }
}
