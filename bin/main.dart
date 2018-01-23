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

Map<PerspectiveAttribute, double> buildThresholdMap() {
  final thresholds = <PerspectiveAttribute, double>{};
  PERSPECTIVE_ATTRIBUTES.forEach((a) {
    thresholds[a] = 0.9;
  });
  return thresholds;
}

Future main() async {
  PerspectiveRequester.setApiKey(API_KEY);

  // Create a Reddit instance using DRAW. This simple method pulls account
  // credential information from `bin/draw.ini` and determines which type of
  // authentication to use. In this case `draw.ini` contains a username and
  // password, a client ID and secret, and a user agent, all of which are needed
  // for a non-trivial Reddit bot.
  final reddit = await Reddit.createInstance(
      configUri: Uri.parse('bin/draw.ini'), siteName: 'Toxicity-Moderator');

  // Here we create a Subreddit object for r/MorbidReality, which contains methods
  // that allow for navigation of a Reddit community. In this example, we will be
  // using the comment stream functionality to be notified of new comments as
  // they are posted.
  final subreddit = reddit.subreddit('MorbidReality');

  final perspective = new PerspectiveRequester(PERSPECTIVE_ATTRIBUTES);
  final perspectiveFilter = new PerspectiveFilter(buildThresholdMap());

  // Using the stream functionality, we can see comments in real-time as they
  // come in and pass them to the Perspective service for analysis.
  await for (final comment in subreddit.stream.comments()) {
    final body = await comment.property('body');
    final perspectiveResult = await perspective.analyze(body);

    // If a comment's score in a particular attribute exceeds the predetermined
    // threshold, we send a report to the subreddit moderators using the original
    // comment object.
    if (perspectiveFilter.shouldFilter(perspectiveResult)) {
      final reason = perspectiveFilter.lastFilterReason;
      final threshold = perspectiveFilter.attributeThreshold(reason);
      final reasonStr = perspectiveAttributeToString(reason);
      final score = perspectiveResult.summaryScore(reason);
      final reportMessage = 'Comment flagged for $reasonStr '
        '($score >= $threshold, github.com/bkonyi/Toxicity-Moderator)';

      // DRAW makes reporting this comment easy!
      await comment.report(reportMessage);

      // Informative print statements. Nothing to see here.
      print(reportMessage);
      print(perspectiveResult);
    }
  }
}
