import 'package:flutter_showcase/domain/models/meal.dart';

const pasta = Meal(
  id: '1',
  name: 'Spaghetti Bolognese',
  thumbnailUrl: 'https://example.com/pasta.jpg',
  category: 'Pasta',
  area: 'Italian',
);

const curry = Meal(
  id: '2',
  name: 'Chicken Curry',
  thumbnailUrl: 'https://example.com/curry.jpg',
  category: 'Chicken',
  area: 'Indian',
);

const pastaDetail = Meal(
  id: '1',
  name: 'Spaghetti Bolognese',
  thumbnailUrl: 'https://example.com/pasta.jpg',
  category: 'Pasta',
  area: 'Italian',
  instructions: 'Boil the pasta.\nAdd the sauce.',
  ingredients: [
    Ingredient(name: 'Spaghetti', measure: '200g'),
    Ingredient(name: 'Tomato', measure: '3'),
  ],
  tags: ['Meat'],
);

/// A raw TheMealDB payload, including the flattened ingredient fields.
Map<String, dynamic> mealJson({String id = '1', String name = 'Pasta'}) => {
  'idMeal': id,
  'strMeal': name,
  'strMealThumb': 'https://example.com/$id.jpg',
  'strCategory': 'Pasta',
  'strArea': 'Italian',
  'strInstructions': 'Step one.\r\nStep two.',
  'strTags': 'Meat, Casserole,',
  'strIngredient1': 'Spaghetti',
  'strMeasure1': '200g',
  'strIngredient2': ' Tomato ',
  'strMeasure2': null,
  'strIngredient3': '',
  'strMeasure3': ' ',
  'strIngredient4': null,
};
