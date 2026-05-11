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

## Reproducing the production build

Production images are built by [Nixpacks](https://nixpacks.com/) (configured in `nixpacks.toml`) and deployed via Coolify. To reproduce locally:

```sh
nixpacks build . --name scc-phoenix
docker run --rm -p 4000:4000 --env-file .env.prod-test scc-phoenix
```

`.env.prod-test` is gitignored — see `config/runtime.exs` for the required environment variables. At minimum you need `SECRET_KEY_BASE`, `LIVE_SIGNING_SALT`, `TWITCH_TOKEN_SECRET`, and either `DATABASE_URL` (with `USE_SSL=true`) or the `RDS_*` set.

The container starts with `/app/bin/server`, which runs `Release.migrate` and then boots Phoenix on port 4000.

## Debugging on Elastic Beanstalk

`eb logs`
`eb ssh` to get into the EC2 machine
`sudo -s` on the EC2 machine to run Docker commands and attach to the instance
`docker ps` will list the running containers
`docker exec -i -t container_name COMMAND` will connect you to the container in a Bash shell
