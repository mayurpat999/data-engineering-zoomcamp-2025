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

+-----------------+--------------------+
| pickup_location | total_amount       |
|-----------------+--------------------|
| 74              | 18686.68000000008  |
| 75              | 16797.26000000007  |
| 166             | 13029.790000000037 |
+-----------------+--------------------+

select * from taxi_zone_lookup
where "LocationID" = 74 or "LocationID" = 75 or "LocationID" = 166;

Select  z."Borough",z."Zone",t.pickup_location, t.total_amount from taxi_zone_lookup z
inner join  (SELECT   "PULocationID" as pickup_location,SUM(total_amount) AS total_amount FROM    green_tripdata
                    WHERE
                        DATE(lpep_pickup_datetime) = '2019-10-18'
                    GROUP BY
                        pickup_location
                    HAVING
                        SUM(total_amount) > 13000) t
ON  z."LocationID"= t.pickup_location;               


######

SELECT b."Zone", SUM(a.tip_amount) AS total_tip from 
			(SELECT t."LocationID",t."Zone" as pickup_zone,g.tip_amount,"DOLocationID"  FROM green_tripdata g
			JOIN taxi_zone_lookup t ON g."PULocationID" = t."LocationID"
			WHERE DATE(g.lpep_pickup_datetime) BETWEEN '2019-10-01' AND '2019-10-31'
			AND t."Zone" = 'East Harlem North'
			ORDER BY g.tip_amount DESC) a
Join taxi_zone_lookup b	on 	a."DOLocationID" = b."LocationID"
GROUP BY b."Zone"
ORDER BY total_tip DESC;

 ##Network
  docker network create pg-network

  docker run -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_green_taxi" \
  -v C:/Users/mayur/OneDrive/Documents/GitHub/data-engineering-zoomcamp-2025/01-docker-terraform/ny_green_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network=pg-network \
  --name pg-database \
  postgres:latest

  docker run -it \
  -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
  -e PGADMIN_DEFAULT_PASSWORD="root" \
  -e POSTGRES_DB="ny_green_taxi" \
  -p 8080:80 \
  --network=pg-network \
  --name pgadmin \
  dpage/pgadmin4