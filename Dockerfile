FROM alpine:3.19.1
RUN mkdir /conf
COPY dns-server /dns-server
RUN chmod 755 /dns-server
USER root
ENTRYPOINT ["./docker-entrypoint.sh"]
