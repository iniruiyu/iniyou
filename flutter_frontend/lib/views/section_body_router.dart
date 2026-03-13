import 'package:flutter/widgets.dart';

import '../main.dart' show AppView;

Widget sectionBodyForView(
  AppView view, {
  required Widget dashboard,
  required Widget privateSpace,
  required Widget publicSpace,
  required Widget profile,
  required Widget postDetail,
  required Widget levels,
  required Widget subscription,
  required Widget blockchain,
  required Widget friends,
  required Widget chat,
}) {
  switch (view) {
    case AppView.dashboard:
      return dashboard;
    case AppView.privateSpace:
      return privateSpace;
    case AppView.publicSpace:
      return publicSpace;
    case AppView.profile:
      return profile;
    case AppView.postDetail:
      return postDetail;
    case AppView.levels:
      return levels;
    case AppView.subscription:
      return subscription;
    case AppView.blockchain:
      return blockchain;
    case AppView.friends:
      return friends;
    case AppView.chat:
      return chat;
  }
}
