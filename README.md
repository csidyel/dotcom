[![Build Status](https://semaphoreci.com/api/v1/projects/ed6a7697-4bde-446b-89bd-47c634431bf0/950162/badge.svg)](https://semaphoreci.com/mbta/dotcom)

# DotCom

The new face of http://mbta.com/

## Getting Started

1. Install Erlang/Elixir: http://elixir-lang.org/install.html
1. Install NodeJS: https://nodejs.org/en/download/
1. Install Sass:
  * `gem install sass`
  * You might get a permission error here.  You can either `sudo gem install
    sass`, or install a Ruby environment manager.
1. Install Phoenix: http://www.phoenixframework.org/docs/installation
1. Install our Elixir dependencies:
  * `mix deps.get`
1. Install our Node dependencies:
  * `npm run install`
  * If you run into an error about fetching a Github dependency, you can tell Git to always use HTTP for Github:

      git config --global url.https://github.com/.insteadOf git://github.com/
1. Run `npm run brunch:build`

## Running the Server

    mix phoenix.server

Then, visit the site at http://localhost:4001/

## Tests

Run `mix phoenix.server` to start a server in one window, then open a
separate window and run `npm test` from the main folder. This will execute
the following scripts in succession:

* `mix test` — Phoenix tests
* `npm run test:js` — JS tests
* `mix backstop.tests` — Backstop tests (see section below for details)

Note that all tests will run even if one of them fails, and there is no final
summary at the end, so pay attention to the output while they're running to
make sure everything passes.

### Other helpful test scripts

All run from the main folder:

* `npm run backstop:reference` — create new backstop reference images
* `npm run backstop:bless` — allow backstop tests to run after changing the
  backstop.json file without creating new reference images
* `npm run brunch:build` — builds the static files

## Backstop Tests

We use [BackstopJS](https://github.com/garris/BackstopJS) to test for
unexpected visual changes. Backstop works by keeping a repository of
reference images; when you run a backstop test it takes snapshots of the
pages on your localhost and compares them to those references images; if
anything has changed then the test will fail. This helps us catch unintended
changes to the UI (typically a CSS selector that is broader than
expected). Whenever you make a change that affects the UI, you will need to
update the backstop images.

In order to make sure the tests are reproducible, we use
[WireMock](http://wiremock.org/) to record and playback the V3 API responses.

### Running the tests

1. (once) Download
   [WireMock](http://repo1.maven.org/maven2/com/github/tomakehurst/wiremock-standalone/2.1.10/wiremock-standalone-2.1.10.jar), and place it in the `bin/` directory.
1. (once) Download [Goon](https://github.com/alco/goon/releases/download/v1.1.1/goon_darwin_amd64.tar.gz), untar it with `tar -xf goon_darwin_amd64.tar.gz`, and place it in the `bin/` directory.
1. Install JDK if you do not have it already. Type `java` at the command line and follow the prompts.
1. Build the static files:
  * `npm run brunch:build && mix phoenix.digest`
1. Run the tests:
  * `mix backstop.tests`
  * You may need to run `npm run backstop:bless` in make sure the timestamps
    are correct.

### Updating the images

1. Running the tests generates a new folder in
    `apps/site/backstop_data/bitmaps_test/` with images for each test that
    were generated from your localhost
1. Review the test output and confirm that the only tests that failed were
   the ones with changes you meant to make (if not, fix any unintentional
   changes before proceeding)
1. For each image that failed as expected, delete the corresponding image in
   `apps/site/backstop_data/bitmaps_reference` and replace it with the new
   image generated by the test.
   * A quick way to update the files would be to run `mix backstop.update`, which
   will find all the most recently failed tests and copy them over.
   * Alternatively, you can explicitly pass a list of failed test files to update with
   ```bash
   mix backstop.update 1_1_mode-group-block_0_phone.png 1_1_mode-group-block_2_tablet_h.png
   ```
1. Make sure the tests pass:
  * `mix backstop.tests`

### Updating the API responses

1. Run the WireMock server in record-mappings mode:
  * `java -jar ${WIREMOCK_PATH} —proxy-all="http://mbta-api-prod.us-east-1.elasticbeanstalk.com" --record-mappings`

## Building

1. (once) Install Docker: https://docs.docker.com/engine/installation/
1. Build the .ZIP package:
  * `sh build.sh`

This will build the release in a Docker container, and put the files in
`site-build.zip`

## Deploying

1. (once) Install the AWS EB CLI:
   http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install.html
1. (once) Get AWS credentials (Access Key ID and Secret Access Key)
1. (once) Create `~/.aws/config` with the following:

    ```
    [profile eb-cli]
    aws_access_key_id = <YOUR ACCESS KEY ID>
    aws_secret_access_key = <YOUR SECRET ACCESS KEY>
    ```

1. Deploy the built file:
  * `eb deploy`

You should now be able to see the new site at
http://mbta-dotcom-dev-green.us-east-1.elasticbeanstalk.com/
