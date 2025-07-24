import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';

// --- МОДЕЛИ ДАННЫХ ---
enum PartType { body, weapon, gadget }

class Part {
  final String id;
  final String name;
  final String imagePath;
  final PartType type;
  final int health;
  final int energy;
  final int power;

  Part({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.type,
    this.health = 0,
    this.energy = 0,
    this.power = 0,
  });
}

class VehicleSlot {
  final Vector2 position;
  final PartType allowedPartType;
  Part? attachedPart;

  VehicleSlot({required this.position, required this.allowedPartType, this.attachedPart});
}

// --- ОСНОВНОЕ ПРИЛОЖЕНИЕ ---
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ConstructorScreen(),
  ));
}

// --- ЭКРАН КОНСТРУКТОРА ---
class ConstructorScreen extends StatefulWidget {
  const ConstructorScreen({Key? key}) : super(key: key);

  @override
  _ConstructorScreenState createState() => _ConstructorScreenState();
}

class _ConstructorScreenState extends State<ConstructorScreen> {
  // --- СОСТОЯНИЕ ЭКРАНА ---

  final Map<String, Part> allParts = {
    'titan_body': Part(id: 'titan_body', name: 'Титан', imagePath: 'titan_body.png', type: PartType.body, health: 216, energy: 10),
    'scout_body': Part(id: 'scout_body', name: 'Проныра', imagePath: 'scout_body.png', type: PartType.body, health: 54, energy: 6),
    'rocket_launcher': Part(id: 'rocket_launcher', name: 'Ракетница', imagePath: 'rocket.png', type: PartType.weapon, power: 25),
    'drill': Part(id: 'drill', name: 'Пила', imagePath: 'drill.png', type: PartType.weapon, power: 18),
  };

  late List<Part> inventory;
  late Part currentBody;
  late List<VehicleSlot> currentSlots;

  // **НОВОЕ**: Отслеживаем, над каким слотом находится курсор
  int? _hoveredSlotIndex;

  @override
  void initState() {
    super.initState();
    inventory = allParts.values.toList();
    _selectBody('titan_body');
  }

  // --- ЛОГИКА ---

  void _selectBody(String bodyId) {
    setState(() {
      currentBody = allParts[bodyId]!;
      if (bodyId == 'titan_body') {
        currentSlots = [
          VehicleSlot(position: Vector2(-80, 0), allowedPartType: PartType.weapon),
          VehicleSlot(position: Vector2(70, 20), allowedPartType: PartType.weapon),
          VehicleSlot(position: Vector2(0, -60), allowedPartType: PartType.gadget),
        ];
      } else if (bodyId == 'scout_body') {
        currentSlots = [
          VehicleSlot(position: Vector2(-60, -25), allowedPartType: PartType.weapon),
          VehicleSlot(position: Vector2(50, 10), allowedPartType: PartType.gadget),
        ];
      }
    });
  }

  void _attachPart(Part part, int slotIndex) {
    setState(() {
      currentSlots[slotIndex].attachedPart = part;
    });
  }

  int get totalHealth => currentBody.health + currentSlots.fold(0, (sum, slot) => sum + (slot.attachedPart?.health ?? 0));
  int get totalPower => currentBody.power + currentSlots.fold(0, (sum, slot) => sum + (slot.attachedPart?.power ?? 0));

  // --- ВИДЖЕТЫ UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[800],
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              children: [
                _buildBodySelectionPanel(),
                Expanded(child: _buildVehicleArea()),
                _buildInventoryPanel(),
              ],
            ),
          ),
          _buildStatsBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 50,
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Text(
          'КОНСТРУКТОР',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBodySelectionPanel() {
    return Container(
      width: 120,
      color: Colors.black.withOpacity(0.4),
      child: ListView(
        children: inventory.where((p) => p.type == PartType.body).map((part) {
          bool isSelected = part.id == currentBody.id;
          return GestureDetector(
            onTap: () => _selectBody(part.id),
            child: Card(
              color: isSelected ? Colors.orange.withOpacity(0.5) : Colors.grey[800],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Image.asset('assets/images/${part.imagePath}', width: 80, height: 80),
                    Text(part.name, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInventoryPanel() {
    return Container(
      width: 120,
      color: Colors.black.withOpacity(0.4),
      child: ListView(
        children: inventory.where((p) => p.type != PartType.body).map((part) {
          return Draggable<Part>(
            data: part,
            feedback: Opacity(
              opacity: 0.8,
              child: Image.asset('assets/images/${part.imagePath}', width: 80, height: 80),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: Card(color: Colors.grey[800], child: Image.asset('assets/images/${part.imagePath}', width: 80, height: 80)),
            ),
            child: Card(
              color: Colors.grey[800],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Image.asset('assets/images/${part.imagePath}', width: 80, height: 80),
                    Text(part.name, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // **ИЗМЕНЕНО**: Центральная область с анимацией слотов
  Widget _buildVehicleArea() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/images/${currentBody.imagePath}', width: 300, height: 200),
          ...List.generate(currentSlots.length, (i) {
            final slot = currentSlots[i];
            final isHovered = _hoveredSlotIndex == i;

            // **НОВОЕ**: Используем AnimatedContainer для плавных переходов
            final double scale = isHovered ? 1.25 : 1.0; // Увеличиваем на 25%
            final Color color = isHovered ? Colors.green.withOpacity(0.7) : Colors.black.withOpacity(0.3);

            return Positioned(
              left: (MediaQuery.of(context).size.width - 300) / 2 + 150 + slot.position.x - (isHovered ? 31.25 : 25), // Центрируем увеличенный слот
              top: (MediaQuery.of(context).size.height - 400) / 2 + 100 + slot.position.y - (isHovered ? 31.25 : 25),
              child: DragTarget<Part>(
                onWillAccept: (part) => part != null && part.type == slot.allowedPartType,
                onAccept: (part) {
                  setState(() {
                    _attachPart(part, i);
                    _hoveredSlotIndex = null; // Сбрасываем подсветку
                  });
                },
                // **НОВОЕ**: Отслеживаем, когда деталь входит и покидает зону
                onMove: (details) {
                  setState(() {
                    _hoveredSlotIndex = i;
                  });
                },
                onLeave: (part) {
                  setState(() {
                    _hoveredSlotIndex = null;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  if (slot.attachedPart != null) {
                    return Image.asset('assets/images/${slot.attachedPart!.imagePath}', width: 50, height: 50);
                  }
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200), // Скорость анимации
                    curve: Curves.easeInOut,
                    width: isHovered ? 62.5 : 50, // Увеличенные размеры
                    height: isHovered ? 62.5 : 50,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: Colors.white.withOpacity(0.5), size: isHovered ? 30 : 24),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite, color: Colors.red, size: 24),
          const SizedBox(width: 8),
          Text('$totalHealth', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(width: 48),
          const Icon(Icons.flash_on, color: Colors.yellow, size: 24),
          const SizedBox(width: 8),
          Text('${currentBody.energy}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(width: 48),
          const Icon(Icons.whatshot, color: Colors.orange, size: 24),
          const SizedBox(width: 8),
          Text('$totalPower', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}