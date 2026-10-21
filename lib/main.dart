import 'package:flutter/material.dart';
import 'models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BancoDinamicoApp());
}

class BancoDinamicoApp extends StatelessWidget {
  const BancoDinamicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banco Dinâmico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ListasPage(),
    );
  }
}

class ListasPage extends StatefulWidget {
  const ListasPage({super.key});

  @override
  State<ListasPage> createState() => _ListasPageState();
}

class _ListasPageState extends State<ListasPage> {
  // Lista inicial de exemplo ou carregada do banco
  List<ListaEntidades> listas = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banco Dinâmico'),
        centerTitle: true,
      ),
      body: listas.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma lista encontrada.\nToque no botão + para criar a tua primeira tabela.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: listas.length,
              itemBuilder: (context, index) {
                final lista = listas[index];
                return ListTile(
                  leading: Icon(
                    lista.isLocked ? Icons.lock : Icons.table_chart,
                    color: _obterCorTema(lista.corTema),
                  ),
                  title: Text(lista.titulo),
                  subtitle: Text('${lista.linhas.length} registos'),
                  onTap: () {
                    // Navegar para a grelha de detalhes da lista
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ação para criar nova lista
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _obterCorTema(String tema) {
    switch (tema) {
      case 'verde':
        return Colors.green;
      case 'roxo':
        return Colors.purple;
      case 'cinza':
        return Colors.grey;
      case 'azul':
      default:
        return Colors.blue;
    }
  }
}
