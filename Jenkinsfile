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
        DB_IMAGE_REPO = "hadil01/pipe-db"
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
                        docker build -t $NGINX_IMAGE_REPO:$IMAGE_TAG -f docker/nginx/Dockerfile.nginx .
                        docker push $NGINX_IMAGE_REPO:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('🐬 Build & Push DB Image') {
            steps {
                container('docker') {
                    sh '''
                        set -e
                        docker build -t $DB_IMAGE_REPO:$IMAGE_TAG -f docker/db/Dockerfile.db .
                        docker push $DB_IMAGE_REPO:$IMAGE_TAG
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
                            argocd login $ARGOCD_SERVER --username $ARGOCD_USER --password $ARGOCD_PASS --insecure
                            argocd app set $ARGOCD_APP_NAME \
                                --helm-set php.image.tag=$IMAGE_TAG \
                                --helm-set nginx.image.tag=$IMAGE_TAG \
                                --helm-set db.image.tag=$IMAGE_TAG
                            n=0
                            until [ "$n" -ge 5 ]
                            do
                              if argocd app sync $ARGOCD_APP_NAME --async --prune --force; then
                                break
                              fi
                              n=$((n+1))
                              sleep 10
                            done
                        '''
                    }
                }
            }
        }

        stage('🔄 Update MicroK8s Database') {
            steps {
                container('argocd') {
                    sh '''
                        POD=$(kubectl get pods -n magento2 -l app=magento-db -o jsonpath='{.items[0].metadata.name}')
                        kubectl cp docker/db/init.sql magento2/$POD:/tmp/init.sql
                        kubectl exec -n magento2 -it $POD -- bash -lc "mysql -u pipe -p'1234' pipe < /tmp/init.sql"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
