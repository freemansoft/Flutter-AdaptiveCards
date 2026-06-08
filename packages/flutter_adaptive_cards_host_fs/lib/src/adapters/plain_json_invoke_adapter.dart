import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/src/adapters/plain_json_invoke_response_parser.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_kind.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_request.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_response.dart';

/// Serializes [AdaptiveCardInvokeRequest] to flat JSON for custom flow-services.
class PlainJsonInvokeAdapter {
  const PlainJsonInvokeAdapter._();

  /// Serializes [request] to a POST body map.
  static Map<String, dynamic> toMap(AdaptiveCardInvokeRequest request) {
    return {
      'kind': request.kind.name,
      if (request.actionId != null) 'actionId': request.actionId,
      if (request.verb != null) 'verb': request.verb,
      if (request.data.isNotEmpty) 'data': request.data,
      if (request.inputId != null) 'inputId': request.inputId,
      if (request.value != null) 'value': request.value,
      if (request.dataQuery != null) 'dataQuery': request.dataQuery!.toJson(),
      if (request.url != null) 'url': request.url,
    };
  }

  /// Deserializes a POST body map into [AdaptiveCardInvokeRequest].
  static AdaptiveCardInvokeRequest requestFromMap(Map<String, dynamic> map) {
    final kindName = map['kind'] as String;
    final kind = AdaptiveCardInvokeKind.values.byName(kindName);
    DataQuery? dataQuery;
    final dq = map['dataQuery'];
    if (dq is Map<String, dynamic>) {
      dataQuery = DataQuery.fromJson(dq);
    }
    return AdaptiveCardInvokeRequest(
      kind: kind,
      actionId: map['actionId'] as String?,
      verb: map['verb'] as String?,
      data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
      inputId: map['inputId'] as String?,
      value: map['value'],
      dataQuery: dataQuery,
      url: map['url'] as String?,
    );
  }

  /// Parses a response JSON map using the PlainJson contract.
  static AdaptiveCardInvokeResponse responseFromMap(Map<String, dynamic> map) {
    return PlainJsonInvokeResponseParser.parse(map);
  }
}
