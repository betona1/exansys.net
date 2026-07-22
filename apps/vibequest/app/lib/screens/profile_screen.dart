import 'package:flutter/material.dart';

/// 내 기록 — V3에서 주간 활동·카테고리 숙련도가 붙는다.
/// 정답률을 전면에 크게 표시하지 않는다 (§11.6).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 기록')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Card(
            child: ListTile(
              leading: Text('📅', style: TextStyle(fontSize: 26)),
              title: Text('주간 학습', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('학습을 시작하면 여기에 기록이 쌓여요.'),
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Text('⚙️', style: TextStyle(fontSize: 26)),
              title: Text('설정', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('소리·진동·모션 설정은 다음 업데이트에서 열려요.'),
            ),
          ),
        ],
      ),
    );
  }
}
