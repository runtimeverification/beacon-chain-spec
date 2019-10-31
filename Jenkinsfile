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
    stage('Test - LLVM') {
      steps {
        sh '''
          make test-llvm -j8
        '''
      }
    }
    stage('Test - Haskell') {
      steps {
        sh '''
          make test-haskell -j8
        '''
      }
    }
    stage('Publish to Jenkins') {
      steps {
        sh '''
          deps/k/k-distribution/target/release/k/bin/kcovr .build/defn/llvm/beacon-chain-kompiled \
            -- .build/defn/llvm/*.k      \
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
      stages {
        stage('Initialize Git/SSH') {
          steps {
            sshagent(['2b3d8d6b-0855-4b59-864a-6b3ddf9c9d1a']) {
              sh '''
                git config --global user.email "admin@runtimeverification.com"
                git config --global user.name  "RV Jenkins"
                mkdir -p ~/.ssh
                echo 'host github.com'                       > ~/.ssh/config
                echo '    hostname github.com'              >> ~/.ssh/config
                echo '    user git'                         >> ~/.ssh/config
                echo '    identityagent SSH_AUTH_SOCK'      >> ~/.ssh/config
                echo '    stricthostkeychecking accept-new' >> ~/.ssh/config
                chmod go-rwx -R ~/.ssh
                ssh github.com || true
              '''
            }
          }
        }
        stage('Push GitHub Pages') {
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
  }
}

