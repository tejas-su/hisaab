/// How the icon step groups the curated category icons, in order (D138, UI_DESIGN §5.3).
///
/// Group keys name a heading in `categoryIconGroup`; icon keys are `CategoryIcon.keys`.
abstract final class CategoryIconGroups {
  static const List<(String, List<String>)> all = <(String, List<String>)>[
    ('food', <String>['groceries', 'vegetables', 'fruit', 'milk', 'chai', 'coffee', 'snacks', 'eating_out']),
    ('habits', <String>['cigarettes', 'beer', 'cold_drink', 'drinks', 'sweets', 'gaming', 'cards', 'lottery', 'paan', 'hookah']),
    ('around', <String>['fuel', 'auto', 'cab', 'bike', 'car', 'metro', 'train', 'parking', 'trip']),
    ('home', <String>['kids', 'school', 'family', 'pet', 'cleaning', 'laundry', 'repair', 'plants']),
    ('care', <String>['medicine', 'gym', 'yoga', 'salon', 'prayer', 'giving', 'gift', 'wedding']),
    ('things', <String>['clothes', 'shoes', 'jewellery', 'phone', 'recharge', 'movies', 'books', 'tag']),
  ];
}
