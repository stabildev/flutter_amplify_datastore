# Build an offline-first Flutter app with Amplify Auth, DataStore and GoRouter

## Prerequisites

- Set up Flutter and the Amplify CLI (follow the [Project setup guide](https://docs.amplify.aws/lib/project-setup/prereq/q/platform/flutter/))

## Project Setup

### Create a new Flutter app

- Create a new Flutter app with `flutter create flutter_amplify_datastore`
- Open the project in VS Code
- Delete the folders for `web`, `macos`, `linux` and `windows`

### Set iOS deployment target and Android minSdkVersion

- Uncomment the following line in `ios/Podfile` and set the value to `13`:

```
platform :ios, '13.0'
```

- Set the `minSdkVersion` in `android/app/build.gradle` to `21`:

```
defaultConfig {
    ...
    minSdkVersion 24
    ...
}
```

### Clean up file structure

- Create a new folder `screens` in the `lib` folder
- Add a new file `home_screen.dart` in the `screens` folder
- Move the `MyHomePage` class from `main.dart` to `home_screen.dart` and rename it to `HomeScreen`

### Configure GoRouter

- Run `flutter pub add go_router` to add GoRouter to your project
- In `main.dart`, add the following GoRouter config:

```dart
// GoRouter configuration
  static final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const HomeScreen(title: 'Flutter Demo Home Page'),
      ),
    ],
  );
```

- Replace `MaterialApp(...)` with `MaterialApp.router()`:

```dart
@override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
```

### Time for a first build

- Run `flutter run` to see if everything works as expected

[Image: 01_counter.gif]

## Set up Amplify

### Add Amplify to your project

```bash
flutter pub add amplify_flutter

amplify init
```

- Confirm the default values for all questions
- Add a new file `amplify.dart` in the `lib` folder with the following content:

```dart
import 'package:amplify_flutter/amplify_flutter.dart';

import './amplifyconfiguration.dart';

Future<void> configureAmplify() async {
  try {
    // Plugins will be added here

    // call Amplify.configure to use the initialized categories in your app
    await Amplify.configure(amplifyconfig);
  } on AmplifyAlreadyConfiguredException {
    safePrint(
        'Tried to reconfigure Amplify; this can occur when your app restarts on Android.');
  } catch (e) {
    safePrint('Error during Amplify configuration:\n${e.toString()}');
  }
}
```

- In `main.dart`, updated the `main()` method to the following:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureAmplify();
  runApp(const MyApp());
}
```

## Set up DataStore

### Generate API

- Install the DataStore package:

```bash
flutter pub add amplify_datastore
```

- Run `amplify add api`
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

### Generate DataStore models for use with Flutter

```bash
amplify codegen models
```

We can now use the `Workout` model in our Flutter app.

### Initialize DataStore in Amplify config

- In `amplify.dart`, add the following:

```dart
import 'package:amplify_datastore/amplify_datastore.dart';
import './models/ModelProvider.dart';

...
  // Plugins will be added here
  final datastorePlugin =
      AmplifyDataStore(modelProvider: ModelProvider.instance);
  await Amplify.addPlugin(datastorePlugin);
...
```

### Display a list of items and add new items to the store

- Replace `_HomeScreenState` in `screens/home_screen.dart` with the following:

```dart
class _HomeScreenState extends State<HomeScreen> {
  // We will use this subscription to update the list of workouts when a new one is created
  // The first snapshot will include all workouts, subsequent snapshots will only include new workouts
  StreamSubscription<QuerySnapshot<Workout>>? _workoutSubscription;
  List<Workout> _workouts = [];

  void _observeWorkouts() {
    _workoutSubscription = Amplify.DataStore.observeQuery(Workout.classType)
        .listen((QuerySnapshot<Workout> snapshot) {
      setState(() {
        _workouts = snapshot.items;
      });
    });
  }

  void _initialize() {
    _observeWorkouts();
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _workoutSubscription?.cancel();
    super.dispose();
  }

  Future<void> _createWorkout() async {
    final workout = Workout(
      createdAt: TemporalDateTime.now(),
    );

    try {
      await Amplify.DataStore.save(workout);
      _queryWorkouts();
    } on DataStoreException catch (e) {
      safePrint('Could not create workout: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _workouts.isEmpty
          ? const Center(
              child: Text(
                'No workouts yet. Press the + button to create one.',
                textAlign: TextAlign.center,
              ),
            )
          : RefreshIndicator(
              onRefresh: _queryWorkouts,
              child: ListView.separated(
                itemCount: _workouts.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Workout ${index + 1}'),
                  subtitle: Text(_workouts[index].createdAt.toString()),
                ),
                separatorBuilder: (context, index) => const Divider(
                  height: 0,
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createWorkout,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

Read through the code and make sure you understand what's going on.

### Time for another build

- Run `flutter run` to see if everything works as expected
- When you click the `+` button, you should see a new item in the list
- The item is stored locally on the device

[Image: 02_list.gif]

### Add a detail screen

- Create a new file `details_screen.dart` in the `screens` folder with the following content:

```dart
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../models/Workout.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({
    super.key,
    required this.workout,
    required this.workoutNumber,
  });

  final Workout workout;
  final int workoutNumber;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Future<void> _handleDelete() async {
    try {
      await Amplify.DataStore.delete(widget.workout);
      if (mounted) {
        context.pop();
      }
    } on DataStoreException catch (e) {
      safePrint('Could not delete workout: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Workout ${widget.workoutNumber}'),
            Text('Created at: ${widget.workout.createdAt}'),
            TextButton(
              onPressed: _handleDelete,
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            )
          ],
        ),
      ),
    );
  }
}
```

- In `main.dart`, add the following route to the router config:

```dart
GoRoute(
  path: '/workout/:id',
  builder: (context, state) {
    // final id = state.pathParameters['id'];
    final extra = state.extra as Map;
    final workout = extra['workout'] as Workout;
    final workoutNumber = extra['workoutNumber'] as int;
    return DetailsScreen(
      workout: workout,
      workoutNumber: workoutNumber,
    );
  },
),
```

- Add the following method to `_HomeScreenState` (Don't forget to import GoRouter):

```dart
void _handleWorkoutTap(Workout workout) {
  context.push('/workout/${workout.id}', extra: {
    'workout': workout,
    'workoutNumber': _workouts.indexOf(workout) + 1,
  });
}
```

- Set the onTap handler of the `ListTile` in `_HomeScreenState` to `_handleWorkoutTap`:

```dart
onTap: () => _handleWorkoutTap(_workouts[index]),
```

Now when you tap on a workout in the list, you should see the details screen. When you tap the delete button, the workout should be deleted from the list.
You will need to refresh the list by pulling down to see the changes.

[Image: 03_details.gif]

## Add cloud synchronization

> It is recommended to develop without cloud synchronization enabled initially so you can change the schema as your application takes shape without the impact of having to update the provisioned backend. Once you are satisfied with the stability of your data schema, setup cloud synchronization as described below and the data saved locally will be synchronized to the cloud automatically.

### Add authentication with AWS Cognito and the API plugin

- Run `flutter pub add amplify_auth_cognito amplify_api`

- Run `amplify add auth` and select `Email` as the sign-in method
- Run `amplify push` to push your changes to the cloud

- In `amplify.dart`, add the following:

```dart
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';

...
  // Plugins will be added here
  final authPlugin = AmplifyAuthCognito();
  await Amplify.addPlugin(authPlugin);

  final api = AmplifyAPI();
  await Amplify.addPlugin(api);
...
```

### Add a login screen

- Add the Amplify Authenticator package:

```bash
flutter pub add amplify_authenticator
```

- Create a new file `login_screen.dart` in the `screens` folder with the following content:

```dart
import 'package:flutter/material.dart';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _handleLogoutTap(BuildContext context) async {
    await Amplify.Auth.signOut();
    if (context.mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      child: MaterialApp(
        builder: Authenticator.builder(),
        home: Scaffold(
          body: Center(
            child: Column(
              children: [
                const Text('You are logged in!'),
                TextButton(
                  onPressed: () => _handleLogoutTap(context),
                  child: const Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- In `main.dart`, add the following route to the router config:

```dart
GoRoute(
  path: '/login',
  builder: (context, state) => const LoginScreen(),
),
```

- In `_HomeScreenState`, add the following to the `AppBar`:

```dart
actions: [
  IconButton(
    onPressed: () => context.push('/login'),
    icon: const Icon(Icons.person),
  ),
],
```

- Restart your app

Now you should see a login screen when you tap the person icon in the app bar.
You can create a new account or sign in with an existing one.

[Image: 04_login.gif]

### Handle authentication state changes

When the user signs in or out, we want to clear the list of workouts.

- In `home_screen.dart`, add the following to `_HomeScreenState`:

```dart
StreamSubscription<AuthHubEvent>? _authSubscription;

void _observeAuthEvents() {
  _authSubscription =
      Amplify.Hub.listen(HubChannel.Auth, (AuthHubEvent event) {
    switch (event.type) {
      case AuthHubEventType.signedIn:
        _onLogin();
        break;
      case AuthHubEventType.signedOut:
        _onLogout();
        break;
      default:
        break;
    }
  });
}

void _onLogin() async {
  _workoutSubscription?.cancel();
  await Amplify.DataStore.clear();
  _observeWorkouts();
}

void _onLogout() async {
  _workoutSubscription?.cancel();
  await Amplify.DataStore.clear();
  _observeWorkouts();
}

...

void _handleAuthEvent(AuthHubEvent event) {
  switch (event.type) {
    case AuthHubEventType.signedOut:
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Signed out'),
          content: Text('You have been signed out.'),
        ),
      );
      break;
    case AuthHubEventType.signedIn:
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Signed in'),
          content: Text('You have been signed in.'),
        ),
      );
      break;
    default:
      break;
  }
}

@override
void initState() {
  super.initState();
  _queryWorkouts();
  _authSubscription = Amplify.Hub.listen(HubChannel.Auth, _handleAuthEvent);
}

@override
void dispose() {
  _authSubscription.cancel();
  super.dispose();
}
```

Restart your app. As you log in and out, you will see that the list of workouts is cleared.

### Sync offline workouts after login

Since we are creating an offline-first app, we want to sync the workouts that were created before the user logged in (or possible even before the user created an account).

To accomplish this, we have to copy the existing workouts and save them as the logged in user after the user logs in.

We have to make sure that the sync is completed before we reset the workout list. Otherwise, the workouts would be deleted before they are synced.

Amplify doesn't allow us to copy workouts without the id, so we have to create a new workout with the same id and copy the other properties.

The code for this is not straightforward, so make sure you understand what's going on.

- In `home_screen.dart`, replace `_onLogin()` with the following:

```dart
void _onLogin() async {
  _workoutSubscription?.cancel();

  if (_workouts.isEmpty) {
    Amplify.DataStore.clear();
    _observeWorkouts();
  }

  if (_workouts.isNotEmpty) {
    // Add local workouts to account
    // We need to recreate the workout objects without the ID
    final localWorkouts = await Amplify.DataStore.query(Workout.classType);
    final localWorkoutsWithoutId = localWorkouts.map((workout) => Workout(
          createdAt: workout.createdAt,
          startedAt: workout.startedAt,
          finishedAt: workout.finishedAt,
        ));

    // Keep track of which workouts have yet to be synced
    // We use the createdAt timestamp as a (sufficiently) unique identifier
    List<String> pendingWorkoutTimestamps = localWorkoutsWithoutId
        .map((workout) => workout.createdAt.toString())
        .toList();

    // Subscription to wait for syncing to finish before clearing
    late final StreamSubscription<DataStoreHubEvent> stream;
    stream = Amplify.Hub.listen(HubChannel.DataStore, (event) async {
      if (event.type == DataStoreHubEventType.outboxMutationProcessed) {
        final processedEvent = event.payload as OutboxMutationEvent;
        if (processedEvent.modelName == Workout.classType.modelName()) {
          final workout = processedEvent.element.model as Workout;
          pendingWorkoutTimestamps.remove(workout.createdAt.toString());
          if (pendingWorkoutTimestamps.isEmpty) {
            safePrint('All workouts synced');
            stream.cancel();
            Amplify.DataStore.clear();
            _observeWorkouts();
          }
        }
      }
    });

    // Save local workouts to account
    try {
      for (final workout in localWorkoutsWithoutId) {
        await Amplify.DataStore.save(workout);
      }
    } on DataStoreException catch (e) {
      safePrint('Could not save workouts: ${e.message}');
    }
  }
}
```

And that's it! Now you have a fully functional offline-first app with cloud synchronization.
