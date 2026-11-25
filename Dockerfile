# Garage S3-compatible storage. The official image only contains the garage
# binary, so it is copied onto Alpine to add a shell for first-boot setup.
FROM dxflrs/garage:v2.6.0 AS garage

FROM alpine:3.22
RUN apk add --no-cache curl openssl
COPY --from=garage /garage /usr/local/bin/garage
COPY --chmod=755 railway-start.sh /usr/local/bin/railway-start.sh

EXPOSE 3900
CMD ["/usr/local/bin/railway-start.sh"]
