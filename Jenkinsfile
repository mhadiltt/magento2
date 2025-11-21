pipeline {
    agent {
        kubernetes {
            defaultContainer 'docker'
            yaml """
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsUser: 0
  containers:
    - name: docker
      image: docker:24.0.6-dind
      imagePullPolicy: IfNotPresent
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
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent

    - name: jnlp
      image: jenkins/inbound-agent:latest
      imagePullPolicy: IfNotPresent
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent

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
    }

    stages {

        stage('📥 Checkout Code') {
            steps {
                checkout scm
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
                        echo "🐘 Building PHP Image: $PHP_IMAGE_REPO:$IMAGE_TAG ..."
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
                        echo "🌐 Building NGINX Image: $NGINX_IMAGE_REPO:$IMAGE_TAG ..."
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

                            echo "🧩 Updating Helm values with new image tags (php & nginx only)..."
                            argocd app set $ARGOCD_APP_NAME \
                                --helm-set php.image.tag=$IMAGE_TAG \
                                --helm-set nginx.image.tag=$IMAGE_TAG

                            echo "🔄 Syncing ArgoCD application..."
                            n=0
                            until [ "$n" -ge 5 ]
                            do
                              if argocd app sync $ARGOCD_APP_NAME --async --prune --force; then
                                echo "✅ ArgoCD sync started successfully!"
                                break
                              fi
                              echo "⚠️ Sync attempt $((n+1)) failed, retrying in 10s..."
                              n=$((n+1))
                              sleep 10
                            done
                        '''
                    }
                }
            }
        }

        stage('🔧 Fix Pod Permissions') {
            steps {
                container('argocd') {
                    withCredentials([usernamePassword(credentialsId: env.ARGOCD_CREDS, usernameVariable: 'ARGOCD_USER', passwordVariable: 'ARGOCD_PASS')]) {
                        sh '''
                            set -e
                            echo "🔧 Ensuring permission-fix script is executable..."
                            chmod +x scripts/magento-fix-perms.sh || true

                            echo "🔎 Looking for kubectl in PATH..."
                            if command -v kubectl >/dev/null 2>&1; then
                              echo "kubectl found in PATH"
                            else
                              echo "kubectl not found. Attempting to download kubectl binary to workspace..."
                              KUBECTL_BIN="$WORKSPACE/kubectl"
                              if command -v curl >/dev/null 2>&1; then
                                curl -L -o "$KUBECTL_BIN" "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" || true
                              elif command -v wget >/dev/null 2>&1; then
                                wget -O "$KUBECTL_BIN" "https://dl.k8s.io/release/$(wget -q -O - https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" || true
                              else
                                echo "Neither curl nor wget available to download kubectl. Ensure kubectl is present in the argocd container image or modify the Jenkins pod to include kubectl."
                                exit 1
                              fi
                              chmod +x "$KUBECTL_BIN" || true
                              export PATH="$WORKSPACE:$PATH"
                              echo "kubectl downloaded to $KUBECTL_BIN and added to PATH"
                            fi

                            echo "🔧 Running permission-fix script..."
                            ./scripts/magento-fix-perms.sh -n magento2 -l "app=magento-php" -c php
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
