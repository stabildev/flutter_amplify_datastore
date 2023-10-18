import 'dart:async';

import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';

import '../models/Workout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<QuerySnapshot<Workout>>? _workoutSubscription;
  StreamSubscription<AuthHubEvent>? _authSubscription;

  List<Workout> _workouts = [];

  void _observeWorkouts() {
    _workoutSubscription = Amplify.DataStore.observeQuery(Workout.classType)
        .listen((QuerySnapshot<Workout> snapshot) {
      setState(() {
        _workouts = snapshot.items;
      });
    });
  }

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

  Future<void> _createWorkout() async {
    final workout = Workout(
      createdAt: TemporalDateTime.now(),
    );
    try {
      await Amplify.DataStore.save(workout);
    } on DataStoreException catch (e) {
      safePrint('Could not create workout: ${e.message}');
    }
  }

  void _handleWorkoutTap(Workout workout) {
    context.push('/workout/${workout.id}', extra: {
      'workout': workout,
      'workoutNumber': _workouts.indexOf(workout) + 1,
    });
  }

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

  void _onLogout() async {
    _workoutSubscription?.cancel();
    await Amplify.DataStore.clear();
    _observeWorkouts();
  }

  void _initialize() {
    _observeWorkouts();
    _observeAuthEvents();
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _workoutSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: _workouts.isEmpty
          ? const Center(
              child: Text(
                'No workouts yet. Press the + button to create one.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              itemCount: _workouts.length,
              itemBuilder: (context, index) => ListTile(
                title: Text('Workout ${index + 1}'),
                subtitle: Text(_workouts[index].owner.toString()
                    // _workouts[index].createdAt.toString(),
                    ),
                onTap: () => _handleWorkoutTap(_workouts[index]),
              ),
              separatorBuilder: (context, index) => const Divider(
                height: 0,
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
