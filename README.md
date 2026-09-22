# JaguarDocker

## Commands

| Command                                    | Description                                        |
| ------------------------------------------ | -------------------------------------------------- |
| `docker ps`                                | List running containers                            |
| `docker ps -a`                             | List all containers, including stopped             |
| `docker images`                            | List downloaded Docker images                      |
| `docker volume ls`                         | List Docker volumes                                |
| `docker network ls`                        | List Docker networks                               |
| `docker stats`                             | Show live CPU, memory, network, and I/O usage      |
| `docker info`                              | Show Docker system information                     |
| `docker version`                           | Show Docker client/server versions                 |
| `docker logs -f <container>`               | Follow container logs in real time                 |
| `docker pull <image>`                      | Download/update an image                           |
| `docker system df`                         | Show Docker disk usage                             |
| `docker compose up -d`                     | Create/start the stack in the background           |
| `docker compose down`                      | Stop and remove containers/networks                |
| `docker compose pull`                      | Pull the latest images                             |
| `docker compose top`                       | Show processes running in Compose containers       |

## Common Update Workflow
```
cd ~/docker/<stack>

docker compose pull
docker compose up -d
docker compose ps
docker compose logs -f
```
