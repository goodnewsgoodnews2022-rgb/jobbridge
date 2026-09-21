import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'brand_logo.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final role = auth.role;
    final loggedIn = auth.isLoggedIn;

    final links = <_NavLink>[
      _NavLink('Home', '/'),
      _NavLink('All Jobs', '/jobs'),
      _NavLink('Remote', '/remote-jobs'),
      _NavLink('Nigeria', '/nigeria-jobs'),
      _NavLink('Categories', '/categories'),
    ];

    final userLinks = <_NavLink>[
      if (role == 'company') ...[
        _NavLink('Dashboard', '/company/dashboard'),
        _NavLink('My Jobs', '/company/jobs'),
        _NavLink('Post Job', '/company/jobs/create'),
        _NavLink('Applications', '/company/applications'),
      ] else if (role == 'job_seeker') ...[
        _NavLink('Dashboard', '/job-seeker/dashboard'),
        _NavLink('Saved', '/job-seeker/saved-jobs'),
        _NavLink('Applications', '/job-seeker/applications'),
        _NavLink('Profile', '/job-seeker/profile'),
      ],
    ];

    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: const BrandLogo(size: 32),
              actions: [
                IconButton(
                  onPressed: () => _openDrawer(context, links, userLinks, loggedIn, ref),
                  icon: const Icon(Icons.menu),
                ),
              ],
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const BrandLogo(size: 36),
                    const Divider(height: 32),
                    ...links.map((l) => ListTile(
                          title: Text(l.label),
                          onTap: () {
                            Navigator.pop(context);
                            context.go(l.route);
                          },
                        )),
                    if (userLinks.isNotEmpty) ...[
                      const Divider(height: 32),
                      ...userLinks.map((l) => ListTile(
                            title: Text(l.label),
                            onTap: () {
                              Navigator.pop(context);
                              context.go(l.route);
                            },
                          )),
                    ],
                    const Divider(height: 32),
                    if (loggedIn)
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Sign Out'),
                        onTap: () async {
                          Navigator.pop(context);
                          await ref.read(authStateProvider).signOut();
                          if (context.mounted) context.go('/');
                        },
                      )
                    else ...[
                      ListTile(
                        title: const Text('Sign In'),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/login');
                        },
                      ),
                      ListTile(
                        title: const Text('Register'),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/register');
                        },
                      ),
                    ],
                  ],
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          if (!isMobile) _DesktopNav(links: links, userLinks: userLinks, ref: ref),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _openDrawer(BuildContext c, List<_NavLink> l, List<_NavLink> u, bool loggedIn, WidgetRef ref) {
    Scaffold.of(c).openDrawer();
  }
}

class _DesktopNav extends StatelessWidget {
  final List<_NavLink> links;
  final List<_NavLink> userLinks;
  final WidgetRef ref;
  const _DesktopNav({required this.links, required this.userLinks, required this.ref});

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final loc = GoRouterState.of(context).matchedLocation;

    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/'),
            child: const BrandLogo(size: 36),
          ),
          const SizedBox(width: 40),
          ...links.map((l) => _navItem(context, l, loc == l.route)),
          const Spacer(),
          if (!auth.isLoggedIn) ...[
            TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign In')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => context.go('/register'),
              child: const Text('Get Started'),
            ),
          ] else ...[
            ...userLinks.map((l) => _navItem(context, l, loc == l.route)),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              offset: const Offset(0, 44),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  (auth.displayName ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              onSelected: (v) async {
                if (v == 'signout') {
                  await ref.read(authStateProvider).signOut();
                  if (context.mounted) context.go('/');
                } else if (v == 'profile') {
                  context.go(auth.role == 'company'
                      ? '/company/dashboard'
                      : '/job-seeker/profile');
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'profile', child: Text('Profile')),
                PopupMenuItem(value: 'signout', child: Text('Sign Out')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, _NavLink l, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => context.go(l.route),
        style: TextButton.styleFrom(
          foregroundColor:
              active ? const Color(0xFF2563EB) : const Color(0xFF475569),
        ),
        child: Text(l.label,
            style: TextStyle(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }
}

class _NavLink {
  final String label;
  final String route;
  _NavLink(this.label, this.route);
}