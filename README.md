# tealtowns

Python (with sockets) + MongoDB + Flutter


## Setup

- Replace all instances of `seed_app`, `com.example.seed-app` and `seedApp` with the name / path of your app.

- Install python
  - E.g. Install pyenv: https://github.com/pyenv/pyenv
    - Use `pyenv install 3.11.x` to install, then add a .python-version file with 3.11.x in the directory to use it; `python -V` should show this version.

For (Ubuntu) script, see `server-setup.sh`

- `pip install -r ./requirements.txt`
  - For Mac: `pip install tensorflow-macos tensorflow-metal`
- set up configs (these vary per environment and contains access keys so are NOT checked into version control)
  - `cp config.sample.yml config.yml` then edit `config.yml` as necessary.
  - `cp configloggly.sample.conf config-loggly.conf` and edit `config-loggly.conf` as needed.
  - `cp frontend/.sample-env frontend/.env` and edit `.env` as needed.
- frontend `cd frontend && flutter build web` (for frontend)
- setup config (see configuration section in `server-setup.sh`)

- make sure all Android / iOS (manifest / pList) files are update for any dependencies, e.g.
  - http (Android Internet permission)
  - file picker
  - etc (see individual dependencies for installation notes)


### SSL (HTTPS) with letsencrypt

- Run on server without SSL (set config.yml and frontend/.env to http only)
- `certbot certonly --webroot` (just use /var/www/tealtowns for the webroot, though not sure if this matters?)
- Update config.yml and frontend.env to use https (and add the path to the generated SSL files)


### Setup third party tools

Create accounts and add api keys in configs for each:
- database: mongodb - free tier on AtlasDB
- CircleCI
  - (Create and) add SSH key to circleci.com project settings (and ensure added to server)
- email: free tier on mailchimp or sendgrid
- logging: free tier on loggly


## Local development

- backend (server): `python web_server.py`
- frontend (browser):
  - `cd frontend && flutter run -d chrome --web-port=PORT`
  - OR for non chrome (will have to manually open browser, type in URL & reload page for updates), `flutter run -d web-server --web-port=PORT`

## Tests

- `python -m pytest`
- `cd frontend` then `flutter test`


## Rebuilding Mobile

- update version & build in pubspec.yaml & run `flutter clean`
- iOS
  - `flutter build ios`
  - Open Runner.xcworkspace & use xCode to archive & upload the build to AppStoreConnect & submit for review
- Android
  - `flutter build appbundle`
  - Use Google Play to upload app bundle & submit for review


## Updates (should be done via CI)

`git pull origin main`
`pip3 install -r ./requirements.txt` (only necessary if updated requirements.txt)
`cd frontend && flutter build web && cd ../`
`systemctl restart systemd_web_server_tealtowns.service`


### Versions

- Since Android & iOS take extra time to build and be approved in the app store (and for users to update), we will always have at lease TWO different versions live at once. Thus the backend needs to always support both the current (most recent) version and (at least) 1 version back, since there is only one copy of the live backend and breaking changes will not be instantly updated on mobile, thus would break the mobile apps.
    - So, the backend will need multi (2) version support. Once a new version is released though, clean up 3+ versions behind code and force a mobile / frontend update to the current supported (2 most recent) versions.
