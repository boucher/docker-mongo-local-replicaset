FROM mongo:3.2

RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/*

EXPOSE 27001 27002 27003

COPY setup.sh .

CMD ["./setup.sh"]
