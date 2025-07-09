# CI/CD Integration Examples

This guide provides comprehensive examples for integrating the project with various CI/CD platforms and tools.

## GitHub Actions

### Basic CI Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        go-version: [1.20, 1.21]
        
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: ${{ matrix.go-version }}
    
    - name: Cache Go modules
      uses: actions/cache@v3
      with:
        path: ~/go/pkg/mod
        key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
        restore-keys: |
          ${{ runner.os }}-go-
    
    - name: Install dependencies
      run: go mod download
    
    - name: Run tests
      run: go test -v ./...
    
    - name: Run linter
      uses: golangci/golangci-lint-action@v3
      with:
        version: latest
    
    - name: Build
      run: go build -v ./...
    
    - name: Upload coverage reports
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.out
```

### Release and Deployment Workflow

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.21'
    
    - name: Build binaries
      run: |
        GOOS=linux GOARCH=amd64 go build -o dist/your-project-linux-amd64
        GOOS=darwin GOARCH=amd64 go build -o dist/your-project-darwin-amd64
        GOOS=windows GOARCH=amd64 go build -o dist/your-project-windows-amd64.exe
    
    - name: Create Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        draft: false
        prerelease: false
    
    - name: Upload Release Assets
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ steps.create_release.outputs.upload_url }}
        asset_path: ./dist/your-project-linux-amd64
        asset_name: your-project-linux-amd64
        asset_content_type: application/octet-stream

  docker:
    runs-on: ubuntu-latest
    needs: build
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Log in to GitHub Container Registry
      uses: docker/login-action@v3
      with:
        registry: ghcr.io
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: |
          ghcr.io/${{ github.repository }}:latest
          ghcr.io/${{ github.repository }}:${{ github.ref_name }}
        platforms: linux/amd64,linux/arm64
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy:
    runs-on: ubuntu-latest
    needs: [build, docker]
    environment: production
    
    steps:
    - name: Deploy to production
      run: |
        echo "Deploying to production..."
        # Add your deployment commands here
```

### Multi-platform Build

```yaml
# .github/workflows/multi-platform.yml
name: Multi-platform Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macOS-latest]
        go-version: [1.20, 1.21]
        
    runs-on: ${{ matrix.os }}
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: ${{ matrix.go-version }}
    
    - name: Test (Unix)
      if: matrix.os != 'windows-latest'
      run: go test -v ./...
    
    - name: Test (Windows)
      if: matrix.os == 'windows-latest'
      run: go test -v ./...
      shell: cmd
    
    - name: Build
      run: go build -v ./...
```

## GitLab CI/CD

### GitLab CI Configuration

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  GO_VERSION: "1.21"
  DOCKER_DRIVER: overlay2

before_script:
  - apt-get update -qq && apt-get install -y -qq git ca-certificates
  - which go || (wget -O- https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xzf -)
  - export PATH=$PATH:/usr/local/go/bin
  - go version

test:
  stage: test
  image: golang:${GO_VERSION}
  script:
    - go mod download
    - go test -v ./...
    - go vet ./...
  coverage: '/coverage: \d+.\d+% of statements/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml

build:
  stage: build
  image: golang:${GO_VERSION}
  script:
    - go build -o your-project
  artifacts:
    paths:
      - your-project
    expire_in: 1 hour

docker-build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main

deploy-staging:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache curl
  script:
    - echo "Deploying to staging..."
    - curl -X POST "$STAGING_WEBHOOK_URL" -H "Authorization: Bearer $STAGING_TOKEN"
  environment:
    name: staging
    url: https://staging.yourproject.com
  only:
    - main

deploy-production:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache curl
  script:
    - echo "Deploying to production..."
    - curl -X POST "$PRODUCTION_WEBHOOK_URL" -H "Authorization: Bearer $PRODUCTION_TOKEN"
  environment:
    name: production
    url: https://yourproject.com
  when: manual
  only:
    - tags
```

### GitLab CI with Kubernetes

```yaml
# .gitlab-ci.yml
deploy-k8s:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl config use-context $KUBE_CONTEXT
    - envsubst < k8s/deployment.yaml | kubectl apply -f -
    - kubectl rollout status deployment/your-project
  environment:
    name: production
    url: https://yourproject.com
  only:
    - main
```

## Jenkins

### Jenkinsfile (Declarative Pipeline)

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        GO_VERSION = '1.21'
        DOCKER_REGISTRY = 'your-registry.com'
        IMAGE_NAME = 'your-project'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup') {
            steps {
                sh '''
                    # Install Go
                    wget -O- https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xzf -
                    export PATH=$PATH:/usr/local/go/bin
                    go version
                '''
            }
        }
        
        stage('Dependencies') {
            steps {
                sh '''
                    export PATH=$PATH:/usr/local/go/bin
                    go mod download
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                    export PATH=$PATH:/usr/local/go/bin
                    go test -v ./...
                    go vet ./...
                '''
            }
            post {
                always {
                    publishTestResults testResultsPattern: 'test-results.xml'
                    publishCoverageResults(
                        adapters: [
                            coberturaAdapter('coverage.xml')
                        ],
                        sourceFileResolver: sourceFiles('STORE_ALL_BUILD')
                    )
                }
            }
        }
        
        stage('Build') {
            steps {
                sh '''
                    export PATH=$PATH:/usr/local/go/bin
                    go build -o your-project
                '''
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    def image = docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}")
                    image.push()
                    image.push('latest')
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    echo "Deploying to staging..."
                    # Add deployment commands here
                '''
            }
        }
        
        stage('Deploy to Production') {
            when {
                tag 'v*'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                sh '''
                    echo "Deploying to production..."
                    # Add deployment commands here
                '''
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            slackSend(
                channel: '#deployments',
                color: 'good',
                message: "Successfully deployed ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
            )
        }
        failure {
            slackSend(
                channel: '#deployments',
                color: 'danger',
                message: "Failed to deploy ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
            )
        }
    }
}
```

### Jenkins Shared Library

```groovy
// vars/buildGoProject.groovy
def call(Map config) {
    pipeline {
        agent any
        
        environment {
            GO_VERSION = config.goVersion ?: '1.21'
            PROJECT_NAME = config.projectName
        }
        
        stages {
            stage('Setup Go') {
                steps {
                    script {
                        sh '''
                            wget -O- https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xzf -
                            export PATH=$PATH:/usr/local/go/bin
                            go version
                        '''
                    }
                }
            }
            
            stage('Test') {
                steps {
                    script {
                        sh '''
                            export PATH=$PATH:/usr/local/go/bin
                            go mod download
                            go test -v ./...
                        '''
                    }
                }
            }
            
            stage('Build') {
                steps {
                    script {
                        sh '''
                            export PATH=$PATH:/usr/local/go/bin
                            go build -o ${PROJECT_NAME}
                        '''
                    }
                }
            }
        }
    }
}
```

## Azure DevOps

### Azure Pipelines YAML

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
    - develop
  tags:
    include:
    - v*

pool:
  vmImage: 'ubuntu-latest'

variables:
  goVersion: '1.21'
  projectName: 'your-project'

stages:
- stage: Test
  jobs:
  - job: test
    strategy:
      matrix:
        go120:
          goVersion: '1.20'
        go121:
          goVersion: '1.21'
    steps:
    - task: GoTool@0
      inputs:
        version: $(goVersion)
    
    - script: |
        go mod download
        go test -v ./...
      displayName: 'Run tests'
    
    - script: |
        go install github.com/axw/gocov/gocov@latest
        go install github.com/AlekSi/gocov-xml@latest
        gocov test ./... | gocov-xml > coverage.xml
      displayName: 'Generate coverage'
    
    - task: PublishCodeCoverageResults@1
      inputs:
        codeCoverageTool: 'Cobertura'
        summaryFileLocation: 'coverage.xml'

- stage: Build
  dependsOn: Test
  jobs:
  - job: build
    steps:
    - task: GoTool@0
      inputs:
        version: $(goVersion)
    
    - script: |
        go build -o $(projectName)
      displayName: 'Build binary'
    
    - task: PublishBuildArtifacts@1
      inputs:
        pathtoPublish: '$(projectName)'
        artifactName: 'binary'

- stage: Docker
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - job: docker
    steps:
    - task: Docker@2
      inputs:
        containerRegistry: 'your-registry'
        repository: '$(projectName)'
        command: 'buildAndPush'
        Dockerfile: '**/Dockerfile'
        tags: |
          $(Build.BuildId)
          latest

- stage: Deploy
  dependsOn: Docker
  condition: and(succeeded(), startsWith(variables['Build.SourceBranch'], 'refs/tags/v'))
  jobs:
  - deployment: deploy
    environment: production
    strategy:
      runOnce:
        deploy:
          steps:
          - script: |
              echo "Deploying to production..."
              # Add deployment commands here
            displayName: 'Deploy to production'
```

## CircleCI

### CircleCI Configuration

```yaml
# .circleci/config.yml
version: 2.1

orbs:
  go: circleci/go@1.9.0
  docker: circleci/docker@2.2.0

workflows:
  build-and-deploy:
    jobs:
      - test:
          filters:
            branches:
              only: /.*/
            tags:
              only: /^v.*/
      - build:
          requires:
            - test
          filters:
            branches:
              only: main
            tags:
              only: /^v.*/
      - deploy:
          requires:
            - build
          filters:
            branches:
              ignore: /.*/
            tags:
              only: /^v.*/

jobs:
  test:
    docker:
      - image: cimg/go:1.21
    steps:
      - checkout
      - go/load-cache
      - go/mod-download
      - go/save-cache
      - run:
          name: Run tests
          command: |
            go test -v ./...
            go vet ./...
      - run:
          name: Generate coverage
          command: |
            go test -race -coverprofile=coverage.out ./...
            go tool cover -html=coverage.out -o coverage.html
      - store_artifacts:
          path: coverage.html

  build:
    docker:
      - image: cimg/go:1.21
    steps:
      - checkout
      - go/load-cache
      - go/mod-download
      - run:
          name: Build binary
          command: go build -o your-project
      - persist_to_workspace:
          root: .
          paths:
            - your-project

  deploy:
    docker:
      - image: cimg/base:stable
    steps:
      - checkout
      - attach_workspace:
          at: .
      - setup_remote_docker:
          version: 20.10.14
      - docker/check
      - docker/build:
          image: your-registry/your-project
          tag: ${CIRCLE_TAG}
      - docker/push:
          image: your-registry/your-project
          tag: ${CIRCLE_TAG}
      - run:
          name: Deploy to production
          command: |
            echo "Deploying to production..."
            # Add deployment commands here
```

## Travis CI

### Travis CI Configuration

```yaml
# .travis.yml
language: go

go:
  - "1.20"
  - "1.21"

services:
  - docker

env:
  - GO111MODULE=on

cache:
  directories:
    - $GOPATH/pkg/mod

before_script:
  - go mod download

script:
  - go test -v ./...
  - go vet ./...
  - go build -o your-project

after_success:
  - bash <(curl -s https://codecov.io/bash)

deploy:
  - provider: script
    script: bash deploy.sh
    skip_cleanup: true
    on:
      branch: main
  - provider: releases
    api_key: $GITHUB_TOKEN
    file: your-project
    skip_cleanup: true
    on:
      tags: true
```

## Bitbucket Pipelines

### Bitbucket Configuration

```yaml
# bitbucket-pipelines.yml
image: golang:1.21

pipelines:
  default:
    - step:
        name: Test
        caches:
          - gomodules
        script:
          - go mod download
          - go test -v ./...
          - go vet ./...
  
  branches:
    main:
      - step:
          name: Test
          caches:
            - gomodules
          script:
            - go mod download
            - go test -v ./...
      - step:
          name: Build and Deploy
          script:
            - go build -o your-project
            - docker build -t your-registry/your-project:latest .
            - docker push your-registry/your-project:latest
          services:
            - docker
  
  tags:
    v*:
      - step:
          name: Release
          script:
            - go build -o your-project
            - docker build -t your-registry/your-project:$BITBUCKET_TAG .
            - docker push your-registry/your-project:$BITBUCKET_TAG
          services:
            - docker

definitions:
  caches:
    gomodules: $GOPATH/pkg/mod
```

## Drone CI

### Drone Configuration

```yaml
# .drone.yml
kind: pipeline
type: docker
name: default

steps:
- name: test
  image: golang:1.21
  commands:
  - go mod download
  - go test -v ./...
  - go vet ./...

- name: build
  image: golang:1.21
  commands:
  - go build -o your-project
  depends_on:
  - test

- name: docker
  image: plugins/docker
  settings:
    registry: your-registry.com
    repo: your-registry.com/your-project
    tags:
    - latest
    - ${DRONE_COMMIT_SHA}
    username:
      from_secret: docker_username
    password:
      from_secret: docker_password
  depends_on:
  - build
  when:
    branch:
    - main

- name: deploy
  image: alpine:latest
  commands:
  - apk add --no-cache curl
  - curl -X POST "$DEPLOY_WEBHOOK"
  depends_on:
  - docker
  when:
    branch:
    - main
```

## Kubernetes Deployment

### Kubernetes Manifests

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: your-project
  labels:
    app: your-project
spec:
  replicas: 3
  selector:
    matchLabels:
      app: your-project
  template:
    metadata:
      labels:
        app: your-project
    spec:
      containers:
      - name: your-project
        image: your-registry/your-project:${IMAGE_TAG}
        ports:
        - containerPort: 8080
        env:
        - name: LOG_LEVEL
          value: "info"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: your-project-service
spec:
  selector:
    app: your-project
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
```

## Helm Chart

### Helm Chart Structure

```yaml
# helm/your-project/values.yaml
replicaCount: 3

image:
  repository: your-registry/your-project
  tag: latest
  pullPolicy: Always

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: yourproject.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: your-project-tls
      hosts:
        - yourproject.com

resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

```yaml
# helm/your-project/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "your-project.fullname" . }}
  labels:
    {{- include "your-project.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "your-project.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "your-project.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /health
              port: http
          readinessProbe:
            httpGet:
              path: /ready
              port: http
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
```

## Best Practices

1. **Use specific versions**: Pin exact versions for reproducible builds
2. **Cache dependencies**: Use caching to speed up builds
3. **Parallel execution**: Run tests and builds in parallel when possible
4. **Security scanning**: Include security scans in your pipeline
5. **Automated testing**: Test on multiple platforms and versions
6. **Deployment strategies**: Use blue-green or rolling deployments
7. **Monitoring**: Add monitoring and alerting to your deployment pipeline
8. **Rollback capability**: Ensure you can quickly rollback deployments

## Next Steps

- See [Configuration Guide](../docs/configuration.md) for advanced setup
- Check [Usage Examples](../docs/usage.md) for common use cases
- Join our [Community](../docs/community.md) for support
