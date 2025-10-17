pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-northeast-2'
        ECR_REPO = 'dodam-ecr'
        EC2_NAME_TAG = 'dodam-app-ec2'
        DOCKER_IMAGE = ''
        IMAGE_TAG = ''
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Git Checkout"
                checkout scm
            }
        }

        stage('Get AWS Account ID') {
            steps {
                script {
                    env.AWS_ACCOUNT_ID = sh(
                        script: "aws sts get-caller-identity --query Account --output text",
                        returnStdout: true
                    ).trim()
                    echo "AWS Account ID: ${env.AWS_ACCOUNT_ID}"
                }
            }
        }

        stage('Determine Next Image Tag') {
            steps {
                script {
                    def existingTags = sh(
                        script: "aws ecr list-images --region ${AWS_REGION} --repository-name ${ECR_REPO} --query 'imageIds[*].imageTag' --output text",
                        returnStdout: true
                    ).trim().split("\\s+")

                    def latestVersion = 'v1.0.0'

                    if (existingTags) {
                        def versions = existingTags.findAll { it ==~ /v\\d+\\.\\d+\\.\\d+/ }
                        if (versions) {
                            versions.sort { a, b ->
                                def aParts = a.replace('v','').split('\\.').collect { it.toInteger() }
                                def bParts = b.replace('v','').split('\\.').collect { it.toInteger() }
                                for (int i=0; i<3; i++) {
                                    def diff = aParts[i] - bParts[i]
                                    if (diff != 0) return diff
                                }
                                return 0
                            }
                            def last = versions[-1].replace('v','').split('\\.').collect { it.toInteger() }
                            last[2] += 1
                            latestVersion = "v${last.join('.')}"
                        }
                    }

                    env.IMAGE_TAG = latestVersion
                    env.DOCKER_IMAGE = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${env.IMAGE_TAG}"
                    echo "Next Docker Image Tag: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Build Spring Boot') {
            steps {
                echo "Building Spring Boot App with Gradle"
                sh './gradlew clean build -x test'
            }
        }

        stage('Docker Build & Push') {
            steps {
                echo "Building and Pushing Docker Image"
                sh """
                    docker build -t ${DOCKER_IMAGE} .
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    docker push ${DOCKER_IMAGE}
                """
            }
        }

        stage('Deploy to EC2 via SSM') {
            steps {
                script {
                    echo "Deploying Docker image to all EC2 instances with tag Name=${EC2_NAME_TAG}"
                    sh """
                    aws ssm send-command \
                        --targets "Key=tag:Name,Values=${EC2_NAME_TAG}" \
                        --document-name "AWS-RunShellScript" \
                        --comment "Deploy latest Docker image" \
                        --parameters 'commands=[
                            "docker pull ${DOCKER_IMAGE}",
                            "docker stop dodam-app || true",
                            "docker rm dodam-app || true",
                            "docker run -d -p 8080:8080 --name dodam-app ${DOCKER_IMAGE}"
                        ]' \
                        --region ${AWS_REGION}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Build, Push, and Deploy completed: ${DOCKER_IMAGE}"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
