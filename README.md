# bridge-client

```javascript
var bridge = new Bridge();

bridge.emit('someAction', {
  message: 'This is a message from bridge'
});

bridge.on('someEvent', function (data) {
  console.log(data);
});
```
