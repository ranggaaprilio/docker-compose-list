# Jenkins + Nginx Docker Compose Setup

This project provides a complete CI/CD setup using Jenkins with Nginx as a reverse proxy, containerized with Docker Compose.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Client      │───▶│      Nginx      │───▶│     Jenkins     │
│   (Browser)     │    │ (Reverse Proxy) │    │   (CI/CD)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                Port 80                Port 8080
```

## 📋 Components

### 1. Jenkins Container
- **Base Image**: Custom Jenkins with JDK 21 + Node.js 20
- **Ports**: 
  - `8080`: Jenkins Web UI
  - `50000`: Jenkins Agents communication
- **Features**:
  - Docker-in-Docker capability
  - Node.js and npm pre-installed
  - Persistent data storage
  - Root access for Docker operations

### 2. Nginx Container
- **Base Image**: nginx:latest
- **Port**: `80` (HTTP)
- **Role**: Reverse proxy and static file server
- **Features**:
  - SSL termination ready
  - Load balancing capable
  - Custom configuration support

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Ports 80 and 8080 available
- Minimum 2GB RAM recommended

### 1. Clone and Setup
```bash
git clone <your-repo>
cd nginx-jenkins
```

### 2. Start the Services
```bash
docker-compose up -d
```

### 3. Access Jenkins
1. Open http://localhost:8080 (or through nginx at http://localhost)
2. Get the initial admin password:
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```
3. Complete the Jenkins setup wizard

## 🔧 Configuration

### Directory Structure
```
nginx-jenkins/
├── docker-compose.yaml      # Main compose file
├── Dockerfile.jenkins       # Custom Jenkins image
├── jenkins_data/           # Jenkins persistent data
├── nginx/
│   ├── nginx.conf          # Main nginx config
│   ├── conf.d/             # Site-specific configs
│   ├── html/               # Static files
│   └── logs/               # Nginx logs
└── readme.md
```

### Network Configuration
Both containers are connected to the `ci_network` bridge network, allowing them to communicate using container names.

## 🌐 Network Integration with Other Applications

### Connecting Jenkins to External Applications

To connect Jenkins to other applications in your infrastructure, you have several options:

#### Option 1: Use the Same Network (Recommended)
Add your applications to the same `ci_network`:

```yaml
# In your application's docker-compose.yml
services:
  your-app:
    # ... your app configuration
    networks:
      - ci_network

networks:
  ci_network:
    external: true  # Use the existing network
```

#### Option 2: Create a Shared External Network
```bash
# Create a shared network
docker network create shared_network

# Update docker-compose.yaml to use external network
networks:
  ci_network:
    external: true
    name: shared_network
```

#### Option 3: Host Network Access
Jenkins can access applications running on the host using:
- `host.docker.internal` (already configured in nginx)
- Host IP address
- Exposed ports on localhost

### Jenkins Pipeline Examples

#### Deploying to Docker Containers
```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t myapp:latest .'
            }
        }
        stage('Deploy') {
            steps {
                sh '''
                docker-compose -f /path/to/your/app/docker-compose.yml down
                docker-compose -f /path/to/your/app/docker-compose.yml up -d
                '''
            }
        }
    }
}
```

#### Multi-Container Application Deployment
```groovy
pipeline {
    agent any
    stages {
        stage('Deploy Stack') {
            steps {
                sh '''
                # Stop existing services
                docker-compose -p mystack down
                
                # Deploy new version
                docker-compose -p mystack up -d
                
                # Wait for health check
                docker-compose -p mystack ps
                '''
            }
        }
    }
}
```

## 🔒 Security Considerations

### Jenkins Security
- Change default admin password immediately
- Enable security realm and authorization
- Use Jenkins credentials store for sensitive data
- Regular updates and security patches

### Nginx Security
- Add SSL/TLS certificates for production
- Configure rate limiting
- Enable security headers
- Restrict access to admin interfaces

### Network Security
```yaml
# Example secure network configuration
networks:
  ci_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## 📊 Monitoring and Logging

### View Logs
```bash
# Jenkins logs
docker logs jenkins -f

# Nginx logs
docker logs my-nginx -f

# All services
docker-compose logs -f
```

### Health Checks
```bash
# Check container status
docker-compose ps

# Check network connectivity
docker exec jenkins ping my-nginx
```

## 🛠️ Customization

### Adding Jenkins Plugins
1. Access Jenkins UI → Manage Jenkins → Plugins
2. Or add to `jenkins_data/plugins.txt` and rebuild

### Nginx Configuration
- Modify `nginx/nginx.conf` for global settings
- Add site configs in `nginx/conf.d/`
- Restart nginx: `docker-compose restart nginx`

### Environment Variables
```yaml
# Add to docker-compose.yaml
services:
  jenkins:
    environment:
      - JENKINS_JAVA_OPTIONS="-Xmx2048m"
      - JENKINS_OPTS="--sessionTimeout=1440"
```

## 🚨 Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   sudo chown -R 1000:1000 jenkins_data/
   ```

2. **Port Already in Use**
   ```bash
   # Check what's using the port
   lsof -i :8080
   # Kill the process or change ports in docker-compose.yaml
   ```

3. **Network Connectivity Issues**
   ```bash
   # Check network
   docker network ls
   docker network inspect nginx-jenkins_ci_network
   ```

4. **Jenkins Container Won't Start**
   ```bash
   # Check logs
   docker logs jenkins
   # Verify Docker socket permissions
   ls -la /var/run/docker.sock
   ```

## 🔄 Backup and Recovery

### Backup Jenkins Data
```bash
# Create backup
tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz jenkins_data/

# Automated backup script
cat > backup-jenkins.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/path/to/backups"
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf "$BACKUP_DIR/jenkins-backup-$DATE.tar.gz" jenkins_data/
find "$BACKUP_DIR" -name "jenkins-backup-*.tar.gz" -mtime +30 -delete
EOF
```

### Restore Jenkins Data
```bash
docker-compose down
tar -xzf jenkins-backup-YYYYMMDD.tar.gz
docker-compose up -d
```

## 📈 Scaling and Performance

### Resource Limits
```yaml
services:
  jenkins:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.5'
        reservations:
          memory: 1G
          cpus: '0.5'
```

### Multiple Jenkins Agents
```yaml
services:
  jenkins-agent:
    image: jenkins/ssh-agent
    environment:
      - JENKINS_AGENT_SSH_PUBKEY=${JENKINS_AGENT_SSH_PUBKEY}
    networks:
      - ci_network
```

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: This setup is configured for development/testing. For production deployment, ensure proper security measures, SSL certificates, and resource limits are in place.