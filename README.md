Crosspoint
==========

This project aims at providing a place for real-time discussion.


Requirements
------------
* Ruby >= 2.0
* em-websocket


Installation
------------
For example, you can install required Gem packages using Bundler as follows:
```
gem install bundler
bundle install --path vendor/bundle
```

Optionally, you can install some Rack backends, such as Thin, and launch an HTTP
server by `rackup` command with the Rack configuration file `config.ru` provided
for convenience.
```
gem install thin
```


Usage
-----
The WebSocket server can be launched by the following command:
```
ruby ws_server.rb
```

For example, using our Rack configuration file, you can launch a HTTP server on
the port 8080 by the following command:
```
rackup -p 8080
```
