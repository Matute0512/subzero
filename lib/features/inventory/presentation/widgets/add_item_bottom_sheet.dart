import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/food_category.dart';
import '../../domain/entities/frozen_item.dart';
import 'category_icon_helper.dart';

/// Modal interactivo para registrar o editar alimentos en el congelador según el diseño de Figma.
/// Implementa un layout con botón inferior fijo (Sticky Action Button) que permanece
/// 100% visible y accionable por encima del teclado virtual del celular.
class AddItemBottomSheet extends StatefulWidget {
  final void Function(FrozenItem item) onSave;
  final FrozenItem? itemToEdit;

  const AddItemBottomSheet({
    super.key,
    required this.onSave,
    this.itemToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required void Function(FrozenItem item) onSave,
    FrozenItem? itemToEdit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => AddItemBottomSheet(
        onSave: onSave,
        itemToEdit: itemToEdit,
      ),
    );
  }

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  FoodCategory _selectedCategory = FoodCategory.redMeat;
  late DateTime _frozenDate;
  late DateTime _expirationDate;
  bool _reminderEnabled = true;

  bool get isEditing => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _nameController.text = item.name;
      _notesController.text = item.locationNotes ?? '';
      _quantityController.text = item.quantity % 1 == 0
          ? item.quantity.toInt().toString()
          : item.quantity.toString();
      _selectedCategory = item.category;
      _frozenDate = item.frozenDate;
      _expirationDate = item.expirationDate;
      _reminderEnabled = item.reminderEnabled;
    } else {
      _frozenDate = DateTime.now();
      _expirationDate = _calculateDefaultExpiration(_selectedCategory);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  DateTime _calculateDefaultExpiration(FoodCategory category) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .add(Duration(days: category.defaultShelfLifeDays));
  }

  void _onCategorySelected(FoodCategory category) {
    setState(() {
      _selectedCategory = category;
      if (!isEditing) {
        _expirationDate = _calculateDefaultExpiration(category);
      }
    });
  }

  void _setExpirationMonths(int months) {
    setState(() {
      final base = isEditing ? _frozenDate : DateTime.now();
      _expirationDate = DateTime(base.year, base.month + months, base.day);
    });
  }

  Future<void> _selectCustomExpirationDate() async {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final currentExp = DateUtils.dateOnly(_expirationDate);
    final minDate = today.subtract(const Duration(days: 365));
    final maxDate = today.add(const Duration(days: 365 * 10));

    final effectiveInitialDate = currentExp.isBefore(minDate)
        ? minDate
        : (currentExp.isAfter(maxDate) ? maxDate : currentExp);

    final picked = await showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: minDate,
      lastDate: maxDate,
      currentDate: today,
      initialDatePickerMode: DatePickerMode.day,
      initialEntryMode: DatePickerEntryMode.calendar,
      helpText: isEditing ? 'MODIFICAR CADUCIDAD' : 'FECHA DE CADUCIDAD',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final quantity = double.tryParse(_quantityController.text) ?? 1.0;
      final savedItem = FrozenItem(
        id: widget.itemToEdit?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        category: _selectedCategory,
        frozenDate: _frozenDate,
        expirationDate: _expirationDate,
        quantity: quantity,
        unit: widget.itemToEdit?.unit ?? 'unidad',
        locationNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isConsumed: widget.itemToEdit?.isConsumed ?? false,
        reminderEnabled: _reminderEnabled,
      );

      widget.onSave(savedItem);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - bottomInset;
    final suggestedMonths = (_selectedCategory.defaultShelfLifeDays / 30).round();

    return Padding(
      // Eleva todo el modal por encima del teclado virtual
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: availableHeight * 0.88,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppTheme.surfaceVariant, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Header Modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Modificar Alimento' : 'Congelar Alimento',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Contenido scrolleable (campos del formulario)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Campo de Nombre
                      TextFormField(
                        controller: _nameController,
                        autofocus: false,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Nombre del alimento (ej. Salmón rosado)',
                          hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                          filled: true,
                          fillColor: AppTheme.surface,
                          prefixIcon: const Icon(Icons.fastfood_outlined, color: AppTheme.secondaryAccent),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.surfaceVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.secondaryAccent, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.urgencyCriticalAccent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.urgencyCriticalAccent, width: 1.5),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa un nombre para el alimento.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Selector de Categoría (Carrusel de cards)
                      const Text(
                        'CATEGORÍA DE ALIMENTO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 68,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: FoodCategory.values.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final category = FoodCategory.values[index];
                            final isSelected = category == _selectedCategory;

                            return GestureDetector(
                              onTap: () => _onCategorySelected(category),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 62,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryAccent : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryAccent : AppTheme.surfaceVariant,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      category.icon,
                                      color: isSelected ? Colors.white : AppTheme.secondaryAccent,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      category.displayName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card de Caducidad Sugerida Automática
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.urgencySafeContainer,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.urgencySafeAccent.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.bolt, color: AppTheme.urgencySafeAccent, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        isEditing
                                            ? 'Fecha estimada de caducidad'
                                            : 'Caducidad sugerida automáticamente',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.urgencySafeAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isEditing
                                        ? dateFormat.format(_expirationDate)
                                        : '+$suggestedMonths meses (${dateFormat.format(_expirationDate)})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: _selectCustomExpirationDate,
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Text(
                                  'Cambiar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.secondaryAccent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Chips de selección rápida sin necesidad de navegar meses en el calendario
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildDurationChip(label: '+1 mes', months: 1),
                            const SizedBox(width: 8),
                            _buildDurationChip(label: '+3 meses', months: 3),
                            const SizedBox(width: 8),
                            _buildDurationChip(label: '+6 meses', months: 6),
                            const SizedBox(width: 8),
                            _buildDurationChip(label: '+1 año', months: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SwitchListTile estilizado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.surfaceVariant),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recordarme antes de vencer',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Alerta diaria a las 09:00 AM (7d y 1d antes)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _reminderEnabled,
                              activeTrackColor: AppTheme.secondaryAccent,
                              thumbColor: WidgetStateProperty.resolveWith<Color>(
                                (states) => states.contains(WidgetState.selected)
                                    ? AppTheme.backgroundDark
                                    : AppTheme.textSecondary,
                              ),
                              inactiveTrackColor: AppTheme.surfaceVariant,
                              onChanged: (val) {
                                setState(() {
                                  _reminderEnabled = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo Ubicación y Cantidad
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Cant. (1)',
                                filled: true,
                                fillColor: AppTheme.surface,
                                prefixIcon: const Icon(Icons.tag, color: AppTheme.textSecondary, size: 18),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.surfaceVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.secondaryAccent),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _notesController,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Ubicación (ej. Tupper azul, Cajón 2)',
                                hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                filled: true,
                                fillColor: AppTheme.surface,
                                prefixIcon: const Icon(Icons.place_outlined, color: AppTheme.textSecondary, size: 18),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.surfaceVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.secondaryAccent),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4. Sticky Bottom Action: Botón siempre visible y accesible por encima del teclado
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.primaryGlowShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _submit,
                    child: Center(
                      child: Text(
                        isEditing ? 'Guardar cambios' : 'Guardar en el congelador',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildDurationChip({required String label, required int months}) {
    final base = isEditing ? _frozenDate : DateTime.now();
    final targetDate = DateTime(base.year, base.month + months, base.day);
    final isSelected = DateUtils.isSameDay(_expirationDate, targetDate);

    return InkWell(
      onTap: () => _setExpirationMonths(months),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryAccent : AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppTheme.secondaryAccent : AppTheme.surfaceVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.backgroundDark : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
