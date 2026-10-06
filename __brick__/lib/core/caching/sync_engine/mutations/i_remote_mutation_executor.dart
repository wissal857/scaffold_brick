import 'package:{{project_name}}/core/caching/models/remote_mutation_response.dart';
import 'package:{{project_name}}/core/caching/models/valid_mutation_data.dart';

abstract interface class IRemoteMutationExecutor {
  Future<List<RemoteMutationResponse>> execute(
    List<ValidMutationData> pendingMutations,
  );
}
