FROM postgres:18-alpine

ENV POSTGRES_USER=admin 
ENV POSTGRES_PASSWORD=admin
ENV POSTGRES_DB=capstone_db

COPY init.sql /docker-entrypoint-initdb.d/

EXPOSE 15432

