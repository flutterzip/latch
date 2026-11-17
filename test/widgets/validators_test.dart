import 'package:flutter_test/flutter_test.dart';
import 'package:latch/widgets/validators.dart';

void main() {
  test('email', () {
    expect(Check.email('hello@flutterzip.com'), isTrue);
    expect(Check.email(' a@b.co '), isTrue);
    expect(Check.email('a@b'), isFalse);
    expect(Check.email('no at sign.com'), isFalse);
  });

  test('password strength rewards length over symbols', () {
    expect(Check.password(''), 0);
    expect(Check.password('Ab1!'), 1);
    expect(Check.password('aaaaaaaaaaaaaaaa'), 1, reason: 'one repeated character never passes');
    expect(Check.password('abcdefgh'), 2);
    expect(Check.password('a lamp in the window'), 4);
    expect(Check.password('a lamp in the window'), greaterThan(Check.password('P@ss1!x9')));
  });
}
