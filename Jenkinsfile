pipeline {

  agent any

  environment {
    APP_NAME = 'janus-webrtc-gateway'
  }

  stages {

    stage('Build') {
      steps {

        sh './build.sh'
      }
    }
  }
}
