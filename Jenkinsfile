pipeline {
  options {
    ansiColor('xterm')
  }
  agent {
    dockerfile {
      additionalBuildArgs '--build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)'
      args '-m 60g'
    }
  }
  stages {
    stage('Init title') {
      when { changeRequest() }
      steps {
        script {
          currentBuild.displayName = "PR ${env.CHANGE_ID}: ${env.CHANGE_TITLE}"
        }
      }
    }
    stage('Dependencies') {
      steps {
        sh '''
          export PATH=$HOME/.local/bin:$HOME/.cargo/bin:$PATH
          make deps
        '''
      }
    }
    stage('Build') {
      steps {
        sh '''
          export PATH=$HOME/.local/bin:$HOME/.cargo/bin:$PATH
          make build
        '''
      }
    }
  }
}
