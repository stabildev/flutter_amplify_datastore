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
