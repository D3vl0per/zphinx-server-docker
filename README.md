# Dockerized alpine based zphinx-zerver 
https://github.com/stef/zphinx-zerver


## Setup
1. Download the docker-compose.yml
2. Generate long-term keys with `docker-compose up`
3. Stop the stack with `docker-compose down`
4. Add your SSL key inside the keys folder and adjust the sphinx.cfg accordingly
5. Remove the command line and the first volume definition (./keys/:/tmp/keys/:rw) from the docker-compose.yml 
6. Remove the comment of the second volume definition (./keys/:/etc/ssl/sphinx/:ro)
7. Start the container with `docker-compose up -d`


## Local Development
1. Generate own private key: `openssl ecparam -genkey -out server.pem -name secp384r1`
2. Generate cert: `openssl req -new -nodes -x509 -sha256 -key server.pem -out certs.pem -days 365 -subj '/CN=localhost'`
3. docker-compose -f build-docker-compose.yml build

## Images
Docker registry: `d3vm/zphinx-zerver-docker:zphinx-<upstream-repo-git-commit>`   
GitHub registry: `ghcr.io/d3vl0per/zphinx-zerver-docker/zphinx:<upstream-repo-git-commit>`

