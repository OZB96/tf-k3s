pipeline {
  agent {
    docker {
      image "bryandollery/terraform-packer-aws-alpine"
      args "-u root --entrypoint=''"
    }
  }
  environment {
        CREDS = credentials('aws_secerts')
        AWS_ACCESS_KEY_ID="${CREDS_USR}"
        AWS_SECRET_ACCESS_KEY="${CREDS_PSW}"
        OWNER= "phiProject"
        TF_NAMESPACE="phi"
        PROJECT_NAME="web-server"
        AWS_PROFILE="phi-kh-labs"
  }
  stages {
      stage("init") {
          steps {
	      sh 'pwd'
	      sh 'ls'
              sh 'make init'
      
           }
      }
      stage("plan") {
          steps {
              sh 'make plan'
          }
      }
      stage("apply") {
          steps {
              sh 'make apply'
              sh 'cat ip_address.txt'
	      sh 'cat ssh/id_rsa'

          }
      }
  }
}
