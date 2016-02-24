#  key-manager
## simple s3 backed key management
FROM scratch

MAINTAINER Alex Rudd <github.com/AlexRudd/key-manager/issues>

# Add ca-certificates.crt
ADD ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# Add executable
ADD _bin/key-manager /

ENTRYPOINT ["/key-manager"]
