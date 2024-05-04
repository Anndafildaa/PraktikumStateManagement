import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';

// Fungsi utama aplikasi
void main() {
  runApp(MyApp());
}

// Kelas untuk mewakili informasi universitas
class University {
  final String name;
  final List<String> website;

  // Konstruktor untuk kelas University
  University({required this.name, required this.website});

  // Membuat objek University dari JSON
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      website: List<String>.from(json['web_pages']),
    );
  }
}

// Kelas untuk menyimpan status aplikasi terkait universitas
class UniversityState {
  final String selectedCountry;
  final List<University> universities;
  final bool isLoading;
  final String error;

  // Konstruktor untuk kelas UniversityState
  UniversityState({
    required this.selectedCountry,
    this.universities = const [],
    this.isLoading = false,
    this.error = '',
  });

  // Membuat salinan UniversityState dengan perubahan yang diinginkan
  UniversityState copyWith({
    String? selectedCountry,
    List<University>? universities,
    bool? isLoading,
    String? error,
  }) {
    return UniversityState(
      selectedCountry: selectedCountry ?? this.selectedCountry,
      universities: universities ?? this.universities,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Kelas untuk mengelola state aplikasi menggunakan BLoC
class UniversityCubit extends Cubit<UniversityState> {
  // Konstruktor untuk kelas UniversityCubit
  UniversityCubit() : super(UniversityState(selectedCountry: 'Indonesia'));

  // Metode untuk memperbarui negara yang dipilih
  void updateCountry(String country) {
    emit(state.copyWith(selectedCountry: country));
  }

  // Metode untuk mengambil data universitas berdasarkan negara yang diberikan
  Future<void> fetchUniversities(String country) async {
    // Memulai proses pengambilan data dengan menandai status sebagai pemuatan
    emit(state.copyWith(isLoading: true));
    try {
      // Membuat permintaan HTTP untuk mendapatkan data universitas
      final response = await http.get(Uri.parse(
          'http://universities.hipolabs.com/search?country=$country'));

      // Memeriksa status kode HTTP respons
      if (response.statusCode == 200) {
        // Mendekode respons JSON menjadi daftar objek
        List jsonResponse = json.decode(response.body);
        // Mengubah daftar JSON menjadi daftar objek University
        List<University> universities =
            jsonResponse.map((univ) => University.fromJson(univ)).toList();
        // Mengubah status state dengan universitas yang diambil dan mengakhiri pemuatan
        emit(state.copyWith(universities: universities, isLoading: false));
      } else {
        // Mengubah status state dengan pesan kesalahan jika respons tidak sukses
        emit(state.copyWith(
            error: 'Failed to load universities', isLoading: false));
      }
    } catch (e) {
      // Mengubah status state dengan pesan kesalahan jika terjadi pengecualian
      emit(state.copyWith(
          error: 'Failed to load universities', isLoading: false));
    }
  }
}

// Komponen utama aplikasi Flutter
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universities in ASEAN',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Menggunakan BlocProvider untuk UniversityCubit
      home: BlocProvider(
        create: (_) => UniversityCubit(),
        child: UniversityList(),
      ),
    );
  }
}

// Komponen untuk menampilkan daftar universitas
class UniversityList extends StatelessWidget {
  // Daftar negara ASEAN yang lengkap
  final List<String> countries = [
    'Indonesia',
    'Singapore',
    'Malaysia',
    'Thailand',
    'Philippines',
    'Vietnam',
    'Brunei',
    'Myanmar',
    'Laos',
    'Cambodia'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Universities in ASEAN'),
      ),
      body: BlocBuilder<UniversityCubit, UniversityState>(
        builder: (context, state) {
          return Column(
            children: [
              // Dropdown untuk memilih negara
              Padding(
                padding: EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: state.selectedCountry,
                  onChanged: (newCountry) {
                    // Memperbarui negara yang dipilih
                    context.read<UniversityCubit>().updateCountry(newCountry!);
                    // Mengambil data universitas berdasarkan negara baru
                    context
                        .read<UniversityCubit>()
                        .fetchUniversities(newCountry);
                  },
                  items: countries.map((String country) {
                    return DropdownMenuItem<String>(
                      value: country,
                      child: Text(country),
                    );
                  }).toList(),
                ),
              ),
              // Bagian untuk menampilkan data atau status pemuatan
              Expanded(
                child: state.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : state.error.isNotEmpty
                        ? Center(child: Text('Error: ${state.error}'))
                        : ListView.builder(
                            itemCount: state.universities.length,
                            itemBuilder: (context, index) {
                              University university = state.universities[index];
                              return Card(
                                margin: EdgeInsets.all(8.0),
                                child: ListTile(
                                  leading:
                                      Icon(Icons.school, color: Colors.blue),
                                  title: Text(university.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      'Website: ${university.website.join(', ')}'),
                                  trailing: IconButton(
                                    icon: Icon(Icons.open_in_new,
                                        color: Colors.blue),
                                    onPressed: () {
                                      // Implementasi membuka website universitas
                                      // Anda dapat menggunakan paket seperti url_launcher untuk membuka URL
                                      if (university.website.isNotEmpty) {
                                        // Buka URL pertama di daftar website universitas
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
