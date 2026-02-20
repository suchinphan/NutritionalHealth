import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SearchMainPage extends StatelessWidget {
	const SearchMainPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('ค้นหา'),
				actions: [
					Builder(builder: (_) {
						final auth = AuthService();
						final idText = auth.isGuest ? 'Guest' : (auth.user != null ? (auth.user!['username'] ?? auth.user!['name'] ?? auth.user!['id']?.toString() ?? 'User') : 'User');
						return Padding(padding: const EdgeInsets.only(right:12.0), child: Center(child: Text(idText.toString(), style: TextStyle(color: Colors.white))));
					}),
				],
			),
			body: Padding(
				padding: const EdgeInsets.all(12.0),
				child: Column(
					children: [
						TextField(enabled: !AuthService().isGuestLocked, decoration: InputDecoration(hintText: 'ค้นหาอาหารหรือเมนู', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
						const SizedBox(height: 12),
						Expanded(
							child: Center(child: Text('ผลการค้นหาจะแสดงที่นี่', style: TextStyle(color: Colors.grey[600]))),
						),
					],
				),
			),
		);
	}
}
