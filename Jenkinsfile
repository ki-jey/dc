
pipeline {
    agent {
        kubernetes {
            label "b${env.BUILD_ID}t${currentBuild.startTimeInMillis}-pipeline"
            defaultContainer "jnlp"
            yaml """
                apiVersion: v1
                kind: Pod
                spec:
                  volumes:
                  - name: fileserver-james-volume
                    persistentVolumeClaim:
                      claimName: fileserver-james-claim
                  containers:
                  - name: busybox
                    image: busybox
                    tty: true
                    command: [ "cat" ]
                    volumeMounts:
                    - mountPath: "/fileserver-james"
                      name: fileserver-james-volume
                    resources:
                      requests:
                        memory: "256Mi"
                        cpu: "0.1"
                  - name: aws-cli
                    image: amazon/aws-cli
                    tty: true
                    command: [ "cat" ]
                    resources:
                      requests:
                        memory: "256Mi"
                        cpu: "0.1"
                """.stripIndent()
        }
    }
    options {
        timeout time: 15, unit: 'MINUTES'
        gitLabConnection('gitlab-ee-censhare')
    }

    parameters {
        string(name: 'CUSTOM_COMMIT', defaultValue: 'HEAD', description: '[Optional] Run the pipeline on a specific COMMIT or TAG instead of the branch HEAD. For example: f4c79b41794 or censhare_2019.3.9')
        booleanParam(name: 'IS_A_RELEASE_BUILD', defaultValue: false, description: '[Optional] If enabled, different Ant targets will be used and the last pipeline stage will promote all artifacts to the QA repositories')
    }

    environment {
        CENSHARE_DEV          = "censhare-dev"         // generic dev repos for libs and tar.gz releses from stage "Server"
        CENSHARE_QA           = "censhare-qa"          // generic staging repo for QA
        LIBS_RELEASE_LOCAL    = "libs-release-local"   // Maven repo
        LIBS_SNAPSHOT_LOCAL   = "libs-snapshot-local"
    }
    stages {
        stage('Server') {
            agent {
                kubernetes {
                    label "${CONTAINER_PREFIX}-server"
                    defaultContainer "jnlp"
                    yaml """
                        apiVersion: v1
                        kind: Pod
                        spec:
                          volumes:
                          - name: fileserver-james-volume
                            persistentVolumeClaim:
                              claimName: fileserver-james-claim
                          - name: git-cache
                            nfs:
                              path: /vol_censhare_data_nfs_build_tools/git-cache
                              server: 10.158.0.7
                          containers:
                          - name: jnlp
                            image: docker.censhare.com/jenkins/jenkins-build-corretto11and8:r4
                            tty: true
                            volumeMounts:
                            - mountPath: /fileserver-james
                              name: fileserver-james-volume
                            - mountPath: /git-cache
                              name: git-cache
                            resources:
                              requests:
                                memory: "4Gi"
                                cpu: "2"
                        """.stripIndent()
                }
            } // agent
            options {
                timeout time: 15, unit: 'MINUTES'
            }
            steps {
                gitlabCommitStatus("Server build") {
                    checkout scm
                    script{
                        LATEST_OWASP=$(curl 'https://jeremylong.github.io/DependencyCheck/current.txt')
                        sh "curl -O -L https://dl.bintray.com/jeremy-long/owasp/dependency-check-${env.LATEST_OWASP}-release.zip"
                        sh 'ls && pwd'
                        unzip zipFile: "dependency-check-${env.LATEST_OWASP}-release.zip", dir: './'
                        sh 'ls && pwd'
                        sh 'git clone https://git.censhare.com/vne/dc.git && tar -xzf ./dc/dc.tar.gz -C ./dc'
                        sh 'ls && pwd'
                        sh "./dependency-check/bin/dependency-check.sh -f HTML -f XML -s ./censhare-Server -o . --project censhare-Server_test"
                        sh 'ls && pwd'
                        //sh "./dependency-check/bin/dependency-check.sh -f HTML -f XML -s ./censhare-Server -o . --project censhare-Server_${env.BRANCH_NAME}"
                        //sh "./dependency-check/bin/dependency-check.sh -f HTML -s ./censhare-Server/3rdparty-libs -o ./dependency-check-3rdPartyLibs.html --project censhare-Server_3rdPartyLibs-${env.BRANCH_NAME}"
                        dependencyCheckPublisher pattern: 'dependency-check-report.xml'
                        //zip archive: true, glob: 'dependency-check-*.*', zipFile: "dependency-check-reports.zip";
                    }
                } // gitlabCommitStatus
            } // steps
        } // stage Server
    } // stages
} // pipeline