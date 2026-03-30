import 'package:flutter/widgets.dart';

import '../main.dart' show AppView;

Widget sectionBodyForView(
  AppView view, {
  required Widget dashboard,
  required Widget services,
  required Widget learning,
  required Widget learningAdmin,
  required Widget space,
  required Widget privateSpace,
  required Widget publicSpace,
  required Widget profile,
  required Widget postDetail,
  required Widget levels,
  required Widget blockchain,
  required Widget friends,
  required Widget chat,
}) {
  switch (view) {
    case AppView.dashboard:
      return profile;
    case AppView.services:
      return services;
    case AppView.learning:
      return learning;
    case AppView.learningAdmin:
      return learningAdmin;
    case AppView.space:
    case AppView.privateSpace:
    case AppView.publicSpace:
      return space;
    case AppView.profile:
      return profile;
    case AppView.postDetail:
      return postDetail;
    case AppView.levels:
      return levels;
    case AppView.blockchain:
      return blockchain;
    case AppView.friends:
      return friends;
    case AppView.chat:
      return chat;
  }
}
