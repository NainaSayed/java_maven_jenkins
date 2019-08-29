pipeline 
{
    agent any
    stages
    {
        stage('SCM checkout') 
        {
            steps 
            {
                echo "Checking out from Source Repository"
                //git url: 'https://github.com/pramodk05/java_maven_jenkins'
                git url: 'https://github.com/NainaSayed/java_maven_jenkins.git'
            }
        
        }
        stage('Compile Stage') 
        {
            steps
            {
                echo "Compiling Source"
                withMaven(maven: 'Maven_3.6') 
                {
                // some block
                sh 'mvn compile'
                }
                
            }
        
        }
        stage('Test Stage') 
        {
            steps 
            {
                echo "Compiling Source"
                withMaven(maven: 'Maven_3.6') 
                {
                // some block
                sh 'mvn test'
                }
                
            }
        
        }
        

        stage('Package Stage') 
        {
            steps 
            {
                echo "Compiling Source"
                withMaven(maven: 'Maven_3.6') 
                {
                // some block
                sh 'mvn package'
                }
                
            }
        
        }
        stage ('Terraform Setup') 
        {
            steps 
            {
                script 
                {
                    def tfHome = tool name: 'Terraform', type: 'org.jenkinsci.plugins.terraform.TerraformInstallation'
                    
                }              
            sh 'terraform --version'                    
                
            }
        }
        stage ('Terraform Init and Plan') 
        {
            steps 
            {
                sh 'terraform init'
                sh 'terraform plan'
            }
        }

        stage ('Terraform Apply') 
        {
            steps 
            {
                sh 'terraform apply --auto-approve'               
            }
        }




        /*      
        
        stage('Deploy Stage') 
        {
            steps 
            {
                echo "Deploying Source"
                deploy adapters: [tomcat9(credentialsId: '19a33b97-43c0-4da2-9ef0-c5e7e3e0a5ec', path: '', url: 'http://13.58.115.16:9090/')], contextPath: 'mvn-hello-world', war: 'target/*.war'
                
            }
        
        }
        
        */
        
    }
    
}
