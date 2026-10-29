import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MantenApp());
}

const Color navy = Color(0xFF163B6D);
const Color primaryBlue = Color(0xFF1976D2);
const Color paleBackground = Color(0xFFF4F7FB);
const Color ink = Color(0xFF203247);
const Color mutedInk = Color(0xFF617083);
const Color borderColor = Color(0xFFDDE5EF);

class MantenApp extends StatefulWidget {
  const MantenApp({super.key});

  @override
  State<MantenApp> createState() => _MantenAppState();
}

class _MantenAppState extends State<MantenApp> {
  final MantenStore store = MantenStore();
  bool ready = false;
  bool loggedIn = false;
  String currentUser = 'Administrador';
  String currentRole = 'Administrador';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await store.initialize();
    if (mounted) setState(() => ready = true);
  }

  void _login(Map<String, dynamic> user) {
    setState(() {
      loggedIn = true;
      currentUser = user['name']?.toString() ?? 'Usuario';
      currentRole = user['role']?.toString() ?? 'Operador';
    });
  }

  void _logout() => setState(() => loggedIn = false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MANTEN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paleBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderColor),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: !ready
          ? const _LoadingScreen()
          : loggedIn
              ? HomeShell(
                  store: store,
                  userName: currentUser,
                  userRole: currentRole,
                  onLogout: _logout,
                )
              : LoginScreen(store: store, onLogin: _login),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

// Local persistence layer for the first working version. It can later be replaced
// with a remote API/Supabase repository without changing the screen layout.
class MantenStore extends ChangeNotifier {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final Map<String, List<Map<String, dynamic>>> _tables = {
    'users': [],
    'works': [],
    'machines': [],
    'hours': [],
    'maintenance': [],
    'downtimes': [],
    'partUses': [],
    'requests': [],
  };

  List<Map<String, dynamic>> rows(String table) =>
      List<Map<String, dynamic>>.from(_tables[table] ?? const []);

  Future<void> initialize() async {
    for (final table in _tables.keys) {
      final raw = await _preferences.getString('manten_$table');
      if (raw != null && raw.isNotEmpty) {
        try {
          final parsed = jsonDecode(raw) as List<dynamic>;
          _tables[table] = parsed
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        } catch (_) {
          _tables[table] = [];
        }
      }
    }

    if ((_tables['users'] ?? []).isEmpty) {
      _tables['users'] = [
        {'id': 'u-admin', 'name': 'Administrador', 'username': 'admin', 'role': 'Administrador', 'active': true},
        {'id': 'u-operator', 'name': 'Operador de obra', 'username': 'operador', 'role': 'Operador', 'active': true},
      ];
    }
    if ((_tables['works'] ?? []).isEmpty) {
      _tables['works'] = [
        {'id': 'w-001', 'code': 'OB-001', 'name': 'Obra Norte', 'engineer': 'Carlos Pérez', 'status': 'En ejecución'},
        {'id': 'w-002', 'code': 'OB-002', 'name': 'Obra Centro', 'engineer': 'María Torres', 'status': 'En ejecución'},
        {'id': 'w-003', 'code': 'OB-003', 'name': 'Obra Sur', 'engineer': 'Luis Ramos', 'status': 'Programada'},
      ];
    }
    if ((_tables['machines'] ?? []).isEmpty) {
      _tables['machines'] = [
        {'id': 'm-001', 'code': 'EX-01', 'name': 'Excavadora', 'type': 'Excavadora', 'brand': 'Caterpillar', 'model': '320D', 'workId': 'w-001', 'status': 'Operativa', 'hours': 486.0},
        {'id': 'm-002', 'code': 'CT-02', 'name': 'Cortadora', 'type': 'Cortadora', 'brand': 'Stihl', 'model': 'TS 420', 'workId': 'w-001', 'status': 'En mantenimiento', 'hours': 218.0},
        {'id': 'm-003', 'code': 'PD-03', 'name': 'Podadora', 'type': 'Podadora', 'brand': 'Husqvarna', 'model': '525', 'workId': 'w-002', 'status': 'Detenida', 'hours': 132.0},
      ];
    }
    if ((_tables['hours'] ?? []).isEmpty) {
      _tables['hours'] = [
        {'id': 'h-001', 'machineId': 'm-001', 'date': '2026-10-24', 'value': 8.0, 'notes': 'Jornada regular'},
        {'id': 'h-002', 'machineId': 'm-001', 'date': '2026-10-23', 'value': 6.0, 'notes': 'Mantenimiento de áreas verdes'},
        {'id': 'h-003', 'machineId': 'm-002', 'date': '2026-10-22', 'value': 4.0, 'notes': 'Trabajo parcial'},
      ];
    }
    if ((_tables['maintenance'] ?? []).isEmpty) {
      _tables['maintenance'] = [
        {'id': 'mt-001', 'machineId': 'm-001', 'type': 'Preventivo', 'date': '2026-10-29', 'status': 'Programado', 'responsible': 'Carlos Pérez', 'observations': 'Revisión por horas de uso'},
        {'id': 'mt-002', 'machineId': 'm-002', 'type': 'Correctivo', 'date': '2026-10-20', 'status': 'Realizado', 'responsible': 'María Torres', 'observations': 'Cambio de filtro'},
      ];
    }
    if ((_tables['downtimes'] ?? []).isEmpty) {
      _tables['downtimes'] = [
        {'id': 'dt-001', 'machineId': 'm-002', 'start': '2026-10-20T08:30:00', 'end': '2026-10-20T11:15:00', 'reason': 'Mantenimiento preventivo'},
      ];
    }
    if ((_tables['partUses'] ?? []).isEmpty) {
      _tables['partUses'] = [
        {'id': 'pu-001', 'machineId': 'm-002', 'part': 'Filtro de aceite', 'quantity': 1, 'date': '2026-10-20', 'notes': 'Cambio durante mantenimiento'},
      ];
    }
    if ((_tables['requests'] ?? []).isEmpty) {
      _tables['requests'] = [
        {'id': 'rq-001', 'machineId': 'm-001', 'part': 'Filtro de aceite', 'quantity': 2, 'requester': 'Carlos Pérez', 'date': '2026-10-25', 'status': 'Pendiente'},
        {'id': 'rq-002', 'machineId': 'm-002', 'part': 'Correa', 'quantity': 1, 'requester': 'María Torres', 'date': '2026-10-21', 'status': 'Comprado'},
      ];
    }

    for (final table in _tables.keys) {
      await _save(table, notify: false);
    }
  }

  Future<void> _save(String table, {bool notify = true}) async {
    await _preferences.setString('manten_$table', jsonEncode(_tables[table]));
    if (notify) notifyListeners();
  }

  Future<void> add(String table, Map<String, dynamic> row) async {
    final item = Map<String, dynamic>.from(row);
    item['id'] ??= '${table.substring(0, 1)}-${DateTime.now().microsecondsSinceEpoch}';
    (_tables[table] ??= []).add(item);
    await _save(table);
  }

  Future<void> update(String table, String id, Map<String, dynamic> changes) async {
    final list = _tables[table] ?? [];
    final index = list.indexWhere((row) => row['id'].toString() == id);
    if (index < 0) return;
    list[index] = {...list[index], ...changes, 'id': id};
    await _save(table);
  }

  Future<void> remove(String table, String id) async {
    (_tables[table] ?? []).removeWhere((row) => row['id'].toString() == id);
    await _save(table);
  }

  Map<String, dynamic>? machineById(String? id) {
    if (id == null) return null;
    for (final machine in rows('machines')) {
      if (machine['id'].toString() == id) return machine;
    }
    return null;
  }

  Map<String, dynamic>? workById(String? id) {
    if (id == null) return null;
    for (final work in rows('works')) {
      if (work['id'].toString() == id) return work;
    }
    return null;
  }

  String machineName(String? id) {
    final machine = machineById(id);
    if (machine == null) return 'Máquina sin asignar';
    return '${machine['code']} · ${machine['name']}';
  }

  String workName(String? id) {
    final work = workById(id);
    if (work == null) return 'Sin obra asignada';
    return '${work['code']} · ${work['name']}';
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.store, required this.onLogin});
  final MantenStore store;
  final ValueChanged<Map<String, dynamic>> onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController(text: 'admin');
  final _password = TextEditingController(text: '1234');
  bool _hidePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final user = widget.store.rows('users').where((row) =>
        row['username'].toString().toLowerCase() == _username.text.trim().toLowerCase() && row['active'] != false).firstOrNull;
    if (user != null && _password.text == '1234') {
      widget.onLogin(user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario o contraseña incorrectos. Prueba admin / 1234.')),
      );
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(24)),
                    child: const Column(
                      children: [
                        Icon(Icons.handyman_rounded, color: Colors.white, size: 54),
                        SizedBox(height: 12),
                        Text('MANTEN', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                        SizedBox(height: 4),
                        Text('Control de mantenimiento de maquinaria', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text('Iniciar sesión', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: ink)),
                  const SizedBox(height: 8),
                  const Text('Ingresa para consultar obras, máquinas y mantenimientos.', style: TextStyle(color: mutedInk)),
                  const SizedBox(height: 22),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _username,
                          decoration: const InputDecoration(labelText: 'Usuario', prefixIcon: Icon(Icons.person_outline)),
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa tu usuario' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _hidePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _hidePassword = !_hidePassword),
                              icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? 'Ingresa tu contraseña' : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(width: double.infinity, child: FilledButton.icon(
                          onPressed: _busy ? null : _submit,
                          icon: const Icon(Icons.login),
                          label: Text(_busy ? 'Ingresando…' : 'INGRESAR'),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
                    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Cuenta de demostración', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
                      SizedBox(height: 6),
                      Text('Usuario: admin', style: TextStyle(color: mutedInk)),
                      Text('Contraseña: 1234', style: TextStyle(color: mutedInk)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Text('Primera versión: los datos se guardan localmente en este dispositivo.', textAlign: TextAlign.center, style: TextStyle(color: mutedInk, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store, required this.userName, required this.userRole, required this.onLogout});
  final MantenStore store;
  final String userName;
  final String userRole;
  final VoidCallback onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void _openPage(String key) {
    final Widget page = switch (key) {
      'works' => WorksPage(store: widget.store),
      'machines' => MachinesPage(store: widget.store),
      'hours' => HoursPage(store: widget.store),
      'maintenance' => MaintenancePage(store: widget.store),
      'downtimes' => DowntimePage(store: widget.store),
      'parts' => PartsPage(store: widget.store),
      'admin' => AdminPage(store: widget.store),
      _ => const SizedBox.shrink(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['MANTEN', 'Obras', 'Máquinas', 'Más opciones'];
    final screens = [
      DashboardPage(store: widget.store, userName: widget.userName, userRole: widget.userRole, onOpen: _openPage),
      WorksPage(store: widget.store),
      MachinesPage(store: widget.store),
      MorePage(store: widget.store, onOpen: _openPage),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.w800)),
          if (_selectedIndex == 0) Text(widget.userName, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [
          IconButton(tooltip: 'Cerrar sesión', onPressed: widget.onLogout, icon: const Icon(Icons.logout_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) => setState(() => _selectedIndex = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Obras'),
          NavigationDestination(icon: Icon(Icons.precision_manufacturing_outlined), selectedIcon: Icon(Icons.precision_manufacturing), label: 'Máquinas'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view), label: 'Más'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.store, required this.userName, required this.userRole, required this.onOpen});
  final MantenStore store;
  final String userName;
  final String userRole;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final machines = store.rows('machines');
          final works = store.rows('works');
          final upcoming = store.rows('maintenance').where((r) => r['status'] == 'Programado').length;
          final stopped = machines.where((r) => r['status'] == 'Detenida' || r['status'] == 'En mantenimiento').length;
          final pendingRequests = store.rows('requests').where((r) => r['status'] == 'Pendiente').length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF1559A4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hola, $userName', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  const Text('Control de maquinaria en un solo lugar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 21)),
                  const SizedBox(height: 10),
                  Text('${works.length} obras · ${machines.length} máquinas registradas', style: const TextStyle(color: Colors.white70)),
                ]),
              ),
              const SizedBox(height: 20),
              const SectionHeading(title: 'Resumen', subtitle: 'Estado actual del registro'),
              const SizedBox(height: 10),
              Wrap(spacing: 10, runSpacing: 10, children: [
                MetricCard(label: 'Máquinas', value: '${machines.length}', icon: Icons.precision_manufacturing, color: primaryBlue),
                MetricCard(label: 'En parada / mant.', value: '$stopped', icon: Icons.pause_circle_outline, color: const Color(0xFFB45E12)),
                MetricCard(label: 'Mantenimientos', value: '$upcoming', icon: Icons.event_note, color: const Color(0xFF7758B7)),
                MetricCard(label: 'Repuestos pendientes', value: '$pendingRequests', icon: Icons.build_circle_outlined, color: const Color(0xFF1C8565)),
              ]),
              const SizedBox(height: 22),
              const SectionHeading(title: 'Accesos rápidos', subtitle: 'Continúa con una tarea'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.22,
                children: [
                  QuickAction(title: 'Obras', description: 'Proyectos y responsables', icon: Icons.work_outline, onTap: () => onOpen('works')),
                  QuickAction(title: 'Máquinas', description: 'Datos y estado actual', icon: Icons.precision_manufacturing, onTap: () => onOpen('machines')),
                  QuickAction(title: 'Horas de uso', description: 'Registrar jornadas', icon: Icons.timer_outlined, onTap: () => onOpen('hours')),
                  QuickAction(title: 'Mantenimiento', description: 'Programar y registrar', icon: Icons.build_outlined, onTap: () => onOpen('maintenance')),
                  QuickAction(title: 'Paradas', description: 'Inicio, fin y duración', icon: Icons.pause_circle_outline, onTap: () => onOpen('downtimes')),
                  QuickAction(title: 'Repuestos', description: 'Uso y solicitudes', icon: Icons.settings_suggest_outlined, onTap: () => onOpen('parts')),
                ],
              ),
              const SizedBox(height: 14),
              Card(child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE5EFFB), child: Icon(Icons.verified_user_outlined, color: primaryBlue)),
                title: const Text('Sesión activa', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
                subtitle: Text('Rol: $userRole · datos guardados en este dispositivo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpen('admin'),
              )),
            ],
          );
        },
      );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
        if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle!, style: const TextStyle(fontSize: 12, color: mutedInk))],
      ]);
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: (MediaQuery.sizeOf(context).width - 42) / 2,
        child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 12, color: mutedInk)),
        ]))),
      );
}

class QuickAction extends StatelessWidget {
  const QuickAction({super.key, required this.title, required this.description, required this.icon, required this.onTap});
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFE7F0FC), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: primaryBlue)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 4),
            Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: mutedInk)),
          ]),
        ]))),
      );
}

class MorePage extends StatelessWidget {
  const MorePage({super.key, required this.store, required this.onOpen});
  final MantenStore store;
  final ValueChanged<String> onOpen;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        const SectionHeading(title: 'Operaciones', subtitle: 'Herramientas de seguimiento'),
        const SizedBox(height: 12),
        MenuTile(icon: Icons.timer_outlined, title: 'Horas de uso', subtitle: 'Registros y acumulados', onTap: () => onOpen('hours')),
        MenuTile(icon: Icons.build_outlined, title: 'Mantenimiento', subtitle: 'Programaciones e historial', onTap: () => onOpen('maintenance')),
        MenuTile(icon: Icons.pause_circle_outline, title: 'Paradas de máquina', subtitle: 'Fechas, motivo y duración', onTap: () => onOpen('downtimes')),
        MenuTile(icon: Icons.settings_suggest_outlined, title: 'Repuestos', subtitle: 'Repuestos usados y compras', onTap: () => onOpen('parts')),
        const SizedBox(height: 18),
        const SectionHeading(title: 'Configuración', subtitle: 'Acceso administrativo'),
        const SizedBox(height: 12),
        MenuTile(icon: Icons.manage_accounts_outlined, title: 'Usuarios y roles', subtitle: 'Administrar personas y perfiles', onTap: () => onOpen('admin')),
        const SizedBox(height: 18),
        const Card(child: Padding(padding: EdgeInsets.all(15), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: primaryBlue),
          SizedBox(width: 10),
          Expanded(child: Text('MANTEN guarda los registros de esta versión en el almacenamiento local del dispositivo. Todavía no sincroniza información entre teléfonos.', style: TextStyle(fontSize: 12, color: mutedInk))),
        ]))),
      ]);
}

class MenuTile extends StatelessWidget {
  const MenuTile({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Card(child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFFE7F0FC), child: Icon(icon, color: primaryBlue)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: ink)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      )));
}

class WorksPage extends StatelessWidget {
  const WorksPage({super.key, required this.store});
  final MantenStore store;

  Future<void> _edit(BuildContext context, {Map<String, dynamic>? row}) async {
    final values = await showRecordDialog(context,
      title: row == null ? 'Registrar obra' : 'Modificar obra',
      initial: row,
      fields: [
        FormFieldSpec('code', 'Código de obra', required: true, initial: 'OB-${(store.rows('works').length + 1).toString().padLeft(3, '0')}'),
        const FormFieldSpec('name', 'Nombre de la obra', required: true),
        const FormFieldSpec('engineer', 'Ingeniero a cargo', required: true),
        const FormFieldSpec('status', 'Estado de la obra', type: FieldType.dropdown, required: true, options: {'En ejecución': 'En ejecución', 'Programada': 'Programada', 'Finalizada': 'Finalizada'}),
      ]);
    if (values == null) return;
    if (row == null) {
      await store.add('works', values);
    } else {
      await store.update('works', row['id'].toString(), values);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: paleBackground,
        floatingActionButton: FloatingActionButton.extended(onPressed: () => _edit(context), icon: const Icon(Icons.add), label: const Text('Nueva obra')),
        body: AnimatedBuilder(animation: store, builder: (context, _) {
          final works = store.rows('works');
          return ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 100), children: [
            const SectionHeading(title: 'Obras', subtitle: 'Proyectos y responsables a cargo'),
            const SizedBox(height: 12),
            if (works.isEmpty) const EmptyState(text: 'Todavía no hay obras registradas.'),
            for (final work in works)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(child: ListTile(
                contentPadding: const EdgeInsets.all(13),
                leading: const CircleAvatar(backgroundColor: Color(0xFFE7F0FC), child: Icon(Icons.work_outline, color: primaryBlue)),
                title: Text('${work['code']} · ${work['name']}', style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
                subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text('Ingeniero: ${work['engineer']}\nEstado: ${work['status']}\nMáquinas asignadas: ${store.rows('machines').where((m) => m['workId'] == work['id']).length}')),
                isThreeLine: true,
                trailing: IconButton(tooltip: 'Editar obra', onPressed: () => _edit(context, row: work), icon: const Icon(Icons.edit_outlined)),
              ))),
          ]);
        }),
      );
}

class MachinesPage extends StatelessWidget {
  const MachinesPage({super.key, required this.store});
  final MantenStore store;

  Map<String, String> get _workOptions => {
        '': 'Sin obra asignada',
        for (final work in store.rows('works')) work['id'].toString(): '${work['code']} · ${work['name']}',
      };

  Future<void> _edit(BuildContext context, {Map<String, dynamic>? row}) async {
    final values = await showRecordDialog(context,
      title: row == null ? 'Registrar máquina' : 'Modificar máquina',
      initial: row,
      fields: [
        FormFieldSpec('code', 'Código de máquina', required: true, initial: 'MA-${(store.rows('machines').length + 1).toString().padLeft(2, '0')}'),
        const FormFieldSpec('name', 'Nombre de máquina', required: true),
        const FormFieldSpec('type', 'Tipo de máquina', required: true),
        const FormFieldSpec('brand', 'Marca', required: true),
        const FormFieldSpec('model', 'Modelo', required: true),
        FormFieldSpec('workId', 'Obra asignada', type: FieldType.dropdown, options: _workOptions, required: false, initial: ''),
        const FormFieldSpec('status', 'Estado actual', type: FieldType.dropdown, required: true, options: {'Operativa': 'Operativa', 'En mantenimiento': 'En mantenimiento', 'Detenida': 'Detenida'}),
      ]);
    if (values == null) return;
    values['hours'] = row?['hours'] ?? 0.0;
    if (values['workId'] == '') values['workId'] = null;
    if (row == null) {
      await store.add('machines', values);
    } else {
      await store.update('machines', row['id'].toString(), values);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: paleBackground,
        floatingActionButton: FloatingActionButton.extended(onPressed: () => _edit(context), icon: const Icon(Icons.add), label: const Text('Nueva máquina')),
        body: AnimatedBuilder(animation: store, builder: (context, _) {
          final machines = store.rows('machines');
          return ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 100), children: [
            const SectionHeading(title: 'Máquinas', subtitle: 'Ficha, ubicación y estado actual'),
            const SizedBox(height: 12),
            if (machines.isEmpty) const EmptyState(text: 'Todavía no hay máquinas registradas.'),
            for (final machine in machines)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(child: Padding(padding: const EdgeInsets.all(13), child: Column(children: [
                Row(children: [
                  const CircleAvatar(backgroundColor: Color(0xFFE7F0FC), child: Icon(Icons.precision_manufacturing_outlined, color: primaryBlue)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${machine['code']} · ${machine['name']}', style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
                    const SizedBox(height: 3),
                    Text('${machine['brand']} ${machine['model']} · ${machine['type']}', style: const TextStyle(fontSize: 12, color: mutedInk)),
                  ])),
                  IconButton(onPressed: () => _edit(context, row: machine), icon: const Icon(Icons.edit_outlined), tooltip: 'Editar máquina'),
                ]),
                const Divider(height: 22),
                Row(children: [
                  Expanded(child: Text(store.workName(machine['workId']?.toString()), style: const TextStyle(fontSize: 12, color: mutedInk))),
                  StatusPill(text: machine['status'].toString()),
                ]),
                const SizedBox(height: 7),
                Row(children: [const Icon(Icons.schedule, size: 15, color: mutedInk), const SizedBox(width: 5), Text('Horas acumuladas: ${numberText(machine['hours'])} h', style: const TextStyle(fontSize: 12, color: mutedInk))]),
              ])))),
          ]);
        }),
      );
}

class HoursPage extends StatelessWidget {
  const HoursPage({super.key, required this.store});
  final MantenStore store;

  Future<void> _add(BuildContext context) async {
    final machineOptions = {for (final machine in store.rows('machines')) machine['id'].toString(): '${machine['code']} · ${machine['name']}'};
    if (machineOptions.isEmpty) {
      showInfo(context, 'Primero registra una máquina para poder agregar sus horas de uso.');
      return;
    }
    final values = await showRecordDialog(context, title: 'Registrar horas de uso', fields: [
      FormFieldSpec('machineId', 'Máquina', type: FieldType.dropdown, options: machineOptions, required: true),
      FormFieldSpec('date', 'Fecha (AAAA-MM-DD)', required: true, initial: todayText()),
      const FormFieldSpec('value', 'Horas trabajadas', type: FieldType.number, required: true),
      const FormFieldSpec('notes', 'Observaciones', required: false),
    ]);
    if (values == null) return;
    final hours = double.tryParse(values['value'].toString()) ?? 0;
    if (hours <= 0 || hours > 24) {
      showInfo(context, 'Ingresa una cantidad de horas mayor que 0 y no superior a 24.');
      return;
    }
    values['value'] = hours;
    final machine = store.machineById(values['machineId'].toString());
    if (machine != null) await store.update('machines', machine['id'].toString(), {'hours': (toDouble(machine['hours']) + hours)});
    await store.add('hours', values);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Horas de uso')),
        floatingActionButton: FloatingActionButton.extended(onPressed: () => _add(context), icon: const Icon(Icons.add), label: const Text('Registrar horas')),
        body: AnimatedBuilder(animation: store, builder: (context, _) {
          final machines = store.rows('machines');
          final logs = store.rows('hours')..sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
          return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
            const SectionHeading(title: 'Horas acumuladas', subtitle: 'Registro por máquina y fecha'),
            const SizedBox(height: 12),
            for (final machine in machines)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Card(child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE7F0FC), child: Icon(Icons.av_timer, color: primaryBlue)),
                title: Text('${machine['code']} · ${machine['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: Text('${numberText(machine['hours'])} h', style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w800)),
                subtitle: Text(store.workName(machine['workId']?.toString())),
              ))),
            const SizedBox(height: 14),
            const SectionHeading(title: 'Historial de registros'),
            const SizedBox(height: 8),
            if (logs.isEmpty) const EmptyState(text: 'Todavía no hay registros de horas.'),
            for (final log in logs)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Card(child: ListTile(
                leading: const Icon(Icons.history, color: primaryBlue),
                title: Text(store.machineName(log['machineId']?.toString()), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${log['date']} · ${log['notes'] ?? 'Sin observaciones'}'),
                trailing: Text('+${numberText(log['value'])} h', style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
              ))),
          ]);
        }),
      );
}

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key, required this.store});
  final MantenStore store;

  Future<void> _add(BuildContext context) async {
    final machineOptions = {for (final machine in store.rows('machines')) machine['id'].toString(): '${machine['code']} · ${machine['name']}'};
    if (machineOptions.isEmpty) { showInfo(context, 'Primero registra una máquina.'); return; }
    final values = await showRecordDialog(context, title: 'Programar mantenimiento', fields: [
      FormFieldSpec('machineId', 'Máquina', type: FieldType.dropdown, options: machineOptions, required: true),
      const FormFieldSpec('type', 'Tipo de mantenimiento', type: FieldType.dropdown, options: {'Preventivo': 'Preventivo', 'Correctivo': 'Correctivo', 'Inspección': 'Inspección'}, required: true),
      FormFieldSpec('date', 'Fecha (AAAA-MM-DD)', required: true, initial: todayText()),
      const FormFieldSpec('responsible', 'Responsable', required: true, initial: 'Ingeniero a cargo'),
      const FormFieldSpec('observations', 'Observaciones', required: false),
      const FormFieldSpec('status', 'Estado', type: FieldType.dropdown, options: {'Programado': 'Programado', 'Realizado': 'Realizado'}, required: true, initial: 'Programado'),
    ]);
    if (values != null) await store.add('maintenance', values);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mantenimiento')),
        floatingActionButton: FloatingActionButton.extended(onPressed: () => _add(context), icon: const Icon(Icons.add), label: const Text('Programar')),
        body: AnimatedBuilder(animation: store, builder: (context, _) {
          final entries = store.rows('maintenance')..sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
          return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
            const SectionHeading(title: 'Plan de mantenimiento', subtitle: 'Fechas, tipo y responsable'),
            const SizedBox(height: 12),
            if (entries.isEmpty) const EmptyState(text: 'No hay mantenimientos registrados.'),
            for (final entry in entries)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const CircleAvatar(backgroundColor: Color(0xFFE7F0FC), child: Icon(Icons.build_outlined, color: primaryBlue)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(store.machineName(entry['machineId']?.toString()), style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
                    const SizedBox(height: 4),
                    Text('${entry['type']} · ${entry['date']}', style: const TextStyle(color: mutedInk, fontSize: 12)),
                  ])),
                  StatusPill(text: entry['status'].toString()),
                ]),
                const SizedBox(height: 10),
                Text('Responsable: ${entry['responsible']}', style: const TextStyle(fontSize: 12, color: mutedInk)),
                if ((entry['observations'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 4), Text(entry['observations'].toString(), style: const TextStyle(fontSize: 12, color: mutedInk))],
                if (entry['status'] == 'Programado') ...[
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(
                    onPressed: () async {
                      await store.update('maintenance', entry['id'].toString(), {'status': 'Realizado', 'completedDate': todayText()});
                      final machine = store.machineById(entry['machineId']?.toString());
                      if (machine != null && machine['status'] == 'En mantenimiento') await store.update('machines', machine['id'].toString(), {'status': 'Operativa'});
                    },
                    icon: const Icon(Icons.check_circle_outline), label: const Text('Marcar realizado'),
                  )),
                ],
              ])))),
          ]);
        }),
      );
}

class DowntimePage extends StatelessWidget {
  const DowntimePage({super.key, required this.store});
  final MantenStore store;

  Future<void> _start(BuildContext context) async {
    final machineOptions = {for (final machine in store.rows('machines')) machine['id'].toString(): '${machine['code']} · ${machine['name']}'};
    if (machineOptions.isEmpty) { showInfo(context, 'Primero registra una máquina.'); return; }
    final values = await showRecordDialog(context, title: 'Registrar inicio de parada', fields: [
      FormFieldSpec('machineId', 'Máquina', type: FieldType.dropdown, options: machineOptions, required: true),
      const FormFieldSpec('reason', 'Motivo de la parada', required: true),
    ]);
    if (values == null) return;
    values['start'] = DateTime.now().toIso8601String();
    values['end'] = null;
    await store.add('downtimes', values);
    await store.update('machines', values['machineId'].toString(), {'status': 'Detenida'});
  }

  Future<void> _finish(BuildContext context, Map<String, dynamic> record) async {
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
          title: const Text('Finalizar parada'),
          content: Text('¿Registrar el fin de la parada de ${store.machineName(record['machineId']?.toString())}?'),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Finalizar'))],
        ));
    if (confirm != true) return;
    await store.update('downtimes', record['id'].toString(), {'end': DateTime.now().toIso8601String()});
    final machine = store.machineById(record['machineId']?.toString());
    if (machine != null && machine['status'] == 'Detenida') await store.update('machines', machine['id'].toString(), {'status': 'Operativa'});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Paradas de máquina')),
        floatingActionButton: FloatingActionButton.extended(onPressed: () => _start(context), icon: const Icon(Icons.pause_circle_outline), label: const Text('Iniciar parada')),
        body: AnimatedBuilder(animation: store, builder: (context, _) {
          final entries = store.rows('downtimes')..sort((a, b) => b['start'].toString().compareTo(a['start'].toString()));
          return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
            const SectionHeading(title: 'Control de paradas', subtitle: 'Registra inicio, motivo y fin'),
            const SizedBox(height: 12),
            if (entries.isEmpty) const EmptyState(text: 'No hay paradas registradas.'),
            for (final entry in entries)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Icons.pause_circle_outline, color: primaryBlue), const SizedBox(width: 8), Expanded(child: Text(store.machineName(entry['machineId']?.toString()), style: const TextStyle(fontWeight: FontWeight.w800, color: ink))), StatusPill(text: entry['end'] == null ? 'Detenida' : 'Finalizada')]),
                const SizedBox(height: 10),
                Text('Inicio: ${formatDateTime(entry['start'])}', style: const TextStyle(color: mutedInk, fontSize: 12)),
                Text('Fin: ${entry['end'] == null ? 'Pendiente' : formatDateTime(entry['end'])}', style: const TextStyle(color: mutedInk, fontSize: 12)),
                Text('Motivo: ${entry['reason']}', style: const TextStyle(color: mutedInk, fontSize: 12)),
                if (entry['end'] != null) Text('Duración: ${durationText(entry['start'], entry['end'])}', style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 12)),
                if (entry['end'] == null) Align(alignment: Alignment.centerRight, child: FilledButton.tonalIcon(onPressed: () => _finish(context, entry), icon: const Icon(Icons.stop_circle_outlined), label: const Text('Registrar fin'))),
              ])))),
          ]);
        }),
      );
}

class PartsPage extends StatefulWidget {
  const PartsPage({super.key, required this.store});
  final MantenStore store;
  @override
  State<PartsPage> createState() => _PartsPageState();
}

class _PartsPageState extends State<PartsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  MantenStore get store => widget.store;
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Map<String, String> get _machineOptions => {for (final machine in store.rows('machines')) machine['id'].toString(): '${machine['code']} · ${machine['name']}'};

  Future<void> _newRequest() async {
    if (_machineOptions.isEmpty) { showInfo(context, 'Primero registra una máquina.'); return; }
    final values = await showRecordDialog(context, title: 'Solicitar repuesto', fields: [
      FormFieldSpec('machineId', 'Máquina', type: FieldType.dropdown, options: _machineOptions, required: true),
      const FormFieldSpec('part', 'Nombre del repuesto', required: true),
      const FormFieldSpec('quantity', 'Cantidad solicitada', type: FieldType.number, required: true, initial: '1'),
      const FormFieldSpec('requester', 'Solicitado por', required: true, initial: 'Ingeniero a cargo'),
      FormFieldSpec('date', 'Fecha de solicitud', required: true, initial: todayText()),
    ]);
    if (values == null) return;
    final quantity = int.tryParse(values['quantity'].toString()) ?? 0;
    if (quantity < 1) { showInfo(context, 'La cantidad debe ser al menos 1.'); return; }
    values['quantity'] = quantity;
    values['status'] = 'Pendiente';
    await store.add('requests', values);
  }

  Future<void> _newUse() async {
    if (_machineOptions.isEmpty) { showInfo(context, 'Primero registra una máquina.'); return; }
    final values = await showRecordDialog(context, title: 'Registrar repuesto utilizado', fields: [
      FormFieldSpec('machineId', 'Máquina', type: FieldType.dropdown, options: _machineOptions, required: true),
      const FormFieldSpec('part', 'Nombre del repuesto', required: true),
      const FormFieldSpec('quantity', 'Cantidad utilizada', type: FieldType.number, required: true, initial: '1'),
      FormFieldSpec('date', 'Fecha', required: true, initial: todayText()),
      const FormFieldSpec('notes', 'Observaciones', required: false),
    ]);
    if (values == null) return;
    final quantity = int.tryParse(values['quantity'].toString()) ?? 0;
    if (quantity < 1) { showInfo(context, 'La cantidad debe ser al menos 1.'); return; }
    values['quantity'] = quantity;
    await store.add('partUses', values);
  }

  Future<void> _markPurchased(Map<String, dynamic> request) async {
    await store.update('requests', request['id'].toString(), {'status': 'Comprado', 'purchaseDate': todayText()});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Repuestos'), bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Solicitudes'), Tab(text: 'Uso de repuestos')], indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70)),
        floatingActionButton: AnimatedBuilder(animation: _tabs, builder: (context, _) => FloatingActionButton.extended(
          onPressed: _tabs.index == 0 ? _newRequest : _newUse,
          icon: Icon(_tabs.index == 0 ? Icons.add_shopping_cart : Icons.add),
          label: Text(_tabs.index == 0 ? 'Solicitar repuesto' : 'Registrar uso'),
        )),
        body: AnimatedBuilder(animation: store, builder: (context, _) => TabBarView(controller: _tabs, children: [_requestsTab(), _usesTab()])),
      );

  Widget _requestsTab() {
    final entries = store.rows('requests')..sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
      const SectionHeading(title: 'Solicitudes de compra', subtitle: 'Seguimiento de repuestos por máquina'),
      const SizedBox(height: 12),
      if (entries.isEmpty) const EmptyState(text: 'No hay solicitudes de repuestos.'),
      for (final request in entries)
        Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.build_circle_outlined, color: primaryBlue), const SizedBox(width: 8), Expanded(child: Text(request['part'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, color: ink))), StatusPill(text: request['status'].toString())]),
          const SizedBox(height: 8),
          Text('Máquina: ${store.machineName(request['machineId']?.toString())}', style: const TextStyle(fontSize: 12, color: mutedInk)),
          Text('Cantidad: ${request['quantity']} · Fecha: ${request['date']}', style: const TextStyle(fontSize: 12, color: mutedInk)),
          Text('Solicitante: ${request['requester']}', style: const TextStyle(fontSize: 12, color: mutedInk)),
          if (request['status'] == 'Pendiente') Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(onPressed: () => _markPurchased(request), icon: const Icon(Icons.shopping_cart_checkout), label: const Text('Marcar comprado'))),
          if (request['status'] == 'Comprado' && request['purchaseDate'] != null) Text('Compra registrada: ${request['purchaseDate']}', style: const TextStyle(fontSize: 12, color: Colors.green)),
        ])))),
    ]);
  }

  Widget _usesTab() {
    final entries = store.rows('partUses')..sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
      const SectionHeading(title: 'Repuestos utilizados', subtitle: 'Historial asociado a cada máquina'),
      const SizedBox(height: 12),
      if (entries.isEmpty) const EmptyState(text: 'Todavía no hay repuestos registrados como utilizados.'),
      for (final entry in entries)
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Card(child: ListTile(
          leading: const CircleAvatar(backgroundColor: Color(0xFFE7F0FC), child: Icon(Icons.build_outlined, color: primaryBlue)),
          title: Text(entry['part'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
          subtitle: Text('${store.machineName(entry['machineId']?.toString())}\n${entry['date']} · ${entry['notes'] ?? 'Sin observaciones'}'),
          isThreeLine: true,
          trailing: Text('×${entry['quantity']}', style: const TextStyle(fontWeight: FontWeight.w800, color: primaryBlue)),
        ))),
    ]);
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.store});
  final MantenStore store;

  Future<void> _edit(BuildContext context, {Map<String, dynamic>? row}) async {
    final values = await showRecordDialog(context, title: row == null ? 'Agregar usuario' : 'Modificar usuario', initial: row, fields: [
      const FormFieldSpec('name', 'Nombre completo', required: true),
      const FormFieldSpec('username', 'Nombre de usuario', required: true),
      const FormFieldSpec('role', 'Rol', type: FieldType.dropdown, required: true, options: {'Administrador': 'Administrador', 'Ingeniero': 'Ingeniero', 'Operador': 'Operador', 'Supervisor': 'Supervisor'}),
      const FormFieldSpec('active', 'Estado', type: FieldType.dropdown, required: true, options: {'true': 'Activo', 'false': 'Inactivo'}, initial: 'true'),
    ]);
    if (values == null) return;
    values['active'] = values['active'] == 'true';
    if (row == null) {
      await store.add('users', values);
    } else {
      await store.update('users', row['id'].toString(), values);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Usuarios y roles')),
        floatingActionButton: FloatingActionButton.extended(onPressed: () => _edit(context), icon: const Icon(Icons.person_add_alt_1), label: const Text('Agregar usuario')),
        body: AnimatedBuilder(animation: store, builder: (context, _) {
          final users = store.rows('users');
          return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
            const SectionHeading(title: 'Usuarios', subtitle: 'Perfiles y estado de acceso'),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF4DD), borderRadius: BorderRadius.circular(12)), child: const Text('Versión de demostración: las cuentas utilizan la contraseña 1234. Configura autenticación real antes de usar datos de producción.', style: TextStyle(fontSize: 12, color: Color(0xFF7B571A)))),
            const SizedBox(height: 12),
            for (final user in users)
              Padding(padding: const EdgeInsets.only(bottom: 9), child: Card(child: ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFFE7F0FC), child: Icon(user['active'] == false ? Icons.person_off_outlined : Icons.person_outline, color: primaryBlue)),
                title: Text(user['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
                subtitle: Text('@${user['username']} · ${user['role']}\nEstado: ${user['active'] == false ? 'Inactivo' : 'Activo'}'),
                isThreeLine: true,
                trailing: IconButton(onPressed: () => _edit(context, row: user), icon: const Icon(Icons.edit_outlined), tooltip: 'Editar usuario'),
              ))),
          ]);
        }),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    Color color = primaryBlue;
    if (text.toLowerCase().contains('operativa') || text.toLowerCase().contains('realizado') || text.toLowerCase().contains('comprado') || text.toLowerCase() == 'finalizada') color = const Color(0xFF1C8565);
    if (text.toLowerCase().contains('detenida') || text.toLowerCase().contains('pendiente') || text.toLowerCase().contains('mantenimiento')) color = const Color(0xFFB45E12);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(30)), child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)));
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)), child: Column(children: [const Icon(Icons.inbox_outlined, size: 34, color: mutedInk), const SizedBox(height: 8), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: mutedInk))]));
}

enum FieldType { text, number, dropdown }

class FormFieldSpec {
  const FormFieldSpec(this.keyName, this.label, {this.type = FieldType.text, this.required = false, this.options = const {}, this.initial});
  final String keyName;
  final String label;
  final FieldType type;
  final bool required;
  final Map<String, String> options;
  final String? initial;
}

Future<Map<String, dynamic>?> showRecordDialog(BuildContext context, {required String title, required List<FormFieldSpec> fields, Map<String, dynamic>? initial}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => RecordDialog(title: title, fields: fields, initial: initial ?? const {}),
  );
}

class RecordDialog extends StatefulWidget {
  const RecordDialog({super.key, required this.title, required this.fields, required this.initial});
  final String title;
  final List<FormFieldSpec> fields;
  final Map<String, dynamic> initial;
  @override
  State<RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<RecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _values = {};

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      final raw = widget.initial[field.keyName]?.toString() ?? field.initial ?? '';
      if (field.type == FieldType.dropdown) {
        _values[field.keyName] = field.options.containsKey(raw) ? raw : (field.options.isNotEmpty ? field.options.keys.first : null);
      } else {
        _controllers[field.keyName] = TextEditingController(text: raw == 'null' ? '' : raw);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) { controller.dispose(); }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final result = <String, dynamic>{};
    for (final field in widget.fields) {
      if (field.type == FieldType.dropdown) {
        result[field.keyName] = _values[field.keyName];
      } else if (field.type == FieldType.number) {
        final text = _controllers[field.keyName]!.text.trim();
        result[field.keyName] = double.tryParse(text) ?? int.tryParse(text) ?? 0;
      } else {
        result[field.keyName] = _controllers[field.keyName]!.text.trim();
      }
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 460,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (final field in widget.fields) ...[
                  const SizedBox(height: 10),
                  if (field.type == FieldType.dropdown)
                    DropdownButtonFormField<String>(
                      initialValue: _values[field.keyName],
                      isExpanded: true,
                      decoration: InputDecoration(labelText: field.label),
                      items: field.options.entries.map((entry) => DropdownMenuItem<String>(value: entry.key, child: Text(entry.value, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (value) => setState(() => _values[field.keyName] = value),
                      validator: field.required ? (value) => (value == null || value.isEmpty) ? 'Selecciona ${field.label.toLowerCase()}' : null : null,
                    )
                  else
                    TextFormField(
                      controller: _controllers[field.keyName],
                      keyboardType: field.type == FieldType.number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                      inputFormatters: field.type == FieldType.number ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null,
                      decoration: InputDecoration(labelText: field.label),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (field.required && text.isEmpty) return 'Completa ${field.label.toLowerCase()}';
                        if (field.type == FieldType.number && text.isNotEmpty && double.tryParse(text) == null) return 'Ingresa un número válido';
                        return null;
                      },
                      maxLines: field.keyName.toLowerCase().contains('observ') || field.keyName == 'notes' ? 2 : 1,
                    ),
                ],
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Guardar')),
        ],
      );
}

Future<void> showInfo(BuildContext context, String message) async {
  await showDialog<void>(context: context, builder: (context) => AlertDialog(
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
      ));
}

String todayText() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

double toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String numberText(dynamic value) {
  final number = toDouble(value);
  return number == number.roundToDouble() ? number.toInt().toString() : number.toStringAsFixed(1);
}

String formatDateTime(dynamic value) {
  if (value == null) return 'No registrado';
  final date = DateTime.tryParse(value.toString());
  if (date == null) return value.toString();
  final dateText = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  if (value.toString().contains('T')) return '$dateText ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  return dateText;
}

String durationText(dynamic start, dynamic end) {
  final startDate = DateTime.tryParse(start?.toString() ?? '');
  final endDate = DateTime.tryParse(end?.toString() ?? '');
  if (startDate == null || endDate == null || endDate.isBefore(startDate)) return 'No disponible';
  final duration = endDate.difference(startDate);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '$hours h $minutes min';
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
