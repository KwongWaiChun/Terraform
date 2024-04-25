# github-oidc-terraform

You need to set the file github-action.yml inside this directory:

```bash
.github/workflows/
```


openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=foo.bar.com"