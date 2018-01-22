import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

class PerspectiveFilter {
  PerspectiveFilter();
  bool shouldFilter(PerspectiveResponse response) {
    return false;
  }
}

class PerspectiveResponse {
  final String body;

  final List<PerspectiveAttribute> attributes;

  final Map _results;

  double get toxicity => _summaryScore(PerspectiveAttribute.Toxicity);

  double get severeToxicity =>
      _summaryScore(PerspectiveAttribute.SevereToxicity);

  double get toxicityFast => _summaryScore(PerspectiveAttribute.ToxicityFast);

  double get attackOnAuthor =>
      _summaryScore(PerspectiveAttribute.AttackOnAuthor);

  double get attackOnCommenter =>
      _summaryScore(PerspectiveAttribute.AttackOnCommenter);

  double get incoherent => _summaryScore(PerspectiveAttribute.Incoherent);

  double get inflammatory => _summaryScore(PerspectiveAttribute.Inflammatory);

  double get likelyToReject =>
      _summaryScore(PerspectiveAttribute.LikelyToReject);

  double get obscene => _summaryScore(PerspectiveAttribute.Obscene);

  double get spam => _summaryScore(PerspectiveAttribute.Spam);

  double get unsubstantial => _summaryScore(PerspectiveAttribute.Unsubstantial);

  PerspectiveResponse(
      String this.body, List<PerspectiveAttribute> this.attributes, Map results)
      : _results = results;

  double _summaryScore(PerspectiveAttribute attribute) =>
      _results['attributeScores']
              .containsKey(_perspectiveAttributeToString(attribute))
          ? _results['attributeScores']
                  [_perspectiveAttributeToString(attribute)]['summaryScore']
              ['value']
          : 0.0;

  void _toStringHelper(StringBuffer s, a, v) =>
      s.writeln('${_perspectiveAttributeToString(a)}: $v');

  String toString() {
    StringBuffer s = new StringBuffer();
    s.writeln('Body: $body');
    if (attributes.contains(PerspectiveAttribute.Toxicity))
      _toStringHelper(s, PerspectiveAttribute.Toxicity, toxicity);
    if (attributes.contains(PerspectiveAttribute.SevereToxicity))
      _toStringHelper(s, PerspectiveAttribute.SevereToxicity, severeToxicity);
    if (attributes.contains(PerspectiveAttribute.ToxicityFast))
      _toStringHelper(s, PerspectiveAttribute.ToxicityFast, toxicityFast);
    if (attributes.contains(PerspectiveAttribute.AttackOnAuthor))
      _toStringHelper(s, PerspectiveAttribute.AttackOnAuthor, attackOnAuthor);
    if (attributes.contains(PerspectiveAttribute.AttackOnCommenter))
      _toStringHelper(
          s, PerspectiveAttribute.AttackOnCommenter, attackOnCommenter);
    if (attributes.contains(PerspectiveAttribute.Incoherent))
      _toStringHelper(s, PerspectiveAttribute.Incoherent, incoherent);
    if (attributes.contains(PerspectiveAttribute.Inflammatory))
      _toStringHelper(s, PerspectiveAttribute.Inflammatory, inflammatory);
    if (attributes.contains(PerspectiveAttribute.LikelyToReject))
      _toStringHelper(s, PerspectiveAttribute.LikelyToReject, likelyToReject);
    if (attributes.contains(PerspectiveAttribute.Obscene))
      _toStringHelper(s, PerspectiveAttribute.Obscene, obscene);
    if (attributes.contains(PerspectiveAttribute.Spam))
      _toStringHelper(s, PerspectiveAttribute.Spam, spam);
    if (attributes.contains(PerspectiveAttribute.Unsubstantial))
      _toStringHelper(s, PerspectiveAttribute.Unsubstantial, unsubstantial);
    return s.toString();
  }
}

enum PerspectiveAttribute {
  Toxicity,
  SevereToxicity,
  ToxicityFast,
  AttackOnAuthor,
  AttackOnCommenter,
  Incoherent,
  Inflammatory,
  LikelyToReject,
  Obscene,
  Spam,
  Unsubstantial,
}

String _perspectiveAttributeToString(PerspectiveAttribute a) {
  switch (a) {
    case PerspectiveAttribute.Toxicity:
      return "TOXICITY";
    case PerspectiveAttribute.SevereToxicity:
      return "SEVERE_TOXICITY";
    case PerspectiveAttribute.ToxicityFast:
      return "TOXICITY_FAST";
    case PerspectiveAttribute.AttackOnAuthor:
      return "ATTACK_ON_AUTHOR";
    case PerspectiveAttribute.AttackOnCommenter:
      return "ATTACK_ON_COMMENTER";
    case PerspectiveAttribute.Incoherent:
      return "INCOHERENT";
    case PerspectiveAttribute.Inflammatory:
      return "INFLAMMATORY";
    case PerspectiveAttribute.LikelyToReject:
      return "LIKELY_TO_REJECT";
    case PerspectiveAttribute.Obscene:
      return "OBSCENE";
    case PerspectiveAttribute.Spam:
      return "SPAM";
    case PerspectiveAttribute.Unsubstantial:
      return "UNSUBSTANTIAL";
    default:
      throw new ArgumentError('Invalid PerspectiveAttribute: $a');
  }
}

class PerspectiveRequester {
  static String _API_KEY;
  static const String _API_ENDPOINT =
      "https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze?key=";

  final List<PerspectiveAttribute> _attributes = <PerspectiveAttribute>[];

  static void SetApiKey(String key) => _API_KEY = key;

  void addAttribute(PerspectiveAttribute attribute) =>
      _attributes.add(attribute);

  void clearAttributes() => _attributes.clear();

  PerspectiveRequester([List<PerspectiveAttribute> attributes]) {
    _attributes.addAll(attributes);
  }

  Future<PerspectiveResponse> analyze(String body) async {
    final request = {
      "comment": {"text": body},
      "languages": ["en"],
    };

    Map requestAttributes = {};
    _attributes.forEach((attribute) {
      requestAttributes[_perspectiveAttributeToString(attribute)] = {};
    });
    request["requestedAttributes"] = requestAttributes;

    final response =
        await post(_API_ENDPOINT + _API_KEY, body: JSON.encode(request));
    final results = JSON.decode(response.body);
    return new PerspectiveResponse(body, _attributes, results);
  }
}
