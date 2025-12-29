# Fact Check Manager

Fact Check Manager is an app which handles the Fact Checking process for content being produced through Mainstream Publisher.

The aim of Fact Check Manager is to improve security of Publisher and improve ease of access for SPOCs and SMEs by abstracting out this process where non-GDS staff who are not regular users require access to draft content.

## Nomenclature

- **Artefact**: a document on GOV.UK.
- **SME**: Subject Matter Expert. Members of other departments with specialist knowledge about operational or policy subjects.
- **SPOC**: Single Point of Contact. Elevated permissions in this app, can share read-only links to the change with SPOCs, and submit the final response through this app.

## Technical documentation

This is a Rails application and should follow [our Rails app conventions](https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html).

### Setting up Fact Check Manager

You can use the [GOV.UK Docker environment](https://github.com/alphagov/govuk-docker) to run the application and its tests with all the necessary dependencies.  Follow [the usage instructions](https://github.com/alphagov/govuk-docker#usage) to get started.

Initially building the app with:

```shell
make fact-check-manager
```

Only needs to be done once. After this, it will pick up changes to your local branches and use whichever one you have checked out. Re-running this command can be a useful way to wipe your local Fact Check Manager container and start fresh if it ends up in a corrupted state.

### Running Locally

The app can be run locally using:

```sh
govuk-docker up fact-check-manager-app
```

And then visiting http://fact-check-manager.dev.gov.uk/ in your web browser. The terminal you use to run the command will display useful server activity logs for debugging. Make sure to use `control + c` to gracefully shut down the server when you're done with it.

You can open the rails console for your local container with:

```shell
govuk-docker run fact-check-manager-lite bash
```

or the rails console with:

```shell
govuk-docker run fact-check-manager-lite rails c
```
### Running the test suite

The default `rake` task runs all the tests:

```sh
govuk-docker run fact-check-manager-lite bundle exec rake
```

## Licence

[MIT License](LICENCE)