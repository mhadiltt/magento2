pipeline {
    agent {
        kubernetes {
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsUser: 0
  containers:
    - name: php
      image: hadil01/php-base:8.2
      imagePullPolicy: IfNotPresent
      command: ["cat"]
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
          readOnly: false

    - name: docker
      image: docker:24.0.6-dind
      securityContext:
        privileged: true
      env:
        - name: DOCKER_TLS_CERTDIR
          value: ""
      volumeMounts:
        - name: docker-graph-storage
          mountPath: /var/lib/docker
        - name: docker-socket
          mountPath: /var/run
        - name: workspace-volume
          mountPath: /home/jenkins/agent
          readOnly: false

    - name: argocd
      image: hadil01/argocd-cli:latest
      imagePullPolicy: IfNotPresent
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
          readOnly: false

    - name: jnlp
      image: jenkins/inbound-agent:latest
      imagePullPolicy: IfNotPresent
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
          readOnly: false

  volumes:
    - name: docker-socket
      emptyDir: {}
    - name: docker-graph-storage
      emptyDir: {}
    - name: workspace-volume
      emptyDir: {}
"""
        }
    }

    environment {
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        PHP_IMAGE_REPO = "hadil01/pipe-php"
        NGINX_IMAGE_REPO = "hadil01/pipe-nginx"
        DOCKERHUB_CREDS = 'dockerhub-pass'
        ARGOCD_CREDS = 'argocd-jenkins-creds'
        ARGOCD_SERVER = "argocd-server.argocd.svc.cluster.local:443"
        ARGOCD_APP_NAME = "magento2"
        CI = "true" // signal for scripts to skip OpenSearch
    }

    stages {

        stage('📥 Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('⚙️ Magento Prepare (setup, compile, static)') {
            steps {
                container('php') {
                    sh '''
                        set -e
                        echo "===================================="
                        echo "Running Magento Preparation Script (No OpenSearch)"
                        echo "===================================="

                        chmod +x scripts/magento-prepare.sh
                        ./scripts/magento-prepare.sh

                        echo "✅ Magento preparation completed"
                    '''
                }
            }
        }

        stage('🔐 Docker Login') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            set -e
                            echo "🔐 Logging into DockerHub..."
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        '''
                    }
                }
            }
        }

        stage('🐘 Build & Push PHP Image') {
            steps {
                container('docker') {
                    sh '''
                        set -e
                        echo "🐘 Building PHP Image..."
                        docker build -t $PHP_IMAGE_REPO:$IMAGE_TAG -f docker/php/Dockerfile.php .
                        docker push $PHP_IMAGE_REPO:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('🌐 Build & Push NGINX Image') {
            steps {
                container('docker') {
                    sh '''
                        set -e
                        echo "🌐 Building NGINX Image..."
                        docker build -t $NGINX_IMAGE_REPO:$IMAGE_TAG -f docker/nginx/Dockerfile.nginx .
                        docker push $NGINX_IMAGE_REPO:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('🚀 ArgoCD Sync') {
            steps {
                container('argocd') {
                    withCredentials([usernamePassword(credentialsId: env.ARGOCD_CREDS, usernameVariable: 'ARGOCD_USER', passwordVariable: 'ARGOCD_PASS')]) {
                        sh '''
                            set -e
                            echo "🔑 Logging into ArgoCD..."
                            argocd login $ARGOCD_SERVER --username $ARGOCD_USER --password $ARGOCD_PASS --insecure

                            echo "🧩 Updating Helm values..."
                            argocd app set $ARGOCD_APP_NAME \
                                --helm-set php.image.tag=$IMAGE_TAG \
                                --helm-set nginx.image.tag=$IMAGE_TAG

                            echo "🔄 Syncing ArgoCD..."
                            argocd app sync $ARGOCD_APP_NAME --async --prune --force
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Magento Build & ArgoCD Deployment completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed! Check Jenkins logs for details."
        }
    }
}
