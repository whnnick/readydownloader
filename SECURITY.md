# Security Policy

## Supported Versions

The project is pre-release. Security fixes are applied to the latest development branch until the first stable release.

## Reporting a Vulnerability

Do not disclose a vulnerability containing credentials, cookies, private URLs, or personal media in a public issue.

Until a private GitHub security-reporting channel is configured, open a public issue containing only a non-sensitive summary and request a private contact channel. Maintainers will publish a dedicated security contact before the first stable release.

## Sensitive Data

- Never commit `config/yt_cookies.txt` or another exported browser cookie file.
- Never upload logs that expose cookies, authorization headers, private URLs, local usernames, or personal media paths.
- Release packages must not contain cookies, downloaded media, PDB files, local build paths, `.env` files, or IDE state.
- Toolchain downloads must be pinned and integrity-checked before packaging.

If a cookie file has been shared accidentally, revoke the corresponding browser or Google account session before generating a replacement.
