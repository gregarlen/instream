# VAST & VPAID troubleshooting

```bash
$ mxmlc VASTPlayer.as -source-path=./vendor -warnings=false -o ./public/swf/VASTPlayer.swf
```

Or enable debugging

```bash
$ mxmlc VASTPlayer.as -source-path=./vendor -warnings=false -debug=true -o ./public/swf/VASTPlayer.swf 
```

# Use a webserver

Any webserver will do. Pthyon's `SimpleHTTPServer` should already be installed on a Mac OS X computer.

```bash
$ python -m SimpleHTTPServer
```