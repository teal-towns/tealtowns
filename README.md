# tealtowns

Python (with sockets) + MongoDB + Flutter

## Setup

- Note: all commands are run in Terminal
- Download and install Python 3.11, Flutter, VS Code (or other code editor)
- (Set up Github SSH key and) `git clone git@github.com:teal-towns/tealtowns.git` then `cd tealtowns` into the code repository and run all commands from here.

Note, may have to replace all `pip` with `pip3` and `python` with `python3`. Type `python -V` to see your version of python. If it is not 3.11, try `python3 -V` instead.
- `pip install -r ./requirements.txt`
  - For Mac: `pip install tensorflow-macos tensorflow-metal`
- Download and copy over `config.yml` and `frontend/.env`
  - https://drive.google.com/drive/u/0/folders/1jfnFmkQUZ0YpXnDtyy8Zk9y7CplBja2Y
- `cd frontend && flutter build web` (for frontend)

## Local development

- backend (server): `python web_server.py`
- frontend (browser):
  - `cd frontend && flutter run -d chrome --web-port=PORT`
  - OR for non chrome (will have to manually open browser, type in URL & reload page for updates), `flutter run -d web-server --web-port=PORT`
- Stripe testing: `stripe listen --forward-to localhost:8081/web/stripe-webhooks`
  - https://docs.stripe.com/payments/checkout/fulfill-orders

## Tests

- `python -m pytest`
- `cd frontend` then `flutter test`

## Git Flow (Writting and Pushing Code)
Note: `git status -s` to see current status/changes.
- `git checkout main && git pull origin main`
- `git checkout -b MY-BRANCH`
- [Write your code and bump the version in `frontend/pubspec.yml` (e.g. increment `version: 1.0.0+6` to `version: 1.0.0+7`)]
- `git add . && git commit -am 'SUMMARY OF MY CODE CHANGES'`
- `git checkout main && git pull origin main && git checkout MY-BRANCH && git rebase main`
- `git push origin MY-BRANCH`
- Open a pull request on github.com. Make sure tests pass, then ask for a code review. Once approved, merge it on github.com This will automatically deploy your code.
- `git checkout main && git pull origin main && git branch -d MY-BRANCH`

## Rebuilding Mobile

- update version & build in pubspec.yaml & run `flutter clean`
- iOS
  - `flutter build ios`
  - Open Runner.xcworkspace & use xCode to archive & upload the build to AppStoreConnect & submit for review
- Android
  - `flutter build appbundle`
  - Use Google Play to upload app bundle & submit for review

## Common actions

### Twilio / whatsapp

- Add WhatsApp message templates on twilio.com Content Template Builder, then add / update the ids in `config.yml`
