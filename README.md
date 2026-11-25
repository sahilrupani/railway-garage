# Garage on Railway

Railway packaging for [Garage](https://garagehq.deuxfleurs.fr/). It builds on the official, unmodified image, pinned to a release, and adds only what Railway needs.

Single-node, S3-compatible object storage.

- S3 API on `$PORT` (default `3900`), region `garage`. Attach a volume at `/data`.
- First boot creates the bucket in `GARAGE_BUCKET` and a key named `GARAGE_KEY_NAME`.
- Set `GARAGE_ACCESS_KEY` (`GK` + 24 hex characters) and `GARAGE_SECRET_KEY` (64 hex characters) to use your own key; otherwise one is generated. Read it from the deploy logs or with `garage key info --show-secret <name>` in the service shell.

## License

The files in this repository are MIT licensed (see `LICENSE`). Garage itself is licensed separately by its authors; this repository does not include or modify its source code.
