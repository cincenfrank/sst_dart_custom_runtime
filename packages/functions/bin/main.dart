import 'package:aws_lambda_dart_runtime/aws_lambda_dart_runtime.dart';
import 'package:aws_lambda_dart_runtime/runtime/context.dart';
import 'package:functions/functions.dart' as functions;

void main() async {
  /// The Runtime is a singleton. You can define the handlers as you wish.
  Runtime()
    ..registerHandler<AwsApiGatewayEvent>(
      'calculate',
      calculate,
    )
    ..invoke();
}

/// This demo's handling an API Gateway request.
Future<dynamic> calculate(Context context, AwsApiGatewayEvent event) async {
  final response = {"result": functions.calculate()};
  return AwsApiGatewayResponse.fromJson(response);
}
