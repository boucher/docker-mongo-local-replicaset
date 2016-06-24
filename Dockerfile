FROM mongo:3.2

RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/*

VOLUME /data/db1 /data/db2 /data/db3
EXPOSE 27001 27002 27003

COPY setup.sh .

CMD ./setup.sh
