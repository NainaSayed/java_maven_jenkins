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
                git url: 'https://github.com/pramodk05/java_maven_jenkins'
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
        
        stage('Deploy Stage') 
        {
            steps 
            {
                echo "Deploying Source"
                deploy adapters: [tomcat9(credentialsId: '19a33b97-43c0-4da2-9ef0-c5e7e3e0a5ec', path: '', url: 'http://13.58.115.16:9090/')], contextPath: 'mvn-hello-world', war: 'target/*.war'
                
            }
        
        }
        
    }
    
}
