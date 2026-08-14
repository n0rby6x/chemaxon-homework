FROM alpine:3.22

WORKDIR /app

COPY app/rest_1.0_linux_amd64 /app/rest

RUN chmod +x /app/rest

EXPOSE 8080

ENTRYPOINT ["/app/rest"]
