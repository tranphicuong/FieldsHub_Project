import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterResult {
  final RangeValues priceRange;
  final RangeValues timeRange;
  final Set<String> selectedDistricts;
  final int selectedRating;

  const FilterResult({
    required this.priceRange,
    required this.timeRange,
    required this.selectedDistricts,
    required this.selectedRating,
  });
}

Future<FilterResult?> showFilterDialog({
  required BuildContext context,
  required RangeValues priceRange,
  required RangeValues timeRange,
  required Set<String> selectedDistricts,
  required int selectedRating,
}) {
  RangeValues tempPrice = priceRange;
  RangeValues tempTime = timeRange;
  Set<String> tempDistricts = Set.from(selectedDistricts);
  int tempRating = selectedRating;

  String formatMoney(double value) {
    return "${NumberFormat('#,###').format(value.toInt())} đ";
  }

  return showGeneralDialog<FilterResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Bộ lọc',
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, anim1, anim2) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.85,
            margin: const EdgeInsets.only(top: 40, bottom: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(-3, 3),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  children: [
                    // === Header ===
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 10),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Bộ lọc sân",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context, null),
                            icon: const Icon(Icons.close, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // === Nội dung chính ===
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Giá
                            Text(
                              "Giá (${formatMoney(tempPrice.start)} - ${formatMoney(tempPrice.end)})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            RangeSlider(
                              values: tempPrice,
                              min: 0,
                              max: 1000000,
                              divisions: 20,
                              activeColor: Colors.blue,
                              inactiveColor: Colors.grey[300],
                              labels: RangeLabels(
                                formatMoney(tempPrice.start),
                                formatMoney(tempPrice.end),
                              ),
                              onChanged: (val) =>
                                  setModalState(() => tempPrice = val),
                            ),
                            const SizedBox(height: 20),

                            // Giờ hoạt động
                            Text(
                              "Giờ hoạt động (${tempTime.start.toInt()}h - ${tempTime.end.toInt()}h)",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            RangeSlider(
                              values: tempTime,
                              min: 0,
                              max: 24,
                              divisions: 24,
                              activeColor: Colors.green,
                              inactiveColor: Colors.grey[300],
                              labels: RangeLabels(
                                "${tempTime.start.toInt()}h",
                                "${tempTime.end.toInt()}h",
                              ),
                              onChanged: (val) =>
                                  setModalState(() => tempTime = val),
                            ),
                            const SizedBox(height: 20),

                            // Khu vực
                            const Text(
                              "Khu vực",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  [
                                    'Thủ Đức',
                                    'Bình Thạnh',
                                    'Gò Vấp',
                                    'Quận 7',
                                    'Quận 8',
                                    'Tân Bình',
                                    'Phú Nhuận',
                                    'Tân Phú',
                                    'Quận 11',
                                    'Quận 12',
                                    'Quận 3',
                                    'Quận 10',
                                  ].map((d) {
                                    return FilterChip(
                                      label: Text(d),
                                      selected: tempDistricts.contains(d),
                                      selectedColor: Colors.blue.withOpacity(
                                        0.2,
                                      ),
                                      checkmarkColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: tempDistricts.contains(d)
                                              ? Colors.blue
                                              : Colors.grey[400]!,
                                        ),
                                      ),
                                      onSelected: (selected) {
                                        setModalState(() {
                                          if (selected) {
                                            tempDistricts.add(d);
                                          } else {
                                            tempDistricts.remove(d);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // Đánh giá
                            const Text(
                              "Đánh giá",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: List.generate(5, (i) {
                                final rating = i + 1;
                                final isSelected = tempRating == rating;
                                return FilterChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$rating'),
                                      const Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                    ],
                                  ),
                                  selected: isSelected,
                                  selectedColor: Colors.amber.withOpacity(0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? Colors.amber[700]!
                                          : Colors.grey[400]!,
                                    ),
                                  ),
                                  onSelected: (_) {
                                    setModalState(() {
                                      tempRating = isSelected ? 0 : rating;
                                    });
                                  },
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // === Footer ===
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setModalState(() {
                                  tempPrice = const RangeValues(0, 1000000);
                                  tempTime = const RangeValues(6, 22);
                                  tempDistricts.clear();
                                  tempRating = 0;
                                });

                                
                                Navigator.pop(
                                  context,
                                  const FilterResult(
                                    priceRange: RangeValues(0, 1000000),
                                    timeRange: RangeValues(6, 22),
                                    selectedDistricts: {},
                                    selectedRating: 0,
                                  ),
                                );
                              },
                              child: const Text(
                                "Thiết lập lại",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  FilterResult(
                                    priceRange: tempPrice,
                                    timeRange: tempTime,
                                    selectedDistricts: tempDistricts,
                                    selectedRating: tempRating,
                                  ),
                                );
                              },
                              child: const Text(
                                "Áp dụng",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(anim1),
        child: child,
      );
    },
  );
}
