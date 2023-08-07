
enum LessonsCount {
  all,
  thisMonth,
  author,
}

enum UserChatState {
  authorCommands,
  lessonCommands,
  faqCommands,
  normalMode,
  all,
}

Map<String, Map<String, dynamic>> userChatStates = {
  // number : {
  //    state: UserChatState,
  //    lsId: String,
  // }
};

String formate(DateTime? dateTime) {
  if (dateTime == null) return 'Unknown';
  return '${dateTime.year}/'
      '${dateTime.month}/'
      '${dateTime.day} '
      '${dateTime.hour}:'
      '${dateTime.minute}';
}