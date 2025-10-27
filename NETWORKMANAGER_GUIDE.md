# NetworkManager Quick Reference

## Usage Guide

### POST Requests (JSON body)

```swift
NetworkManager.shared.post(endpoint: "/your-endpoint", body: ["key": "value"]) { response in
    guard let response = response else {
        print("Request failed")
        return
    }
    
    // Process response dictionary
    if let status = response["status"] as? String {
        print("Status: \(status)")
    }
}
```

### GET Requests (returns Data)

```swift
NetworkManager.shared.get(endpoint: "/your-endpoint") { data in
    guard let data = data else {
        print("Request failed")
        return
    }
    
    // Process raw data
}
```

### GET Requests (expects JSON Array)

```swift
NetworkManager.shared.getArray(endpoint: "/search/query") { jsonArray in
    guard let jsonArray = jsonArray else {
        print("Request failed")
        return
    }
    
    // Process array of dictionaries
    for item in jsonArray {
        // Access item["key"]
    }
}
```

## Configuration Details

### Timeouts
- **Request**: 10 seconds
- **Resource**: 15 seconds

### Connection Settings
- **Max connections per host**: 10
- **HTTP Pipelining**: Enabled
- **Keep-Alive**: Enabled

### Cache Policy
- API responses are **NOT cached**
- Set to: `.reloadIgnoringLocalCacheData`

## Performance Monitoring

All requests automatically log their performance:
```
✅ /endpoint - Status: 200 - Time: 0.45s
❌ /endpoint - Network error (took 10.00s): The request timed out.
```

## When to Use

✅ **Use NetworkManager for:**
- All API calls to partyaux.party
- RESTful HTTP requests
- JSON data exchange

❌ **Don't use for:**
- Socket.IO connections (use SocketManager)
- Image downloads (use AsyncImage)
- File downloads/uploads (may need different configuration)

## Error Handling

NetworkManager handles:
- Network timeouts (10s)
- Connection failures
- JSON parsing errors
- HTTP status codes

All errors are logged to console with emoji indicators:
- ✅ Success
- ❌ Error
- 🔍 Debug info
- ⚠️ Warning

## Tips

1. **Check console logs** for request timing
2. **Response times > 2s** may indicate server issues
3. **Timeouts at 10s** suggest connectivity problems
4. All callbacks run on **main thread** (already handled)

## Common Patterns

### With Loading State
```swift
isLoading = true
NetworkManager.shared.post(endpoint: "/login", body: credentials) { response in
    self.isLoading = false
    
    guard let response = response else {
        self.showError = true
        return
    }
    
    // Handle success
}
```

### With Completion Handler
```swift
func fetchData(completion: @escaping () -> Void) {
    NetworkManager.shared.post(endpoint: "/data", body: [:]) { response in
        // Process response
        completion()
    }
}
```

### Chaining Requests
```swift
NetworkManager.shared.post(endpoint: "/first", body: [:]) { response1 in
    guard let response1 = response1 else { return }
    
    NetworkManager.shared.post(endpoint: "/second", body: [:]) { response2 in
        guard let response2 = response2 else { return }
        
        // Both requests complete
    }
}
```

## Troubleshooting

### Slow Requests
1. Check console for response time logs
2. Verify server is responding quickly
3. Test with Postman for comparison

### Timeout Errors
1. Verify network connectivity
2. Check server status
3. May need to increase timeout for specific endpoints

### JSON Parsing Errors
1. Check raw response in console logs
2. Verify server is returning valid JSON
3. Ensure correct endpoint is being called

## Migration Notes

When migrating old code:

**Before:**
```swift
guard let url = URL(string: "https://api.partyaux.party/endpoint") else { return }
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try? JSONSerialization.data(withJSONObject: body)
URLSession.shared.dataTask(with: request) { data, response, error in
    // Handle...
}.resume()
```

**After:**
```swift
NetworkManager.shared.post(endpoint: "/endpoint", body: body) { response in
    // Handle...
}
```

✨ Much cleaner and automatically optimized!
