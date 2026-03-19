import 'package:flutter/material.dart';

class TelaTermosCondicoes extends StatelessWidget {
  static const route = '/termos-condicoes';

  const TelaTermosCondicoes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos e Condições'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(),
            const SizedBox(height: 20),
            _sectionCard(
              icon: Icons.info_outline,
              title: '1. Sobre a plataforma',
              content:
                  'A COGITARE é uma plataforma que conecta cuidadores, responsáveis e idosos, facilitando o contato, a organização de informações e a gestão de cuidados.',
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.person_outline,
              title: '2. Cadastro e responsabilidade do usuário',
              content:
                  'Ao criar uma conta, o usuário declara que as informações fornecidas são verdadeiras e atualizadas. Cada usuário é responsável pela segurança de sua conta, incluindo e-mail, senha e dados pessoais cadastrados.',
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.privacy_tip_outlined,
              title: '3. Privacidade e dados pessoais',
              content:
                  'Os dados informados na plataforma são utilizados para viabilizar o funcionamento do aplicativo, melhorar a experiência do usuário e permitir a comunicação entre as partes. A COGITARE se compromete a tratar essas informações com responsabilidade e segurança.',
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.shield_outlined,
              title: '4. Uso adequado da plataforma',
              content:
                  'É proibido utilizar a plataforma para fins ilícitos, fraudulentos, ofensivos ou que prejudiquem outros usuários. O uso inadequado poderá resultar em suspensão ou exclusão da conta.',
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.handshake_outlined,
              title: '5. Relação entre usuários',
              content:
                  'A COGITARE atua como intermediadora da conexão entre os usuários. A responsabilidade pelas informações fornecidas, acordos realizados e condutas adotadas entre cuidador e responsável pertence às partes envolvidas.',
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.edit_note_outlined,
              title: '6. Alterações nos termos',
              content:
                  'Os termos e condições podem ser atualizados a qualquer momento para refletir melhorias na plataforma, adequações legais ou mudanças no funcionamento do serviço.',
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.logout_outlined,
              title: '7. Encerramento da conta',
              content:
                  'O usuário pode deixar de utilizar a plataforma a qualquer momento. Em casos de violação destes termos, a COGITARE poderá restringir ou encerrar o acesso à conta.',
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.gavel_outlined,
              title: '8. Aceite',
              content:
                  'Ao utilizar a plataforma, o usuário declara estar ciente e de acordo com estes Termos e Condições de Uso.',
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ao continuar usando o app, você concorda com estes termos e com as regras de uso da plataforma.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade100,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.description_outlined, size: 36),
          SizedBox(height: 12),
          Text(
            'Termos e Condições da COGITARE',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Leia com atenção as condições de uso da plataforma e as responsabilidades dos usuários.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}