
services:
  postgres:
    image: postgres
    environment:
      POSTGRES_USER: airflow
      POSTGRES_PASSWORD: airflow
      POSTGRES_DB: airflow
    volumes:
      - postgres-db-volume:/var/lib/postgresql/data
volumes:
  postgres-data:


docker run -it -e  POSTGRES_USER: "root" -e  POSTGRES_PASSWORD: "root"  ^
  -e  POSTGRES_DB: "my_taxi" ^
  -v C:\Users\mayur\OneDrive\Documents\GitHub\data-engineering-zoomcamp-2025\01-docker-terraform\2_docker_sql\ny_taxi_postgres_data : /var/lib/postgresql/data ^
  -p 5432:5432 ^
 postgres:latest

 ```bash
docker run -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v C:/Users/mayur/OneDrive/Documents/GitHub/data-engineering-zoomcamp-2025/01-docker-terraform/2_docker_sql/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:latest
```

docker run -it \
  -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
  -e PGADMIN_DEFAULT_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -p 8080:80 \
  dpage/pgadmin4


  ##Network
  docker network create pg-network

  docker run -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v C:/Users/mayur/OneDrive/Documents/GitHub/data-engineering-zoomcamp-2025/01-docker-terraform/2_docker_sql/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network=pg-network \
  --name pg-database \
  postgres:latest

  docker run -it \
  -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
  -e PGADMIN_DEFAULT_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -p 8080:80 \
  --network=pg-network \
  --name pgadmin \
  dpage/pgadmin4