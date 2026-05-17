import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/category_group.dart';
import '../../domain/entities/category_item.dart';

/// Default fallback groups used when the server is unreachable or returns an empty list.
/// IDs are canonical: sort_order + 1 (1-indexed, 1–143), matching migration 012.
const _fallbackGroups = <CategoryGroup>[
  CategoryGroup(group: 'Income', type: 'income', categories: [
    CategoryItem(id: 1, name: 'Paychecks'),
    CategoryItem(id: 2, name: 'Bonuses & Commissions'),
    CategoryItem(id: 3, name: 'Overtime'),
    CategoryItem(id: 4, name: 'Business Income / Revenue'),
    CategoryItem(id: 5, name: 'Freelance / Side Hustle Income'),
    CategoryItem(id: 6, name: 'Self-Employment Income'),
    CategoryItem(id: 7, name: 'Interest Income'),
    CategoryItem(id: 8, name: 'Dividends & Investment Income'),
    CategoryItem(id: 9, name: 'Rental Income'),
    CategoryItem(id: 10, name: 'Pension / Retirement Income'),
    CategoryItem(id: 11, name: 'Government Benefits (Social Security, etc.)'),
    CategoryItem(id: 12, name: 'Tax Refunds & Credits'),
    CategoryItem(id: 13, name: 'Reimbursements'),
    CategoryItem(id: 14, name: 'Gifts Received'),
    CategoryItem(id: 15, name: 'Alimony / Child Support Received'),
    CategoryItem(id: 16, name: 'Other Income'),
  ]),
  CategoryGroup(group: 'Housing', type: 'expense', categories: [
    CategoryItem(id: 17, name: 'Mortgage'),
    CategoryItem(id: 18, name: 'Rent'),
    CategoryItem(id: 19, name: 'Property Taxes'),
    CategoryItem(id: 20, name: 'HOA / Condo Fees'),
    CategoryItem(id: 21, name: 'Homeowners / Renters Insurance'),
    CategoryItem(id: 22, name: 'Home Maintenance & Repairs'),
    CategoryItem(id: 23, name: 'Home Improvement & Renovations'),
    CategoryItem(id: 24, name: 'Lawn Care & Landscaping'),
    CategoryItem(id: 25, name: 'Home Services (cleaning, pest control, etc.)'),
    CategoryItem(id: 26, name: 'Furniture & Housewares'),
    CategoryItem(id: 27, name: 'Appliances'),
  ]),
  CategoryGroup(group: 'Transportation', type: 'expense', categories: [
    CategoryItem(id: 28, name: 'Auto Loan / Lease Payment'),
    CategoryItem(id: 29, name: 'Gas & Fuel'),
    CategoryItem(id: 30, name: 'Auto Insurance'),
    CategoryItem(id: 31, name: 'Auto Maintenance & Repairs'),
    CategoryItem(id: 32, name: 'Tires & Auto Parts'),
    CategoryItem(id: 33, name: 'Car Wash & Detailing'),
    CategoryItem(id: 34, name: 'Parking & Tolls'),
    CategoryItem(id: 35, name: 'Vehicle Registration & DMV Fees'),
    CategoryItem(id: 36, name: 'Public Transit'),
    CategoryItem(id: 37, name: 'Taxi & Ride Shares'),
    CategoryItem(id: 38, name: 'Bike / Scooter Share Programs'),
    CategoryItem(id: 39, name: 'Roadside Assistance & Warranty'),
  ]),
  CategoryGroup(group: 'Utilities', type: 'expense', categories: [
    CategoryItem(id: 40, name: 'Electricity'),
    CategoryItem(id: 41, name: 'Natural Gas'),
    CategoryItem(id: 42, name: 'Water & Sewer'),
    CategoryItem(id: 43, name: 'Garbage & Recycling'),
    CategoryItem(id: 44, name: 'Internet'),
    CategoryItem(id: 45, name: 'Cable & Television'),
    CategoryItem(id: 46, name: 'Phone (Mobile & Landline)'),
    CategoryItem(id: 47, name: 'Streaming Subscriptions'),
    CategoryItem(id: 48, name: 'Subscriptions & Memberships'),
  ]),
  CategoryGroup(group: 'Food & Dining', type: 'expense', categories: [
    CategoryItem(id: 49, name: 'Groceries'),
    CategoryItem(id: 50, name: 'Restaurants & Bars'),
    CategoryItem(id: 51, name: 'Fast Food'),
    CategoryItem(id: 52, name: 'Coffee Shops & Cafes'),
    CategoryItem(id: 53, name: 'Food Delivery & Takeout'),
    CategoryItem(id: 54, name: 'Alcohol & Tobacco'),
    CategoryItem(id: 55, name: 'Snacks & Convenience Stores'),
  ]),
  CategoryGroup(group: 'Shopping', type: 'expense', categories: [
    CategoryItem(id: 56, name: 'Clothing & Apparel'),
    CategoryItem(id: 57, name: 'Shoes & Accessories'),
    CategoryItem(id: 58, name: 'Jewelry'),
    CategoryItem(id: 59, name: 'Electronics & Gadgets'),
    CategoryItem(id: 60, name: 'Books, Music & Media'),
    CategoryItem(id: 61, name: 'Household Supplies'),
    CategoryItem(id: 62, name: 'Tools & Hardware'),
  ]),
  CategoryGroup(group: 'Personal Care', type: 'expense', categories: [
    CategoryItem(id: 63, name: 'Toiletries & Personal Hygiene'),
    CategoryItem(id: 64, name: 'Beauty & Cosmetics'),
    CategoryItem(id: 65, name: 'Haircuts & Salon Services'),
    CategoryItem(id: 66, name: 'Spa, Massage & Wellness Treatments'),
    CategoryItem(id: 67, name: 'Dry Cleaning & Laundry'),
    CategoryItem(id: 68, name: 'Personal Care Services'),
  ]),
  CategoryGroup(group: 'Health & Wellness', type: 'expense', categories: [
    CategoryItem(id: 69, name: 'Health Insurance'),
    CategoryItem(id: 70, name: 'Medical & Doctor Visits'),
    CategoryItem(id: 71, name: 'Prescriptions & Medications'),
    CategoryItem(id: 72, name: 'Pharmacy / Over-the-Counter'),
    CategoryItem(id: 73, name: 'Dentist & Dental Care'),
    CategoryItem(id: 74, name: 'Vision Care / Eyeglasses / Contacts'),
    CategoryItem(id: 75, name: 'Therapy & Mental Health'),
    CategoryItem(id: 76, name: 'Hospital / Urgent Care / Emergency'),
    CategoryItem(id: 77, name: 'Medical Devices & Supplies'),
    CategoryItem(id: 78, name: 'Supplements & Vitamins'),
    CategoryItem(id: 79, name: 'Alternative Medicine'),
  ]),
  CategoryGroup(group: 'Fitness & Recreation', type: 'expense', categories: [
    CategoryItem(id: 80, name: 'Fitness / Gym Memberships'),
    CategoryItem(id: 81, name: 'Fitness Classes & Equipment'),
    CategoryItem(id: 82, name: 'Sports & Recreation'),
  ]),
  CategoryGroup(group: 'Travel & Vacation', type: 'expense', categories: [
    CategoryItem(id: 83, name: 'Travel & Vacation'),
    CategoryItem(id: 84, name: 'Flights & Airfare'),
    CategoryItem(id: 85, name: 'Hotels & Lodging'),
    CategoryItem(id: 86, name: 'Rental Cars & Travel Transportation'),
    CategoryItem(id: 87, name: 'Travel Meals & Activities'),
    CategoryItem(id: 88, name: 'Souvenirs & Travel Gifts'),
  ]),
  CategoryGroup(
      group: 'Entertainment & Lifestyle',
      type: 'expense',
      categories: [
        CategoryItem(id: 89, name: 'Entertainment & Recreation'),
        CategoryItem(id: 90, name: 'Movies, Theater & Concerts'),
        CategoryItem(id: 91, name: 'Video Games & Gaming'),
        CategoryItem(id: 92, name: 'Hobbies & Crafts'),
        CategoryItem(id: 93, name: 'Fun Money / Pocket Spending'),
        CategoryItem(id: 94, name: 'Sporting Events'),
      ]),
  CategoryGroup(group: 'Children & Family', type: 'expense', categories: [
    CategoryItem(id: 95, name: 'Childcare / Daycare'),
    CategoryItem(id: 96, name: "Children's Clothing & Shoes"),
    CategoryItem(id: 97, name: 'Child Activities / Sports / Lessons'),
    CategoryItem(id: 98, name: 'School Fees & Supplies'),
    CategoryItem(id: 99, name: 'Toys & Baby Supplies'),
    CategoryItem(id: 100, name: "Allowance / Kids' Spending"),
    CategoryItem(id: 101, name: 'Child Support / Alimony Paid'),
  ]),
  CategoryGroup(group: 'Education', type: 'expense', categories: [
    CategoryItem(id: 102, name: 'Student Loans'),
    CategoryItem(id: 103, name: 'Tuition & Education Fees'),
    CategoryItem(id: 104, name: 'Books & Educational Supplies'),
    CategoryItem(id: 105, name: 'Professional Development / Courses'),
  ]),
  CategoryGroup(group: 'Pets', type: 'expense', categories: [
    CategoryItem(id: 106, name: 'Pet Food & Supplies'),
    CategoryItem(id: 107, name: 'Veterinary Care & Pet Medical'),
    CategoryItem(id: 108, name: 'Pet Grooming & Boarding'),
    CategoryItem(id: 109, name: 'Pet Insurance'),
    CategoryItem(id: 110, name: 'Pet Toys & Accessories'),
  ]),
  CategoryGroup(group: 'Gifts & Donations', type: 'expense', categories: [
    CategoryItem(id: 111, name: 'Charity & Donations'),
    CategoryItem(id: 112, name: 'Religious Contributions'),
    CategoryItem(id: 113, name: 'Gifts Given'),
  ]),
  CategoryGroup(group: 'Financial & Debt', type: 'expense', categories: [
    CategoryItem(id: 114, name: 'Loan Repayment (Non-Auto/Student)'),
    CategoryItem(id: 115, name: 'Financial & Legal Services'),
    CategoryItem(id: 116, name: 'Financial Fees'),
    CategoryItem(id: 117, name: 'Bank & Credit Card Fees'),
    CategoryItem(id: 118, name: 'Investment Fees'),
    CategoryItem(id: 119, name: 'Cash & ATM Withdrawals'),
    CategoryItem(id: 120, name: 'Taxes (Income, Property, etc.)'),
    CategoryItem(id: 121, name: 'Accountant / Tax Preparation'),
  ]),
  CategoryGroup(group: 'Business Expenses', type: 'expense', categories: [
    CategoryItem(id: 122, name: 'Advertising & Promotion'),
    CategoryItem(id: 123, name: 'Business Utilities & Communication'),
    CategoryItem(id: 124, name: 'Employee Wages & Contract Labor'),
    CategoryItem(id: 125, name: 'Business Travel & Meals'),
    CategoryItem(id: 126, name: 'Business Auto Expenses'),
    CategoryItem(id: 127, name: 'Business Insurance'),
    CategoryItem(id: 128, name: 'Office Supplies & Expenses'),
    CategoryItem(id: 129, name: 'Office Rent'),
    CategoryItem(id: 130, name: 'Postage & Shipping'),
    CategoryItem(id: 131, name: 'Business Software & Tools'),
    CategoryItem(id: 132, name: 'Professional Services (legal, accounting)'),
    CategoryItem(id: 133, name: 'Business Licenses & Permits'),
    CategoryItem(id: 134, name: 'Marketing & Client Entertainment'),
  ]),
  CategoryGroup(
      group: 'Transfers & Adjustments',
      type: 'transfer',
      categories: [
        CategoryItem(id: 135, name: 'Internal Transfer'),
        CategoryItem(id: 136, name: 'Savings Contributions'),
        CategoryItem(id: 137, name: 'Investment Contributions'),
        CategoryItem(id: 138, name: 'Retirement Contributions'),
        CategoryItem(id: 139, name: 'Credit Card Payment'),
        CategoryItem(id: 140, name: 'Balance Adjustments'),
      ]),
  CategoryGroup(group: 'Other', type: 'expense', categories: [
    CategoryItem(id: 141, name: 'Uncategorized'),
    CategoryItem(id: 142, name: 'Check'),
    CategoryItem(id: 143, name: 'Miscellaneous'),
  ]),
];

class CategoriesNotifier extends StateNotifier<List<CategoryGroup>> {
  CategoriesNotifier(this._ref) : super(_fallbackGroups);

  final Ref _ref;

  Future<void> sync() async {
    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.get<List<dynamic>>('/api/categories');
      final fetched = (response.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CategoryGroup.fromJson)
          .where((g) => g.categories.isNotEmpty)
          .toList();
      if (fetched.isNotEmpty) {
        state = fetched;
      }
    } catch (_) {
      // Keep current (or fallback) list on failure
    }
  }

  void clear() {
    state = _fallbackGroups;
  }
}

/// Holds the full grouped category structure from the API.
final categoryGroupsProvider =
    StateNotifierProvider<CategoriesNotifier, List<CategoryGroup>>(
  (ref) => CategoriesNotifier(ref),
);

/// Derived flat list of all category names. Used by the filter sheet
/// and any widget that only needs display names.
final categoriesProvider = Provider<List<String>>(
  (ref) => ref
      .watch(categoryGroupsProvider)
      .expand((g) => g.categories.map((c) => c.name))
      .toList(),
);
