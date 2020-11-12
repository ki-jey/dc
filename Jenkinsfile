
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
        LATEST_OWASP          = "$(curl https://jeremylong.github.io/DependencyCheck/current.txt)"

        // destinations artifactory repositories for the build artifacts
        CENSHARE_DEV          = "censhare-dev"         // generic dev repos for libs and tar.gz releses from stage "Server"
        CENSHARE_QA           = "censhare-qa"          // generic staging repo for QA
        LIBS_RELEASE_LOCAL    = "libs-release-local"   // Maven repo
        LIBS_SNAPSHOT_LOCAL   = "libs-snapshot-local"  // Maven repo
        RPM_DEV               = "rpm-dev"
        RPM_QA                = "rpm-qa"
        DOCKER_DEV            = "docker-dev"
        DOCKER_QA             = "docker-qa"
        RPM_PATH              = ""              // eg. ${RPM_DEV}/stable/censhare/${VERSION_MAJOR}/${VERSION_MINOR}
        RPM_FILE_SERVER         = ""
        RPM_FILE_SERVICECLIENT  = ""
        DOCKER_CENSHARE       = "censhare"      // eg. docker-dev.censhare.com/${DOCKER_CENSHARE}/censhare-server:${VERSION_LONG}
        FILESERVER_PATH       = "/fileserver-james"  // CIFS mount on the kubernetes node
        STAGING_DIR           = "/fileserver-james/ZZ_Build_Staging"

        // version related variables
        VERSION_LONG      = "" // eg. 2019.2.2 (grep from censhare-Server/build.common.properties. Sometimes ending on a1, b3 etc. )
        VERSION_SHORT     = "" // eg. 2019.2
        VERSION_MAJOR     = "" // eg. 2019
        VERSION_MINOR     = "" // eg. 2

        // EPOCH_SEC is a workaround, because build numbers in multibranch pipeline are not unique across branches. The goal is to have unique, short and incremental number.
        EPOCH_SEC = "${(int) (currentBuild.startTimeInMillis / 1000 - 1576800000) }"  // seconds since unix epoch minus 50 years (60*60*24*365*50=1576800000)
        BUILD_UNIQ = "b${env.BUILD_ID}t${EPOCH_SEC}"  // used on only for JOB_PREFIX. I will probably merge both variables in few weeks

        // others
        LAST_COMMITTER_EMAIL = "no-reply@censhare.com" // mailext() in post{} with Kubernetes plugin can't get recipientProviders with culprits()
        BRANCH_NAME_HYPHENS = "${env.BRANCH_NAME}".toLowerCase().replaceAll("[^a-z0-9]","-")
        JOB_PREFIX = "${BUILD_UNIQ}-${BRANCH_NAME_HYPHENS}" // BUILD_TAG doesn't fit out needs
        CONTAINER_PREFIX = "${JOB_PREFIX.substring(0, Math.min(50, JOB_PREFIX.length()))}" // kubernetes container name is limited to 63 characters, RFC 1035
        CUSTOM_COMMIT = "${params.CUSTOM_COMMIT}"  // workaround of MissingPropertyException with JENKINS-40574, JENKINS-41929

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
//                         LATEST_OWASP=sh 'curl https://jeremylong.github.io/DependencyCheck/current.txt'
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