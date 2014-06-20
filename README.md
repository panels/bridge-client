# bridge-client

Client library for connecting to panel bridge

```javascript
var bridge = new Bridge();

bridge.emit('someAction', {
  message: 'This is a message from bridge'
});

bridge.on('someEvent', function (data) {
  console.log(data);
});
```

## development

Edit `src/main.coffee`, use `npm run prepublish` to build compiled and minified `lib/bridge.js`.
