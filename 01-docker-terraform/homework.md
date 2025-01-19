Question 1. Understanding docker first run
Run docker with the python:3.12.8 image in an interactive mode, use the entrypoint bash.

What's the version of pip in the image?

24.3.1
24.2.1
23.3.1
23.2.1

docker run -it --entrypoint:bash python:3.12.8



 ```bash
docker run -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_green_taxi" \
  -v C:/Users/mayur/OneDrive/Documents/GitHub/data-engineering-zoomcamp-2025/01-docker-terraform/ny_green_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:latest
```

 docker-compose up -d

 docker-compose down


SELECT DATE(lpep_pickup_datetime) AS pick_up_day, MAX(trip_distance) AS longest_trip_distance FROM green_tripdata WHERE lpep_pickup_datetime BETWEEN '2019-10-01' AND '2019-11-01' GROUP BY pick_up_day ORDER BY longest_trip_distance DESC LIMIT 1; 



SELECT PULocationID, SUM(total_amount) AS total_amount FROM green_tripdata WHERE DATE(lpep_pickup_datetime) = '2019-10-18' GROUP BY PULocationID HAVING SUM(total_amount) > 13000;


SELECT
    PULocationID,
    SUM(total_amount) AS total_amount
FROM
    green_tripdata
WHERE
    DATE(lpep_pickup_datetime) = '2019-10-18'
GROUP BY
    PULocationID
HAVING
    SUM(total_amount) > 13000;

