# StreamClosedCaptionerPhoenix

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Install Node.js dependencies with `npm install` inside the `assets` directory
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Env configs

Done through service

## Debug Live View

`liveSocket.enableDebug()`

## Migrate database

`bin/stream_closed_captioner_phoenix eval "StreamClosedCaptionerPhoenix.Release.migrate"`

## Debugging on Elastic Beanstalk

`eb logs`
`eb ssh` to get into the EC2 machine
`sudo -s` on the EC2 machine to run Docker commands and attach to the instance
`docker ps` will list the running containers
`docker exec -i -t container_name COMMAND` will connect you to the container in a Bash shell
