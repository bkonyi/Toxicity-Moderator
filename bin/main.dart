import 'dart:async';

import 'package:draw/draw.dart';
import '../lib/perspective.dart';

const String API_KEY = '';

const PERSPECTIVE_ATTRIBUTES = const <PerspectiveAttribute>[
  PerspectiveAttribute.SevereToxicity,
  PerspectiveAttribute.AttackOnAuthor,
  PerspectiveAttribute.AttackOnCommenter,
  PerspectiveAttribute.Inflammatory,
  PerspectiveAttribute.Spam,
];

Future main() async {
  PerspectiveRequester.SetApiKey(API_KEY);

  final reddit = await Reddit.createInstance(
      configUri: Uri.parse(r'bin/draw.ini'), siteName: 'Toxicity-Moderator');
  final subreddit = reddit.subreddit('WTF');
  final perspective = new PerspectiveRequester(PERSPECTIVE_ATTRIBUTES);

  await for (final comment in subreddit.stream.comments()) {
    final body = await comment.property('body');
    final perspectiveResult = await perspective.analyze(body);
    print(perspectiveResult);
  }
}
