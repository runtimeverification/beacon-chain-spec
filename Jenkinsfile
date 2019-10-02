pipeline {
  options {
    ansiColor('xterm')
  }
  agent { dockerfile { } }
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
          make deps
          make test-split
        '''
      }
    }
    stage('Build') {
      steps {
        sh '''
          make KOMPILE_OPTS="--coverage" build -j2
        '''
      }
    }
    stage('Test') {
      steps {
        sh '''
          make test -j8
        '''
      }
    }
    stage('Publish') {
      steps {
        sh '''
          deps/k/k-distribution/target/release/k/bin/kcovr .build/defn/llvm/beacon-chain-kompiled \
            -- .build/defn/llvm/*.k      \
            > coverage.xml
        '''
        cobertura coberturaReportFile: 'coverage.xml'

        sh 'make sphinx'
        publishHTML (target: [
          allowMissing: false,
          alwaysLinkToLastBuild: false,
          keepAll: true,
          reportDir: '.build/sphinx-docs/html',
          reportFiles: 'index.html',
          reportName: "Semantics (HTML)"
        ])
      }
    }

  }
}
