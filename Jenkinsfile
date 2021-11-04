pipeline{
    agent any
    environment {
        PATH="/usr/local/bin/:${env.PATH}"
        CFN_KEYPAIR="deneme"
        AWS_REGION = "us-east-1"
        FQDN = "clarus.mehmetafsar.net"
        DOMAIN_NAME = "mehmetafsar.net"
        GIT_FOLDER = sh(script:'echo ${GIT_URL} | sed "s/.*\\///;s/.git$//"', returnStdout:true).trim()
    }
    stages{
        stage('Setup terraform binaries') {
            steps {
              script {

                println "Setup teraform binaries..."
                sh """
                  sudo yum install -y yum-utils
                  sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
                  sudo yum -y install terraform
                """
              }
            }
        } 

        stage('get-keypair'){
            agent any
            steps{
                sh '''
                    if [ -f "${CFN_KEYPAIR}.pem" ]
                    then 
                        echo "file exists..."
                    else
                        aws ec2 create-key-pair \
                          --region ${AWS_REGION} \
                          --key-name ${CFN_KEYPAIR} \
                          --query KeyMaterial \
                          --output text > ${CFN_KEYPAIR}.pem

                        chmod 400 ${CFN_KEYPAIR}.pem

                        ssh-keygen -y -f ${CFN_KEYPAIR}.pem >> the_doctor_public.pem
                        mkdir -p ${JENKINS_HOME}/.ssh
                        cp -f ${CFN_KEYPAIR}.pem ${JENKINS_HOME}/.ssh
                        chown jenkins:jenkins ${JENKINS_HOME}/.ssh/${CFN_KEYPAIR}.pem
                    fi
                '''                
            }
        }

        stage('Aws-Certificate-Manager'){
            agent any
            steps{
                withAWS(credentials: 'mycredentials', region: 'us-east-1') {

                    sh '''
                        Acm=$(aws acm list-certificates --query CertificateSummaryList[].[CertificateArn,DomainName] --output text | grep $FQDN) || true
                        if [ "$Acm" == '' ]
                        then
                            aws acm request-certificate --domain-name $FQDN --validation-method DNS --query CertificateArn --region ${AWS_REGION}
                        
                        fi
                    '''
                        
                }                  
            }
        }

        stage('ssl-tls-record-validate'){
            agent any
            steps{
                withAWS(credentials: 'mycredentials', region: 'us-east-1') {
                    script {
                        env.ZONE_ID = sh(script:"aws route53 list-hosted-zones-by-name --dns-name $DOMAIN_NAME --query HostedZones[].Id --output text | cut -d/ -f3", returnStdout:true).trim()
                        env.SSL_CERT_ARN = sh(script:"aws acm list-certificates --query CertificateSummaryList[].[CertificateArn,DomainName]   --output text | grep $FQDN | cut -f1", returnStdout:true).trim()
                        env.SSL_CERT_NAME = sh(script:"aws acm describe-certificate --certificate-arn $SSL_CERT_ARN --query Certificate.DomainValidationOptions --output text | tail -n 1 | cut -f2", returnStdout:true).trim()
                        env.SSL_CERT_VALUE = sh(script:"aws acm describe-certificate --certificate-arn $SSL_CERT_ARN --query Certificate.DomainValidationOptions --output text | tail -n 1 | cut -f4", returnStdout:true).trim()   
                    }

                    sh "sed -i 's|{{SSL_CERT_NAME}}|$SSL_CERT_NAME|g' deletecertificate.json"
                    sh "sed -i 's|{{SSL_CERT_VALUE}}|$SSL_CERT_VALUE|g' deletecertificate.json"

                    sh '''
                        SSLRecordSet=$(aws route53 list-resource-record-sets   --hosted-zone-id $ZONE_ID   --query ResourceRecordSets[] | grep -i $SSL_CERT_VALUE) || true
                        if [ "$SSLRecordSet" != '' ]
                        then
                            aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file://deletecertificate.json
                        
                        fi
                    '''

                    sh "sed -i 's|{{SSL_CERT_NAME}}|$SSL_CERT_NAME|g' certificate.json"
                    sh "sed -i 's|{{SSL_CERT_VALUE}}|$SSL_CERT_VALUE|g' certificate.json"
                    sh "aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file://certificate.json"
                                 
                }                  
            }
        }

        stage('create infrastructure with terraform'){
            agent any
            steps{
                withAWS(credentials: 'mycredentials', region: 'us-east-1') {
                    sh "sed -i 's|{{key}}|${CFN_KEYPAIR}|g' variable.tf"
                    sh "sed -i 's|{{carn}}|$SSL_CERT_ARN|g' main.tf"
                    sh "terraform init" 
                    sh "terraform apply -input=false -auto-approve"
                }    
            }
        }

        stage('Control the nodejs instance') {
            steps {
                echo 'Control the  nodejs instance'
            script {
                while(true) {
                        
                        echo "NOdejs is not UP and running yet. Will try to reach again after 10 seconds..."
                        sleep(5)

                        ip = sh(script:"aws elbv2 describe-load-balancers --query LoadBalancers[].DNSName | cut -d '\"' -f 2 | tail -n 2 | cut -d ']' -f 2", returnStdout:true).trim()

                        if (ip.length() >= 7) {
                            echo "Nodejs Public Ip Address Found: $ip"
                            env.NODEJS_INSTANCE_PUBLIC_DNS = "$ip"
                            break
                        }
                    }
                }
            }
        }

        stage('Control the  postgresql instance') {
            steps {
                echo 'Control the  postgresql instance'
            script {
                while(true) {
                        
                        echo "Postgresql is not UP and running yet. Will try to reach again after 10 seconds..."
                        sleep(5)

                        ip = sh(script:'aws ec2 describe-instances --region ${AWS_REGION} --filters Name=tag-value,Values=ansible_postgresql  --query Reservations[*].Instances[*].[PrivateDnsName] --output text | sed "s/\\s*None\\s*//g"', returnStdout:true).trim()

                        if (ip.length() >= 7) {
                            echo "Postgresql Private Ip Address Found: $ip"
                            env.POSTGRESQL_INSTANCE_PRİVATE_DNS = "$ip"
                            sleep(5)
                            break
                        }
                    }
                while(true) {
                        ip = sh(script:'aws ec2 describe-instances --region ${AWS_REGION} --filters Name=tag-value,Values=ansible_postgresql  --query Reservations[*].Instances[*].[PublicDnsName] --output text | sed "s/\\s*None\\s*//g"', returnStdout:true).trim()
                        try{
                            sh 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${JENKINS_HOME}/.ssh/${CFN_KEYPAIR}.pem ec2-user@\"$ip" hostname'
                            echo "Postgresql is reachable with SSH."
                            break
                        }
                        catch(Exception){
                            echo "Could not connect to Postgresql with SSH, I will try again in 5 seconds"
                            sleep(5)
                        }
                    }
                }
            }
        }
  
        stage('Setting up  configuration with ansible') {
            steps {
                    echo "Setting up  configuration with ansible"
                    sh "sed -i 's|{{key_pair}}|${CFN_KEYPAIR}.pem|g' ansible.cfg"
                    sh "sed -i 's|{{nodejs_dns_name}}|$NODEJS_INSTANCE_PUBLIC_DNS|g' todo-app-pern/client/.env"
                    sh "sed -i 's|{{postgresql_internal_private_dns}}|$POSTGRESQL_INSTANCE_PRİVATE_DNS|g' todo-app-pern/server/.env"
                    sh 'ansible-playbook --extra-vars "workspace=${WORKSPACE}" docker_project.yml'
            }
        }

        stage('dns-record-control'){
            agent any
            steps{
                withAWS(credentials: 'mycredentials', region: 'us-east-1') {
                    script {
                        
                        env.ZONE_ID = sh(script:"aws route53 list-hosted-zones-by-name --dns-name $DOMAIN_NAME --query HostedZones[].Id --output text | cut -d/ -f3", returnStdout:true).trim()
                        env.ELB_DNS = sh(script:"aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID --query \"ResourceRecordSets[?Name == '$FQDN.']\" --output text | tail -n 1 | cut -f2", returnStdout:true).trim()  
                    }
                    sh "sed -i 's|{{DNS}}|$ELB_DNS|g' deleterecord.json"
                    sh "sed -i 's|{{FQDN}}|$FQDN|g' deleterecord.json"
                    sh '''
                        RecordSet=$(aws route53 list-resource-record-sets   --hosted-zone-id $ZONE_ID   --query \"ResourceRecordSets[?Name == '$FQDN.']\" --output text | tail -n 1 | cut -f2) || true
                        if [ "$RecordSet" != '' ]
                        then
                            aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file://deleterecord.json
                        
                        fi
                    '''
                    
                }                  
            }
        }

        stage('dns-record'){
            agent any
            steps{
                withAWS(credentials: 'mycredentials', region: 'us-east-1') {
                    script {
                        env.ELB_DNS = sh(script:"aws elbv2 describe-load-balancers --query LoadBalancers[].DNSName | cut -d '\"' -f 2 | tail -n 2 | cut -d ']' -f 2", returnStdout:true).trim()
                        env.ZONE_ID = sh(script:"aws route53 list-hosted-zones-by-name --dns-name $DOMAIN_NAME --query HostedZones[].Id --output text | cut -d/ -f3", returnStdout:true).trim()   
                    }
                    sh "sed -i 's|{{DNS}}|dualstack.$ELB_DNS|g' dnsrecord.json"
                    sh "sed -i 's|{{FQDN}}|$FQDN|g' dnsrecord.json"
                    sh "aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file://dnsrecord.json"
                    
                }                  
            }
        }

    }
    post {
        success {
            echo "You are Greattt...You can visit https://$FQDN"
        }
    }
}

