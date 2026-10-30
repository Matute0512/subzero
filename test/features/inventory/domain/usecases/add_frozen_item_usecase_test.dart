import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subzero/core/errors/failures.dart';
import 'package:subzero/features/inventory/domain/entities/food_category.dart';
import 'package:subzero/features/inventory/domain/entities/frozen_item.dart';
import 'package:subzero/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:subzero/features/inventory/domain/usecases/add_frozen_item_usecase.dart';
import 'package:subzero/features/inventory/domain/usecases/update_frozen_item_usecase.dart';

class MockInventoryRepository extends Mock implements IInventoryRepository {}

void main() {
  late MockInventoryRepository mockRepository;
  late AddFrozenItemUseCase addUseCase;
  late UpdateFrozenItemUseCase updateUseCase;

  final now = DateTime.now();
  final validItem = FrozenItem(
    id: 'test-1',
    name: 'Carne picada',
    category: FoodCategory.redMeat,
    frozenDate: now,
    expirationDate: now.add(const Duration(days: 90)),
    quantity: 2.0,
    unit: 'kg',
    locationNotes: 'Cajón 1, tupper azul',
  );

  setUpAll(() {
    registerFallbackValue(validItem);
  });

  setUp(() {
    mockRepository = MockInventoryRepository();
    addUseCase = AddFrozenItemUseCase(mockRepository);
    updateUseCase = UpdateFrozenItemUseCase(mockRepository);

    when(() => mockRepository.saveItem(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => mockRepository.updateItem(any()))
        .thenAnswer((_) async => const Right(unit));
  });

  group('AddFrozenItemUseCase Security & Validation', () {
    test('guarda exitosamente un ítem válido', () async {
      final result = await addUseCase(validItem);
      expect(result.isRight(), isTrue);
      verify(() => mockRepository.saveItem(validItem)).called(1);
    });

    test('rechaza nombres vacíos o solo espacios', () async {
      final invalid = validItem.copyWith(name: '   ');
      final result = await addUseCase(invalid);
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Debería fallar'),
      );
      verifyNever(() => mockRepository.saveItem(any()));
    });

    test('rechaza nombres que superen los 100 caracteres', () async {
      final invalid = validItem.copyWith(name: 'A' * 101);
      final result = await addUseCase(invalid);
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockRepository.saveItem(any()));
    });

    test('rechaza cantidad <= 0', () async {
      final invalid = validItem.copyWith(quantity: 0);
      final result = await addUseCase(invalid);
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockRepository.saveItem(any()));
    });

    test('rechaza cantidades mayores al límite máximo permitido (999999)', () async {
      final invalid = validItem.copyWith(quantity: 1000000);
      final result = await addUseCase(invalid);
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockRepository.saveItem(any()));
    });

    test('rechaza ubicación y notas mayores a 300 caracteres', () async {
      final invalid = validItem.copyWith(locationNotes: 'C' * 301);
      final result = await addUseCase(invalid);
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockRepository.saveItem(any()));
    });

    test('rechaza unidades mayores a 30 caracteres', () async {
      final invalid = validItem.copyWith(unit: 'U' * 31);
      final result = await addUseCase(invalid);
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockRepository.saveItem(any()));
    });
  });

  group('UpdateFrozenItemUseCase Security & Validation', () {
    test('actualiza exitosamente un ítem válido', () async {
      final result = await updateUseCase(validItem);
      expect(result.isRight(), isTrue);
      verify(() => mockRepository.updateItem(validItem)).called(1);
    });

    test('rechaza actualización con nombre mayor a 100 caracteres', () async {
      final invalid = validItem.copyWith(name: 'X' * 101);
      final result = await updateUseCase(invalid);
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockRepository.updateItem(any()));
    });
  });
}
