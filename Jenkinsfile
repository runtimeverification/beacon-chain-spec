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
    stage('Coverage') {
      steps {
        sh '''
          deps/k/k-distribution/target/release/k/bin/kcovr .build/defn/llvm/beacon-chain-kompiled \
            -- .build/defn/llvm/*.k      \
            > coverage.xml
        '''
        cobertura coberturaReportFile: 'coverage.xml'
      }
    }
  }
}
