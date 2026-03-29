pipeline {
    agent any

    environment {
        DOCKERHUB_REPO = "vickyneduncheziyan/trendstore"
        IMAGE_TAG      = "build-${BUILD_NUMBER}"
        KUBECONFIG     = "/var/lib/jenkins/.kube/config"
    }

    triggers {
        // Auto-trigger on every GitHub push via webhook
        githubPush()
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Cloning repository..."
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/vickyneduncheziyan/trendstore.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${DOCKERHUB_REPO}:${IMAGE_TAG}"
                sh """
                    docker build -t ${DOCKERHUB_REPO}:${IMAGE_TAG} .
                    docker tag  ${DOCKERHUB_REPO}:${IMAGE_TAG} ${DOCKERHUB_REPO}:latest
                """
            }
        }

        stage('Push to DockerHub') {
            steps {
                echo "Pushing image to DockerHub..."
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKERHUB_REPO}:${IMAGE_TAG}
                        docker push ${DOCKERHUB_REPO}:latest
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                echo "Deploying to EKS cluster..."
                sh """
                    # Update deployment image to the newly built tag
                    kubectl set image deployment/trendstore-deployment \
                        trendstore=${DOCKERHUB_REPO}:${IMAGE_TAG} \
                        --kubeconfig=${KUBECONFIG}

                    # Apply any manifest changes (deployment + service)
                    kubectl apply -f deployment.yaml --kubeconfig=${KUBECONFIG}
                    kubectl apply -f service.yaml    --kubeconfig=${KUBECONFIG}

                    # Wait until rollout completes
                    kubectl rollout status deployment/trendstore-deployment \
                        --timeout=120s \
                        --kubeconfig=${KUBECONFIG}
                """
            }
        }

        stage('Get LoadBalancer URL') {
            steps {
                echo "Fetching LoadBalancer external URL..."
                sh """
                    sleep 20
                    kubectl get svc trendstore-service \
                        --kubeconfig=${KUBECONFIG} \
                        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline SUCCESS — trendstore deployed!"
        }
        failure {
            echo "Pipeline FAILED — check logs above."
        }
        always {
            // Clean up local docker images to save disk space
            sh "docker rmi ${DOCKERHUB_REPO}:${IMAGE_TAG} || true"
            sh "docker rmi ${DOCKERHUB_REPO}:latest        || true"
        }
    }
}
