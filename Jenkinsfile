
pipeline {
    agent none

    options {
        timeout time: 15, unit: 'MINUTES'
        gitLabConnection('gitlab-ee-censhare')
    }

    triggers {
        cron("H 4 * * 1-5")
    }

    stages {
        stage('Update dependency check') {
            steps {
                node('maven&&build&&ojdk11') {
                    gitlabCommitStatus("tests") {
                        checkout scm
                        script {
                            script {
                                sh 'rm dc.zip'
                                LATEST_OWASP = sh (returnStdout: true, script: "curl https://jeremylong.github.io/DependencyCheck/current.txt").trim()
                                sh "curl -O -L https://dl.bintray.com/jeremy-long/owasp/dependency-check-${LATEST_OWASP}-release.zip"
                                unzip zipFile: "dependency-check-${LATEST_OWASP}-release.zip", dir: './'
                                sh "chmod -R 777 dependency-check && ./dependency-check/bin/dependency-check.sh -f HTML -s . -o ./dependency-check/update.html --project update"
                                zip archive: true, glob: 'dependency-check', zipFile: "dc.zip";
                                sh "rm dependency-check-${LATEST_OWASP}-release.zip && rm -rf dependency-check"
                                sh 'git status'
                                sh "git config --global user.email 'jenkins.user@censhare.com' && git config --global user.name 'Jenkins user'"
                                sh "git add . && git commit -m 'daily-update'"
                                sh 'git status'
                                sh 'git config user.email && git config user.name'

                                withCredentials([usernamePassword(credentialsId: '1d73a515-5d91-4cc7-926a-0f56d67a2f0e',
                                            passwordVariable: 'GIT_PASSWORD',
                                            usernameVariable: 'GIT_USERNAME')]) {
                                    sh('git push https://${GIT_USERNAME}:${GIT_PASSWORD}@git.censhare.com/vne/dc.git master')
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}