import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ThanksView extends StatelessWidget {
  const ThanksView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF92ABFB),
                  Color(0xFF3360F6),
                ],
              ),
            ),
            child: Image.asset('assets/background.png'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Image.asset('assets/logo.png'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        "Tele-Consulta",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                // Formulários
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: [
                          Text(
                            "Obrigado",
                            style: TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              "Sua chamada foi finalizada, obrigado pela utilização de nosso serviço.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEBEAFB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Nova chamada",
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF2a2a2a),
                        ),
                      ),
                      onPressed: () async {
                        context.go('/');
                      },
                    ),
                  ],
                ),

                // Footer
                const Text(
                  'www.neurondata.com.br',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
