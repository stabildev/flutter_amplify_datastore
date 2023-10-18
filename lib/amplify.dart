import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_api/amplify_api.dart';

import './models/ModelProvider.dart';
import './amplifyconfiguration.dart';
// import './models/ModelProvider.dart';

Future<void> configureAmplify() async {
  try {
    // Plugins will be added here
    final authPlugin = AmplifyAuthCognito();

    final datastorePlugin =
        AmplifyDataStore(modelProvider: ModelProvider.instance);

    final api = AmplifyAPI();
    await Amplify.addPlugins([datastorePlugin, api, authPlugin]);

    // call Amplify.configure to use the initialized categories in your app
    await Amplify.configure(amplifyconfig);
  } on AmplifyAlreadyConfiguredException {
    safePrint(
        'Tried to reconfigure Amplify; this can occur when your app restarts on Android.');
  } catch (e) {
    safePrint('Error during Amplify configuration:\n${e.toString()}');
  }
}
