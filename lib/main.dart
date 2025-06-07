import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Digunakan untuk SocketException
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- MODEL DATA ---
// Model untuk merepresentasikan data 'Todo'
class Todo {
  final int id;
  final int userId;
  final String title;
  final bool completed;

  Todo({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      completed: json['completed'],
    );
  }
}

// --- FUNGSI UTAMA & APLIKASI ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Todos',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const TodoListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- HALAMAN UTAMA ---
class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  // --- STATE MANAGEMENT SEDERHANA ---
  List<Todo> _todos = []; // Menyimpan data asli dari API
  String? _error; // Menyimpan pesan error jika ada
  bool _isLoading = true; // Status loading data awal

  @override
  void initState() {
    super.initState();
    _fetchData(); // Ambil data saat halaman pertama kali dibuka
  }

  // --- LOGIKA PENGAMBILAN DATA ---
  Future<void> _fetchData() async {
    // Set state untuk menampilkan loading indicator
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await http
          .get(Uri.parse('https://jsonplaceholder.typicode.com/todos/'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _todos = body.map((dynamic item) => Todo.fromJson(item)).toList();
          });
        }
      } else {
        // Log status code untuk debugging
        print('HTTP Error Status: ${response.statusCode}');
        print('HTTP Error Body: ${response.body}');
        throw Exception('Gagal memuat data. Status: ${response.statusCode}');
      }
    } on SocketException {
      _error = 'Tidak ada koneksi internet. Periksa jaringan Anda.';
    } on TimeoutException {
      _error = 'Koneksi timeout. Server tidak merespons.';
    } catch (e) {
      // Log error yang lebih detail
      print('Caught error: $e');
      _error = 'Terjadi kesalahan: ${e.toString()}';
    } finally {
      // Sembunyikan loading indicator setelah selesai
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- WIDGET BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas'),
      ),
      body: _buildBody(),
    );
  }

  // Fungsi untuk membangun body utama berdasarkan state
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildStatusWidget(
        icon: Icons.error_outline,
        message: _error!,
        onRetry: _fetchData,
      );
    }
    if (_todos.isEmpty) {
      return _buildStatusWidget(
        icon: Icons.assignment_turned_in_outlined,
        message: 'Tidak ada tugas yang ditemukan.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _todos.length,
        itemBuilder: (context, index) {
          final todo = _todos[index];
          return Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: Icon(
                todo.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: todo.completed ? Colors.green : Colors.grey,
              ),
              title: Text(
                todo.title,
                style: TextStyle(
                  decoration: todo.completed ? TextDecoration.lineThrough : null,
                  color: todo.completed ? Colors.grey : null,
                ),
              ),
              subtitle: Text('User ID: ${todo.userId}'),
            ),
          );
        },
      ),
    );
  }

  // Widget untuk menampilkan status (error atau kosong)
  Widget _buildStatusWidget({required IconData icon, required String message, VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}