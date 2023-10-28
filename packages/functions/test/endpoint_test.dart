import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:aws_lambda_dart_runtime/aws_lambda_dart_runtime.dart';
import 'package:aws_lambda_dart_runtime/runtime/context.dart';
import 'package:test/test.dart';

import '../bin/main.dart';

void main() async {
  group('calculate', () {
    late AwsApiGatewayResponse response;
    setUp(() {
      final fnName = "calculate";
      final context = Context(requestId: 'testRequest', handler: fnName);
      final event = createEvent(
        fnName: fnName,
        body: {"test": 1234},
      );

      calculate(context, event).then((value) {
        response = value;
      });
    });
    final experctedResult = {"result": 1000000};
    test('response', () async {
      expect(response.statusCode, 200);
    });
    test('body', () async {
      expect(jsonDecode(response.body!), experctedResult);
    });
  });
}

// Future<Context> createContext() async {
//   final nextInvocation =
//       await NextInvocation.fromResponse(http.Response('{}', 200));

//   final ctx = Context.fromNextInvocation(nextInvocation);
//   return ctx;
// }

AwsApiGatewayEvent createEvent({
  String fnName = "test",
  Object body = const Object(),
}) {
  final bodyString = jsonEncode(body);
  final eventTest = {
    "path": "/test/$fnName",
    "headers": {
      "Accept":
          "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
      "Accept-Encoding": "gzip, deflate, lzma, sdch, br",
      "Accept-Language": "en-US,en;q=0.8",
      "CloudFront-Forwarded-Proto": "https",
      "CloudFront-Is-Desktop-Viewer": "true",
      "CloudFront-Is-Mobile-Viewer": "false",
      "CloudFront-Is-SmartTV-Viewer": "false",
      "CloudFront-Is-Tablet-Viewer": "false",
      "CloudFront-Viewer-Country": "US",
      "Host": "wt6mne2s9k.execute-api.us-west-2.amazonaws.com",
      "Upgrade-Insecure-Requests": "1",
      "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.82 Safari/537.36 OPR/39.0.2256.48",
      "Via": "1.1 fb7cca60f0ecd82ce07790c9c5eef16c.cloudfront.net (CloudFront)",
      "X-Amz-Cf-Id": "nBsWBOrSHMgnaROZJK1wGCZ9PcRcSpq_oSXZNQwQ10OTZL4cimZo3g==",
      "X-Forwarded-For": "192.168.100.1, 192.168.1.1",
      "X-Forwarded-Port": "443",
      "X-Forwarded-Proto": "https"
    },
    "pathParameters": {"proxy": "hello"},
    "requestContext": {
      "accountId": "123456789012",
      "resourceId": "us4z18",
      "stage": "test",
      "requestId": "41b45ea3-70b5-11e6-b7bd-69b5aaebc7d9",
      "identity": {
        "cognitoIdentityPoolId": "",
        "accountId": "",
        "cognitoIdentityId": "",
        "caller": "",
        "apiKey": "",
        "sourceIp": "192.168.100.1",
        "cognitoAuthenticationType": "",
        "cognitoAuthenticationProvider": "",
        "userArn": "",
        "userAgent":
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.82 Safari/537.36 OPR/39.0.2256.48",
        "user": ""
      },
      "resourcePath": "/{proxy+}",
      "httpMethod": "POST",
      "apiId": "wt6mne2s9k"
    },
    "body": bodyString,
    "resource": "/{proxy+}",
    "httpMethod": "GET",
    "queryStringParameters": {"name": "me"},
    "stageVariables": {"stageVarName": "stageVarValue"}
  };
  return AwsApiGatewayEvent.fromJson(eventTest);
}
