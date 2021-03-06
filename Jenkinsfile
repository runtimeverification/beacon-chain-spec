pipeline {
  options { ansiColor('xterm') }
  agent {
    dockerfile {
      label 'docker'
      additionalBuildArgs '--build-arg K_COMMIT=$(cd deps/k && git rev-parse --short=7 HEAD)'
    }
  }
  stages {
    stage('Init title') {
      when { changeRequest() }
      steps { script { currentBuild.displayName = "PR ${env.CHANGE_ID}: ${env.CHANGE_TITLE}" } }
    }
    stage('Build')       { steps { sh 'make KOMPILE_OPTS=--coverage build -j2' } }
    stage('Split Tests') { steps { sh 'make test-split'                        } }
    stage('Test')        { steps { sh 'make test -j8'                          } }
    stage('Publish to Jenkins') {
      steps {
        sh '''
          kcovr .build/defn/llvm-minimal/beacon-chain-kompiled \
            -- .build/defn/llvm-minimal/*.k                    \
            > coverage.xml
        '''
        cobertura coberturaReportFile: 'coverage.xml'

        sh 'make sphinx'
        stash name: 'html_docs', includes: '.build/sphinx-docs/html/**/*'
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
    stage('Deploy documentation to GitHub Pages') {
      when { branch 'master' }
      options { skipDefaultCheckout() }
      post {
        failure {
          slackSend color: '#cb2431'                            \
                  , channel: '#beacon-chain-internal'                  \
                  , message: "Deploy failure: ${env.BUILD_URL}"
        }
      }
      steps {
        unstash 'html_docs'
        dir('gh-pages') { sshagent(['2b3d8d6b-0855-4b59-864a-6b3ddf9c9d1a']) {
          git branch: 'gh-pages', url: 'git@github.com:runtimeverification/beacon-chain-spec'
          sh '''
            cp -rf ../.build/sphinx-docs/html/* .
            git add --all
            git commit -am "Updating public documentation." || true
            git push --set-upstream origin gh-pages
          '''
        } }
      }
    }
  }
}

