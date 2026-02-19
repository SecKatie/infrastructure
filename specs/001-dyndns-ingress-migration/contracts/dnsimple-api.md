# DNSimple API Contract

**Used by**: DynDNS Updater CronJob

## Authentication

All requests require:
```
Authorization: Bearer {DNSIMPLE_TOKEN}
Accept: application/json
Content-Type: application/json
```

## Endpoints Used

### Get Zone Record

```
GET /v2/{account_id}/zones/{zone_name}/records/{record_id}
```

**Response** (200 OK):
```json
{
  "data": {
    "id": 12345,
    "zone_id": "mulliken.net",
    "name": "*",
    "content": "136.57.83.9",
    "ttl": 300,
    "type": "A"
  }
}
```

### Update Zone Record

```
PATCH /v2/{account_id}/zones/{zone_name}/records/{record_id}
```

**Request body**:
```json
{
  "content": "NEW_IP_ADDRESS"
}
```

**Response** (200 OK):
```json
{
  "data": {
    "id": 12345,
    "zone_id": "mulliken.net",
    "name": "*",
    "content": "NEW_IP_ADDRESS",
    "ttl": 300,
    "type": "A"
  }
}
```

## Error Handling

| Status | Meaning         | DynDNS Updater Action       |
| ------ | --------------- | --------------------------- |
| 200    | Success         | Log, continue               |
| 401    | Bad token       | Notify via ntfy, exit error |
| 404    | Record not found | Notify via ntfy, exit error |
| 429    | Rate limited    | Retry next cycle            |
| 5xx    | Server error    | Retry next cycle            |

## ntfy.sh Notification Contract

### Send Notification

```
POST https://ntfy.sh/mulliken
```

**Headers**:
```
Title: DynDNS Update Failed
Priority: high
Tags: warning
```

**Body**: Plain text error message describing the failure.
