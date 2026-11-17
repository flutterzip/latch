import 'package:flutter/material.dart';

import '../../config/brand.dart';
import '../../widgets/widgets.dart';
import '../sign_in/sign_in_screen.dart';
import '../sign_up/sign_up_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final keeper = KeeperController();

  @override
  void initState() {
    super.initState();
    keeper.later(Motion.entrance, keeper.wave);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(AppBrand.name, style: text.titleMedium),
              const Spacer(),
              GestureDetector(
                onTap: keeper.cheer,
                child: Hero(tag: 'keeper', child: Keeper(controller: keeper, size: 230)),
              ),
              const Spacer(),
              Entrance(
                delay: const Duration(milliseconds: 200),
                children: [
                  Text(AppBrand.tagline, style: text.displaySmall, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(
                    'One account for everything. Sign in once and pick up right where you left off.',
                    style: text.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  LatchButton(
                    label: 'Create account',
                    onPressed: () => context.open(const SignUpScreen()),
                  ),
                  const SizedBox(height: 12),
                  LatchButton.ghost(
                    label: 'I already have an account',
                    onPressed: () => context.open(const SignInScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    keeper.dispose();
    super.dispose();
  }
}
