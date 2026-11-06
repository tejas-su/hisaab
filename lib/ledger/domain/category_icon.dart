/// The curated icon keys a category of the user's own can carry, and the word table that
/// suggests one from its name (SPEC BR-11, D138).
///
/// Keys are app-owned and stored in `categories.icon_key`; the presentation layer maps each to
/// a glyph. A shipped key never changes meaning, so keys are only ever added.
abstract final class CategoryIcon {
  /// The key used when no word in the name matches.
  static const String fallback = 'tag';

  // why: order matters. The first entry with a word in the name wins, so "Car service" is a
  // car and "Shaadi gift" a gift. Multi-word phrases are matched as whole phrases.
  static const List<(String, List<String>)> _table = <(String, List<String>)>[
    ('groceries', <String>['grocery', 'groceries', 'kirana', 'ration', 'dmart', 'blinkit', 'zepto', 'bigbasket', 'instamart']),
    ('vegetables', <String>['sabzi', 'sabji', 'vegetables', 'veggies', 'bhaji']),
    ('fruit', <String>['fruit', 'fruits', 'phal', 'apple', 'banana', 'mango']),
    ('milk', <String>['milk', 'doodh', 'dairy', 'curd', 'dahi']),
    ('chai', <String>['chai', 'tea', 'cutting']),
    ('coffee', <String>['coffee', 'cafe', 'starbucks']),
    ('snacks', <String>['snacks', 'nashta', 'samosa', 'chips', 'namkeen', 'chaat', 'vada pav', 'pani puri']),
    ('eating_out', <String>['eating out', 'swiggy', 'zomato', 'restaurant', 'dinner', 'lunch', 'biryani', 'pizza', 'burger', 'dhaba']),
    ('cigarettes', <String>['cigarette', 'cigarettes', 'cig', 'cigs', 'smoke', 'smoking', 'sutta', 'beedi', 'bidi', 'gutka', 'gutkha', 'tobacco', 'khaini', 'vape']),
    ('beer', <String>['beer', 'beers', 'kingfisher', 'bira']),
    ('cold_drink', <String>['cold drink', 'soft drink', 'soda', 'coke', 'pepsi', 'thums up', 'juice']),
    ('drinks', <String>['drinks', 'daru', 'alcohol', 'liquor', 'whisky', 'whiskey', 'rum', 'vodka', 'wine', 'bar', 'pub', 'theka', 'peg']),
    ('sweets', <String>['sweets', 'mithai', 'chocolate', 'ice cream', 'dessert', 'candy']),
    ('gaming', <String>['gaming', 'game', 'games', 'bgmi', 'pubg', 'playstation', 'xbox', 'steam']),
    ('cards', <String>['cards', 'rummy', 'teen patti', 'poker']),
    ('lottery', <String>['lottery', 'raffle']),
    ('paan', <String>['paan', 'pan', 'meetha paan']),
    ('hookah', <String>['hookah', 'hukka', 'sheesha', 'shisha']),
    ('fuel', <String>['petrol', 'diesel', 'fuel', 'cng', 'pump']),
    ('auto', <String>['auto', 'rickshaw', 'tuk tuk']),
    ('cab', <String>['cab', 'ola', 'uber', 'rapido', 'taxi']),
    ('bike', <String>['bike', 'scooter', 'scooty', 'activa']),
    ('car', <String>['car', 'fastag', 'toll']),
    ('metro', <String>['metro']),
    ('train', <String>['train', 'local', 'irctc', 'railway']),
    ('parking', <String>['parking']),
    ('trip', <String>['trip', 'holiday', 'flight', 'vacation', 'tour']),
    ('kids', <String>['kids', 'kid', 'baby', 'child', 'children', 'diapers', 'bachche', 'toys']),
    ('school', <String>['school', 'tuition', 'coaching', 'college', 'fees', 'stationery']),
    ('family', <String>['family', 'parents', 'mom', 'mummy', 'dad', 'papa']),
    ('pet', <String>['pet', 'pets', 'dog', 'cat', 'puppy']),
    ('cleaning', <String>['cleaning', 'maid', 'bai', 'cleaner', 'housekeeping']),
    ('laundry', <String>['laundry', 'dhobi', 'ironing', 'press', 'dry clean']),
    ('repair', <String>['repair', 'service', 'plumber', 'electrician', 'mechanic']),
    ('plants', <String>['plants', 'plant', 'garden', 'nursery']),
    ('medicine', <String>['medicine', 'medicines', 'pharmacy', 'chemist', 'dawai', 'tablets']),
    ('gym', <String>['gym', 'fitness', 'workout', 'protein']),
    ('yoga', <String>['yoga', 'meditation']),
    ('salon', <String>['salon', 'haircut', 'parlour', 'parlor', 'beauty', 'grooming', 'personal care', 'barber']),
    ('prayer', <String>['pooja', 'puja', 'mandir', 'temple', 'church', 'masjid', 'gurudwara', 'prasad']),
    ('giving', <String>['donation', 'charity', 'daan', 'tip']),
    ('gift', <String>['gift', 'gifts', 'birthday', 'shagun']),
    ('wedding', <String>['wedding', 'shaadi', 'marriage']),
    ('clothes', <String>['clothes', 'kapde', 'shirt', 'saree', 'kurta']),
    ('shoes', <String>['shoes', 'chappal', 'sandals', 'sneakers']),
    ('jewellery', <String>['jewellery', 'jewelry', 'gold', 'earrings', 'ring']),
    ('phone', <String>['phone', 'mobile', 'accessories']),
    ('recharge', <String>['recharge', 'data', 'jio', 'airtel', 'vi', 'sim']),
    ('movies', <String>['movie', 'movies', 'cinema', 'film', 'netflix', 'hotstar', 'ott']),
    ('books', <String>['books', 'book', 'kindle', 'novel', 'newspaper']),
    (fallback, <String>[]),
  ];

  /// Every curated key, in the icon step's order, ending with [fallback].
  static final List<String> keys = <String>[for (final (String key, List<String> _) in _table) key];

  /// The key whose words appear in [name]: the first match in the table, or [fallback].
  ///
  /// Words match whole, ignoring case, punctuation and extra spaces; names typed in other
  /// scripts fall back, since the table holds Latin-script words only.
  static String forName(String name) {
    final String padded = ' ${name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), ' ').trim()} ';
    return _table
        .firstWhere(
          ((String, List<String>) entry) => entry.$2.any((String word) => padded.contains(' $word ')),
          orElse: () => (fallback, const <String>[]),
        )
        .$1;
  }
}
