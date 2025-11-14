pipeline {
  agent any
  environment {
    APP_NAME      = "studentmarkservice"
    APP_NAMESPACE = "${APP_NAME}-ns"
    IMAGE_NAME    = "${APP_NAME}-image"
    IMAGE_TAG     = "${BUILD_NUMBER}${BUILD_NUMBER}"
    APP_PORT      = "8100"
    NODE_PORT     = "30081"
    REPLICA_COUNT = "2"
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'master', url: 'https://github.com/Thasneemshaik09/studentmarkservice.git'
      }
    }

    stage('Build') {
      steps {x
        script {
          def gitCommit = env.GIT_COMMIT ?: shReturnStdout('git rev-parse --short HEAD') ?: 'unknown'
          // For Windows agents, adjust: use bat instead of shReturnStdout if needed.
          // Build with label to avoid relying on git being available inside Docker builder
          bat "docker build --label org.opencontainers.image.revision=${gitCommit} -t ${IMAGE_NAME}:${IMAGE_TAG} -f Dockerfile ."
        }
      }
    }
    stage('Run Container') {
                steps {
                    script {
                        // Run docker container instance
                        bat "docker run -d --name ${APP_NAME} -p 8100:8100 ${IMAGE_NAME}:${IMAGE_TAG}"
                    }
                }
            }
    stage('K8s Container Deployment') {
      steps {
        // Use the kubeconfig secret file saved in Jenkins credentials
        withCredentials([file(credentialsId: 'kubeconfig-studentmarkservice', variable: 'KUBECONFIG_FILE')]) {
          script {
            // Render templates using Groovy (no envsubst)
            def renderTemplate = { srcPath, destPath ->
              def tpl = readFile(srcPath)
              tpl = tpl.replace('${APP_NAME}', env.APP_NAME)
                       .replace('${APP_NAMESPACE}', env.APP_NAMESPACE)
                       .replace('${IMAGE_NAME}', env.IMAGE_NAME)
                       .replace('${IMAGE_TAG}', env.IMAGE_TAG)
                       .replace('${APP_PORT}', env.APP_PORT)
                       .replace('${NODE_PORT}', env.NODE_PORT)
                       .replace('${REPLICA_COUNT}', env.REPLICA_COUNT)
              writeFile file: destPath, text: tpl
              echo "Rendered ${destPath}"
            }

            renderTemplate('k8s/namespace-template.yaml', 'k8s/namespace.yaml')
            renderTemplate('k8s/deployment-template.yaml', 'k8s/deployment.yaml')
            renderTemplate('k8s/service-template.yaml', 'k8s/service.yaml')

            // Apply manifests explicitly using the temporary kubeconfig file
            // Note: on Windows agent 'kubectl' must be in PATH
            bat "kubectl --kubeconfig=\"${KUBECONFIG_FILE}\" apply -f k8s/namespace.yaml --validate=false"
            bat "kubectl --kubeconfig=\"${KUBECONFIG_FILE}\" apply -f k8s/deployment.yaml --validate=false"
            bat "kubectl --kubeconfig=\"${KUBECONFIG_FILE}\" apply -f k8s/service.yaml --validate=false"
          }
        }
      }
    }
  }

  post {
    success { echo "✅ Checkout, Build, Dockerize & Deploy completed successfully!" }
    failure { echo "❌ Build failed!" }
  }
}

// helper: try to get git commit in a cross-platform safe way
def shReturnStdout(String cmd) {
  try {
    return sh(script: cmd, returnStdout: true).trim()
  } catch (err) {
    // On Windows, sh isn't available — fall through to attempt reading GIT_COMMIT env
    return null
  }
}