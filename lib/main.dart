import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

enum PartType { body, weapon, wheel }

class Part {
  final String id;
  final String name;
  final String imagePath;
  final PartType type;
  final int health;
  final int energy;
  final int power;
  final int starLevel; // 1-5 звезд

  Part({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.type,
    this.health = 0,
    this.energy = 0,
    this.power = 0,
    this.starLevel = 1,
  });
}

class Vehicle {
  Part body;
  List<Part> attachedParts;
  // Слоты - это предопределенные координаты на корпусе для установки деталей
  List<Vector2> bodySlots;

  Vehicle({required this.body, required this.bodySlots}) : attachedParts = [];

  int get totalHealth => body.health + attachedParts.fold(0, (sum, item) => sum + item.health);
  int get totalPower => attachedParts.fold(0, (sum, item) => sum + item.power);
  int get totalEnergySlots => body.energy;
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ConstructorScreen(),
  ));
}

class BouncingBallGame extends FlameGame {
  late Ball ball;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    ball = Ball();
    add(ball);
  }
}

class Ball extends PositionComponent with HasGameRef<BouncingBallGame> {
  static const double radius = 30;
  static const double gravity = 800; // px/s^2
  static const double bounce = -500; // px/s

  late Vector2 velocity;

  Ball() : super(size: Vector2.all(radius * 2));

  @override
  Future<void> onLoad() async {
    position = Vector2(
      (gameRef.size.x - size.x) / 2,
      0,
    );
    velocity = Vector2(0, 0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    velocity.y += gravity * dt;
    position += velocity * dt;

    final groundY = gameRef.size.y - size.y;
    if (position.y >= groundY) {
      position.y = groundY;
      if (velocity.y > 0) {
        velocity.y = bounce;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.deepPurple;
    canvas.drawCircle(Offset(radius, radius), radius, paint);
  }
}

class VehicleConstructorGame extends FlameGame {
  late SpriteComponent vehicleBody;
  List<SpriteComponent> attachedPartSprites = [];

  @override
  Future<void> onLoad() async {
    // Устанавливаем камеру в центр
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(0, 0);
  }

  // Метод для установки нового корпуса
  Future<void> setBody(Part bodyPart, List<Vector2> slots) async {
    if (isMounted && contains(vehicleBody)) {
      remove(vehicleBody);
    }
    vehicleBody = SpriteComponent(
      sprite: await Sprite.load(bodyPart.imagePath),
      anchor: Anchor.center,
      position: Vector2(0, 0), // В центре мира
      size: Vector2(250, 150), // Примерный размер
    );
    await add(vehicleBody);
    clearAttachments(); // Очищаем старые детали
  }

  // Метод для добавления детали на корпус
  Future<void> addPart(Part part, Vector2 position) async {
    final partSprite = SpriteComponent(
      sprite: await Sprite.load(part.imagePath),
      anchor: Anchor.center,
      position: position, // Позиция относительно родителя (корпуса)
      size: Vector2(50, 50), // Примерный размер
    );
    attachedPartSprites.add(partSprite);
    // Добавляем деталь как дочерний компонент корпуса,
    // чтобы она двигалась вместе с ним
    vehicleBody.add(partSprite);
  }

  // Очистка всех навесных деталей
  void clearAttachments() {
    for (var partSprite in attachedPartSprites) {
      if (vehicleBody.contains(partSprite)) {
        vehicleBody.remove(partSprite);
      }
    }
    attachedPartSprites.clear();
  }
}

class ConstructorScreen extends StatefulWidget {
  const ConstructorScreen({Key? key}) : super(key: key);

  @override
  _ConstructorScreenState createState() => _ConstructorScreenState();
}

class _ConstructorScreenState extends State<ConstructorScreen> {
  late final VehicleConstructorGame _game;

  // Пример данных инвентаря
  final List<Part> inventory = [
    Part(id: 'titan_body', name: 'Титан', imagePath: 'titan_body.png', type: PartType.body, health: 216, energy: 10),
    Part(id: 'scout_body', name: 'Проныра', imagePath: 'scout_body.png', type: PartType.body, health: 54, energy: 6),
    Part(id: 'rocket', name: 'Ракетница', imagePath: 'rocket.png', type: PartType.weapon, power: 15),
    Part(id: 'drill', name: 'Циркулярка', imagePath: 'drill.png', type: PartType.weapon, power: 10),
  ];

  late Vehicle currentVehicle;

  @override
  void initState() {
    super.initState();
    _game = VehicleConstructorGame();
    // Инициализируем начальную машину
    _setupInitialVehicle();
  }

  void _setupInitialVehicle() {
    Part initialBody = inventory.firstWhere((p) => p.type == PartType.body);
    // Определяем слоты для этого корпуса (координаты относительно центра корпуса)
    List<Vector2> slots = [Vector2(80, 20), Vector2(-75, 10), Vector2(40, -40)];
    currentVehicle = Vehicle(body: initialBody, bodySlots: slots);
    
    // Передаем данные в Flame
    _game.setBody(currentVehicle.body, currentVehicle.bodySlots);
  }

  void _addPartToVehicle(Part part) {
    if (currentVehicle.attachedParts.length < currentVehicle.bodySlots.length) {
      setState(() {
        currentVehicle.attachedParts.add(part);
        // Добавляем визуал в Flame
        _game.addPart(part, currentVehicle.bodySlots[currentVehicle.attachedParts.length - 1]);
      });
    } else {
      // Показываем сообщение, что нет свободных слотов
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Нет свободных слотов!')),
      );
    }
  }

  // Пример виджета для инвентаря с drag&drop
  Widget _buildInventoryPanel() {
    return Container(
      width: 120,
      color: Colors.black.withOpacity(0.4),
      child: ListView(
        children: inventory.where((p) => p.type != PartType.body).map((part) {
          return Draggable<Part>(
            data: part,
            feedback: Opacity(
              opacity: 0.7,
              child: Card(
                color: Colors.grey[700],
                child: Column(
                  children: [
                    Image.asset('assets/images/${part.imagePath}', width: 80, height: 80),
                    Text(part.name, style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: Card(
                color: Colors.grey[700],
                child: Column(
                  children: [
                    Image.asset('assets/images/${part.imagePath}', width: 80, height: 80),
                    Text(part.name, style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            child: Card(
              color: Colors.grey[700],
              child: Column(
                children: [
                  Image.asset('assets/images/${part.imagePath}', width: 80, height: 80),
                  Text(part.name, style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Центральная часть: визуализация слотов и DragTarget
  Widget _buildVehicleSlots() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Корпус
          Image.asset('assets/images/${currentVehicle.body.imagePath}', width: 250, height: 150),
          // Слоты для оружия/колёс
          ...List.generate(currentVehicle.bodySlots.length, (i) {
            final slot = currentVehicle.bodySlots[i];
            final attached = i < currentVehicle.attachedParts.length ? currentVehicle.attachedParts[i] : null;
            return Positioned(
              left: 125 + slot.x, // 125 = половина ширины корпуса
              top: 75 + slot.y,   // 75 = половина высоты корпуса
              child: DragTarget<Part>(
                onWillAccept: (part) => attached == null && part != null && part.type != PartType.body,
                onAccept: (part) {
                  setState(() {
                    if (attached == null) {
                      currentVehicle.attachedParts.add(part);
                      _game.addPart(part, slot);
                    }
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: attached == null
                          ? (candidateData.isNotEmpty ? Colors.green.withOpacity(0.5) : Colors.white.withOpacity(0.2))
                          : Colors.transparent,
                      border: Border.all(color: Colors.white, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: attached != null
                        ? Image.asset('assets/images/${attached.imagePath}', width: 48, height: 48)
                        : Icon(Icons.add, color: Colors.white38),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[800],
      body: Stack(
        children: [
          // 1. Игровая сцена Flame на заднем плане (можно скрыть для drag&drop)
          // GameWidget(game: _game),

          // 2. Пользовательский интерфейс Flutter поверх сцены
          Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Row(
                  children: [
                    _buildInventoryPanel(),
                    Expanded(child: _buildVehicleSlots()),
                    _buildRightPanel(),
                  ],
                ),
              ),
              _buildStatsBar(),
            ],
          ),
        ],
      ),
    );
  }

  

  // Пример виджета для характеристик
  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, color: Colors.red),
          SizedBox(width: 8),
          Text('${currentVehicle.totalHealth}', style: TextStyle(color: Colors.white, fontSize: 20)),
          SizedBox(width: 24),
          Icon(Icons.whatshot, color: Colors.orange),
          SizedBox(width: 8),
          Text('${currentVehicle.totalPower}', style: TextStyle(color: Colors.white, fontSize: 20)),
          // ... и так далее для энергии
        ],
      ),
    );
  }

  Widget _buildTopBar() => SizedBox(height: 50); // Заглушка
  Widget _buildRightPanel() => SizedBox(width: 100); // Заглушка
}
