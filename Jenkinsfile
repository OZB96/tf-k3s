pipeline {
  agent {
     kubernetes {
    yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    stattt: testing
spec:
  containers:
  - name: workspace
    image: hashicorp/terraform
    command:
    - bash
    tty: true
"""
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
    stage("workspace") {
          steps {
          
            container ("workspace") {
                sh 'terrafrom workspace new trone'
	        sh 'terrafrom workspace select trone'
              }
	     
      
           }
      }
      stage("init") {
          steps {
          
            container ("workspace") {
                sh 'pwd'
	        sh 'ls'
                sh 'make init'
              }
	      
      
           }
      }
      stage("plan") {
          steps {
          
            container ("workspace") {
                sh 'make plan'
              }
              
          }
      }
      stage("apply") {
          steps {
          
            container ("workspace") {
               sh 'make apply'
               sh 'cat ip_address.txt'
	       sh 'cat ssh/id_rsa'
              }
              

          }
      }
  }
}
