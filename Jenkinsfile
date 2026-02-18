pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-admin-sa
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command: ['sleep']
    args: ['infinity']
    volumeMounts:
    - name: kaniko-secret
      mountPath: /kaniko/.docker
  - name: kubectl
    image: alpine/k8s:1.29.2
    command: ['sleep']
    args: ['infinity']
  volumes:
  - name: kaniko-secret
    emptyDir: {}
"""
        }
    }

    triggers {
        githubPush() 
    }

    environment {
        AWS_ACCOUNT_ID = "808985145578"
        AWS_REGION     = "ap-northeast-2"
        ECR_REPO_NAME  = "python-app" 
        ECR_URL        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG      = "${BUILD_NUMBER}"
        FULL_IMAGE     = "${ECR_URL}/${ECR_REPO_NAME}:${IMAGE_TAG}"
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
                    // status-checker-app 폴더 내의 Dockerfile을 사용하여 빌드.
                    sh """
                    /kaniko/executor --context ${WORKSPACE}/status-checker-app --dockerfile ${WORKSPACE}/status-checker-app/Dockerfile --destination ${FULL_IMAGE} --destination ${ECR_URL}/${ECR_REPO_NAME}:latest
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                container('kubectl') {
                    // deployment.yaml의 IMAGE_PLACEHOLDER를 방금 빌드한 이미지 주소로 교체 후 배포.
                    sh """
                    sed -i "s|IMAGE_PLACEHOLDER|${FULL_IMAGE}|g" k8s-manifests/deployment.yaml
                    kubectl apply -f k8s-manifests/deployment.yaml
                    """
                }
            }
        }
    }
}