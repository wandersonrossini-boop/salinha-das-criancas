String stripEmojis(String input) {
  // Regex to match emojis, symbols, and pictographs
  // This is a comprehensive regex that matches almost all emojis.
  final RegExp emojiRegex = RegExp(
      r'[\p{Emoji_Presentation}\p{Extended_Pictographic}]',
      unicode: true);
      
  return input.replaceAll(emojiRegex, '');
}
