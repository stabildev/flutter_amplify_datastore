# Offline-first Flutter app with Amplify Auth, DataStore and GoRouter

To see the full tutorial from scratch, click [here](./tutorial.md)

## Prerequisites

- Set up Flutter and the Amplify CLI (follow the [Project setup guide](https://docs.amplify.aws/lib/project-setup/prereq/q/platform/flutter/))

## Steps

1. Run `flutter pub get` to install dependencies
2. Run `amplify init` to initialize the Amplify project

- Confirm the default values for all questions

3. Run `amplify add api` to add a GraphQL API

- Select `GraphQL` as the API type
- Select `Amazon Cognito User Pool` as the authentication type
- Enable `conflict detection` and select `Auto Merge` as the resolution strategy
- Select `Blank schema` as the schema template
- Replace the contents of `amplify/backend/api/flutter_amplify_datastore/schema.graphql` with the following schema:

```graphql
type Workout @model @auth(rules: [{ allow: owner }]) {
  id: ID!
  owner: String @auth(rules: [{ allow: owner, operations: [read, delete] }])
  createdAt: AWSDateTime!
  startedAt: AWSDateTime
  finishedAt: AWSDateTime
}
```

4. Run `amplify codegen models` to generate models
5. Run `amplify add auth` to add authentication

- Select `Email` as the sign-in method

6. Run `amplify push` to provision the backend
7. Run `flutter run` to start the app
