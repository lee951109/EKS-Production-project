pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command: ['sleep']
    args: ['infinity']
    volumeMounts:
    - name: kaniko-secret
      mountPath: /kaniko/.docker
  volumes:
  - name: kaniko-secret
    emptyDir: {}
"""
        }
    }

    environment {
        AWS_ACCOUNT_ID = "808985145578"
        AWS_REGION     = "ap-northeast-2"
        ECR_REPO_NAME  = "python-app" 
        ECR_URL        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG      = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push to ECR') {
            steps {
                container('kaniko') {
                    // Dockerfile기반으로 빌드 및 푸시를 수행.
                    sh """
                    /kaniko/executor --context ${WORKSPACE}/status-checker-app --dockerfile ${WORKSPACE}/status-checker-app/Dockerfile --destination ${ECR_URL}/${ECR_REPO_NAME}:${IMAGE_TAG} --destination ${ECR_URL}/${ECR_REPO_NAME}:latest
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Successfully pushed ${ECR_REPO_NAME}:${IMAGE_TAG} to ECR"
        }
    }
}