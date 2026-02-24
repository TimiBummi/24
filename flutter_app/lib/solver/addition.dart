import 'operation.dart';

class Addition implements Operation {
  const Addition();

  @override
  double calc(double a, double b) => a + b;

  @override
  String format(String a, String b) => '$a+$b';

  @override
  bool get isCommutative => true;

  @override
  int get priority => 0;
}
