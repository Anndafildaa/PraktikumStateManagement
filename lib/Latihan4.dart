import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class University {
  final String name;
  final List<String> website;

  // Constructor untuk kelas University
  University({required this.name, required this.website});

  // Fungsi untuk membuat objek University dari JSON
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      website: List<String>.from(json['web_pages']),
    );
  }
}

class UniversityProvider extends ChangeNotifier {
  List<University> universities = [];
  String selectedCountry = 'Indonesia';
  bool isLoading = false;
  String error = '';

  // Metode untuk mengambil data universitas berdasarkan negara
  Future<void> fetchUniversities(String country) async {
    // Menandai bahwa proses pengambilan data sedang berlangsung
    isLoading = true;
    notifyListeners();

    try {
      // Membuat permintaan HTTP untuk API dengan parameter negara yang diberikan
      final response = await http.get(Uri.parse(
          'http://universities.hipolabs.com/search?country=$country'));

      // Memeriksa apakah permintaan HTTP berhasil (status kode 200)
      if (response.statusCode == 200) {
        // Mendekode respons JSON dari API menjadi daftar objek JSON
        List jsonResponse = json.decode(response.body);

        // Mengonversi daftar JSON menjadi daftar objek University dan menyimpannya
        universities =
            jsonResponse.map((univ) => University.fromJson(univ)).toList();

        // Menghapus pesan kesalahan jika permintaan berhasil
        error = '';
      } else {
        // Menyimpan pesan kesalahan jika respons HTTP tidak sukses
        error = 'Failed to load universities';
      }
    } catch (e) {
      // Menangani pengecualian yang terjadi selama permintaan HTTP dan menyimpan pesan kesalahan
      error = 'Failed to load universities';
    }

    // Menandai bahwa proses pengambilan data telah selesai
    isLoading = false;
    notifyListeners();
  }

  // Metode untuk mengatur negara yang dipilih oleh pengguna
  void setCountry(String country) {
    selectedCountry = country;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UniversityProvider(),
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

class UniversityList extends StatelessWidget {
  // Daftar negara ASEAN yang akan ditampilkan dalam dropdown
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
    // Mendapatkan instance dari provider
    final provider = Provider.of<UniversityProvider>(context);

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
              value: provider.selectedCountry,
              onChanged: (newCountry) {
                // Mengatur negara yang dipilih oleh pengguna
                provider.setCountry(newCountry!);
                // Mengambil data universitas untuk negara yang dipilih
                provider.fetchUniversities(newCountry);
              },
              // Daftar negara yang akan ditampilkan dalam dropdown
              items: countries.map((String country) {
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
            ),
          ),
          // Menampilkan daftar universitas atau status pemuatan
          Expanded(
            child: provider.isLoading
                ? Center(child: CircularProgressIndicator())
                : provider.error.isNotEmpty
                    ? Center(child: Text('Error: ${provider.error}'))
                    : ListView.builder(
                        itemCount: provider.universities.length,
                        itemBuilder: (context, index) {
                          // Mendapatkan objek University dari daftar
                          University university = provider.universities[index];
                          return Card(
                            margin: EdgeInsets.all(8.0),
                            child: ListTile(
                              // Ikon sekolah di sebelah kiri
                              leading: Icon(Icons.school, color: Colors.blue),
                              // Nama universitas
                              title: Text(university.name,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              // Situs web universitas
                              subtitle: Text(
                                  'Website: ${university.website.join(', ')}'),
                              // Tombol untuk membuka situs web universitas
                              trailing: IconButton(
                                icon:
                                    Icon(Icons.open_in_new, color: Colors.blue),
                                onPressed: () {},
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
