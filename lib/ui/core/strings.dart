/// All user-facing text in one place (no i18n library on purpose).
abstract final class Strings {
  static const appTitle = 'Meal Finder';
  static const mealsTab = 'Meals';
  static const favouritesTab = 'Favourites';
  static const searchHint = 'Search meals';
  static const allCategories = 'All';
  static const retry = 'Retry';
  static const loading = 'Loading';
  static const offlineBanner = 'You are offline. Showing what is available.';
  static const emptyMeals = 'No meals found';
  static const emptyMealsHint = 'Try another search or category.';
  static const emptyFavourites = 'No favourites yet';
  static const emptyFavouritesHint = 'Tap the heart on a meal to save it here.';
  static const ingredients = 'Ingredients';
  static const instructions = 'Instructions';
  static const addFavourite = 'Add to favourites';
  static const removeFavourite = 'Remove from favourites';
  static const toggleTheme = 'Toggle theme';
  static const notFound = 'This meal does not exist';
  static const errorNetwork = 'No connection. Check your network and retry.';
  static const errorParse = 'The server sent data we could not read.';
  static const errorUnknown = 'Something went wrong.';
  static String errorServer(int? code) =>
      'The server had a problem${code == null ? '' : ' ($code)'}.';
}
