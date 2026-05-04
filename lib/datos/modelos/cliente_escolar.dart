class SchoolCity {
  final String id;
  final String name;

  const SchoolCity({
    required this.id,
    required this.name,
  });
}

class SchoolCustomer {
  final String id;
  final String cityId;
  final String name;
  final String address;
  final String phone;

  const SchoolCustomer({
    required this.id,
    required this.cityId,
    required this.name,
    required this.address,
    required this.phone,
  });
}
