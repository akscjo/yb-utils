## How to get API Token if it already exists

```
curl --location --request POST 'https://<YBA-SERVER-IP>/api/v1/api_login' \
--header 'Content-Type: application/json' \
--data-raw '{
"email":"XXXX@yugabyte.com"
,"password":"YYYY"
}'
```

## How to get Auth Token 

```
curl --location --request POST 'https://<YBA-SERVER-IP>/api/v1/login' \
--header 'Content-Type: application/json' \
--data-raw '{
"email":"xxx@yugabyte.com"
,"password":"yyyy"
}' \
-k
```

```sql
{"authToken":"xxxxxxxxxxxxxxxxxxxxx","customerUUID":"8e3c095d-e943-4fb1-b987-fcb89a69c6e0","userUUID":"203ec6e4-b4bd-4e50-8952-2bfe594d10d3"}%
```

```markdown
curl --request GET \
  --url https://<YBA-SERVER-IP>/api/v1/customers \
  --header 'Accept: application/json' \
  --header 'X-AUTH-TOKEN: xxxxxxxxxxxxxxxxxxxxx' \
  -k
```

## Generate new API Token:

```sql
curl --request PUT \
--url https://<YBA-SERVER-IP>/api/v1/customers/8e3c095d-e943-4fb1-b987-fcb89a69c6e0/api_token \
--header 'Accept: application/json' \
--header 'X-AUTH-TOKEN: xxxxxxxxxxxxxxxxxxxxx' \
-k
```
```
{"apiToken":"27011623-05b6-47cc-81a8-bce47ba911a4","apiTokenVersion":6,"customerUUID":"8e3c095d-e943-4fb1-b987-fcb89a69c6e0","userUUID":"203ec6e4-b4bd-4e50-8952-2bfe594d10d3"}%
```

## List of Universes using X-AUTH-TOKEN:

```markdown
  curl --request GET \
  --url https://<YBA-SERVER-IP>/api/v1/customers/8e3c095d-e943-4fb1-b987-fcb89a69c6e0/universes \
  --header 'Accept: application/json' \
  --header 'X-AUTH-TOKEN: xxxxxxxxxxxxxxxxxxxxx' \
  -k
```

## List of Universes using X-AUTH-YW-API-TOKEN

```markdown
  curl --request GET \
  --url https://<YBA-SERVER-IP>/api/v1/customers/8e3c095d-e943-4fb1-b987-fcb89a69c6e0/universes \
  --header 'Accept: application/json' \
  --header 'X-AUTH-YW-API-TOKEN: 27011623-05b6-47cc-81a8-bce47ba911a4' \
  -k
```
