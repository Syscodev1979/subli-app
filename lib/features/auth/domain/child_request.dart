/// Szülő által megadott gyermek, még összekapcsolás előtt.
class ChildRequest {
  const ChildRequest({required this.name, required this.birthDate});

  final String name;
  final DateTime birthDate;
}
