import 'package:appwrite/appwrite.dart';

/// Singleton Appwrite client for the app.
class AppwriteClient {
  static final AppwriteClient _instance = AppwriteClient._internal();
  late final Client client;
  late final Account account;

  factory AppwriteClient() {
    return _instance;
  }

  AppwriteClient._internal() {
    client = Client()
      ..setEndpoint(
        'https://[YOUR_APPWRITE_ENDPOINT]',
      ) // TODO: Replace with your Appwrite endpoint
      ..setProject(
        '[YOUR_PROJECT_ID]',
      ); // TODO: Replace with your Appwrite project ID
    account = Account(client);
  }
}
