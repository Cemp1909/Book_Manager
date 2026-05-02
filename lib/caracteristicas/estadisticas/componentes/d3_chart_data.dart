enum D3ChartKind { donut, bars, bubble }

class D3ChartDatum {
  final String label;
  final num value;
  final String color;
  final num? secondaryValue;
  final num? size;
  final String? detail;

  const D3ChartDatum({
    required this.label,
    required this.value,
    required this.color,
    this.secondaryValue,
    this.size,
    this.detail,
  });

  Map<String, Object> toJson() {
    return {
      'label': label,
      'value': value,
      'color': color,
      if (secondaryValue != null) 'secondaryValue': secondaryValue!,
      if (size != null) 'size': size!,
      if (detail != null) 'detail': detail!,
    };
  }
}
