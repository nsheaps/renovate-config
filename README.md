# renovate-config

Centralized renovate configs for @nsheaps

## Usage

See [config preset documentation](https://docs.renovatebot.com/config-presets/#github) for more details.

TLDR:

```json
{
  // loads the default.json5 config
  "extends": ["github>nsheaps/renovate-config:default.json5"],
    ...
}
```

Other options:

- `github>nsheaps/renovate-config//presets/preset-name.json5`


## Development

We use json5, which allows comments and trailing commas.

Central config repos for renovate require the file to be named `renovate.json5`.

See [renovate docs](https://docs.renovatebot.com/configuration-options/#renovatejson5) for more details.