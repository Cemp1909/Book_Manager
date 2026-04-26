class CompanySettings {
  final String companyName;
  final String currencySymbol;
  final int lowStockLimit;

  const CompanySettings({
    required this.companyName,
    required this.currencySymbol,
    required this.lowStockLimit,
  });

  static const defaults = CompanySettings(
    companyName: 'Editorial Manager',
    currencySymbol: r'$',
    lowStockLimit: 10,
  );

  CompanySettings copyWith({
    String? companyName,
    String? currencySymbol,
    int? lowStockLimit,
  }) {
    return CompanySettings(
      companyName: companyName ?? this.companyName,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      lowStockLimit: lowStockLimit ?? this.lowStockLimit,
    );
  }
}
