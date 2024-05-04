import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  // Menjalankan aplikasi dengan menjalankan MyApp
  runApp(MyApp());
}

// Kelas University untuk mewakili data universitas
class University {
  final String name;
  final List<String> website;

  // Konstruktor untuk kelas University
  University({required this.name, required this.website});

  // Membuat objek University dari data JSON
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      website: List<String>.from(json['web_pages']),
    );
  }
}

// Kelas abstrak untuk event yang akan ditangani oleh UniversityBloc
abstract class DataEvent {}

// Event untuk memilih negara
class SelectCountryEvent extends DataEvent {
  final String country;

  // Konstruktor untuk event SelectCountryEvent
  SelectCountryEvent(this.country);
}

// Event untuk mengambil data universitas
class FetchUniversitiesEvent extends DataEvent {
  final String country;

  // Konstruktor untuk event FetchUniversitiesEvent
  FetchUniversitiesEvent(this.country);
}

// Kelas untuk menyimpan state terkait universitas
class UniversityState {
  final List<University> universities;
  final bool isLoading;
  final String error;
  final String selectedCountry;

  // Konstruktor untuk UniversityState dengan nilai default
  UniversityState({
    this.universities = const [],
    this.isLoading = false,
    this.error = '',
    this.selectedCountry = 'Indonesia',
  });

  // Metode copyWith untuk membuat salinan UniversityState dengan perubahan yang diinginkan
  UniversityState copyWith({
    List<University>? universities,
    bool? isLoading,
    String? error,
    String? selectedCountry,
  }) {
    return UniversityState(
      universities: universities ?? this.universities,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedCountry: selectedCountry ?? this.selectedCountry,
    );
  }
}

// Kelas BLoC untuk mengelola state dan event terkait universitas
class UniversityBloc extends Bloc<DataEvent, UniversityState> {
  // Konstruktor untuk UniversityBloc dengan state awal
  UniversityBloc() : super(UniversityState()) {
    // Event handler untuk memilih negara
    on<SelectCountryEvent>((event, emit) {
      // Memperbarui negara yang dipilih dan memicu event FetchUniversitiesEvent
      emit(state.copyWith(selectedCountry: event.country));
      add(FetchUniversitiesEvent(event.country));
    });

    // Event handler untuk mengambil data universitas
    on<FetchUniversitiesEvent>((event, emit) async {
      // Memulai proses pengambilan data dengan menandai status sebagai pemuatan
      emit(state.copyWith(isLoading: true));
      try {
        // Membuat permintaan HTTP untuk mendapatkan data universitas
        final response = await http.get(Uri.parse(
            'http://universities.hipolabs.com/search?country=${event.country}'));

        // Memeriksa status kode HTTP respons
        if (response.statusCode == 200) {
          // Mendekode respons JSON menjadi daftar objek
          List jsonResponse = json.decode(response.body);
          // Mengubah daftar JSON menjadi daftar objek University
          List<University> universities =
              jsonResponse.map((univ) => University.fromJson(univ)).toList();

          // Mengubah status state dengan universitas yang diambil dan mengakhiri pemuatan
          emit(state.copyWith(
              universities: universities, isLoading: false, error: ''));
        } else {
          // Mengubah status state dengan pesan kesalahan jika respons tidak sukses
          emit(state.copyWith(
            error: 'Failed to load universities',
            isLoading: false,
          ));
        }
      } catch (e) {
        // Mengubah status state dengan pesan kesalahan jika terjadi pengecualian
        emit(state.copyWith(
          error: 'Failed to load universities',
          isLoading: false,
        ));
      }
    });
  }
}

// Komponen utama aplikasi Flutter
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UniversityBloc(),
      child: MaterialApp(
        title: 'Universities in ASEAN',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: UniversityList(),
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
      body: Column(
        children: [
          // Dropdown untuk memilih negara
          Padding(
            padding: EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: context.watch<UniversityBloc>().state.selectedCountry,
              onChanged: (newCountry) {
                // Menambahkan event SelectCountryEvent dengan negara yang dipilih
                context
                    .read<UniversityBloc>()
                    .add(SelectCountryEvent(newCountry!));
              },
              items: countries.map((String country) {
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
            ),
          ),
          // Expanded widget untuk menampilkan data universitas
          Expanded(
            child: BlocBuilder<UniversityBloc, UniversityState>(
              builder: (context, state) {
                if (state.isLoading) {
                  // Menampilkan CircularProgressIndicator saat data sedang diambil
                  return Center(child: CircularProgressIndicator());
                } else if (state.error.isNotEmpty) {
                  // Menampilkan pesan kesalahan jika ada error
                  return Center(child: Text('Error: ${state.error}'));
                } else {
                  // Menampilkan daftar universitas jika tidak ada error dan data sudah diambil
                  return ListView.builder(
                    itemCount: state.universities.length,
                    itemBuilder: (context, index) {
                      University university = state.universities[index];
                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: Icon(Icons.school, color: Colors.blue),
                          title: Text(university.name,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle:
                              Text('Website: ${university.website.join(', ')}'),
                          trailing: IconButton(
                            icon: Icon(Icons.open_in_new, color: Colors.blue),
                            onPressed: () {
                              // Implementasi membuka website universitas
                              // Anda dapat menggunakan package seperti url_launcher untuk membuka URL
                            },
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
