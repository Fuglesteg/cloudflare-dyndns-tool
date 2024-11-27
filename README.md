Little script in Guile scheme to update the ipv4 DNS records in cloudflare.
Meant to be used on servers requiring DDNS. 

Currently requires the existence of two files `token.secret` and `zone.secret`
in the working directory when the script is called.

# TODO

- [ ] Allow specifying ipv4 addresses or domain names to change
- [ ] Allow specifying token.secret and zone.secret files or directly giving
them through args
