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
    image: bryandollery/terraform-packer-aws-alpine
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
        TF_NAMESPACE="omar"
        PROJECT_NAME="web-server"
        AWS_PROFILE="phi-kh-labs"
  }
  stages {
    stage("init") {
            steps {
		 
	      container ("workspace") {
	
		      sh 'ls'
		      sh 'make init'
		 //   sh 'terraform workspace list'
	           // sh 'terraform workspace select trone'
	             //sh 'make down'
		    }
		      
	          }
                }
   //*           
     stage ("workspace"){
             steps {
          
               container ("workspace") {
                sh 'terraform workspace list'
	       sh 'terraform workspace select trone'
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
               sh 'cat ssh/id_rsa'
               sh 'cat ssh/id_rsa.pub'
              }
              

          }
      }//*/
  }
}

