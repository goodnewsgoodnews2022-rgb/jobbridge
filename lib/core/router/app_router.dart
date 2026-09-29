import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobbridge/features/company/company/screens/company_applications_screen.dart';
import 'package:jobbridge/features/company/company/screens/manage_jobs_screen.dart';
import 'package:jobbridge/features/company/company/screens/post_job_screen.dart';
import 'package:jobbridge/features/company/screens/screens/company_dashboard_screen.dart';
import '../../features/payments/screens/checkout_screen.dart';
import '../../features/payments/screens/payment_pending_screen.dart';
import '../../features/resume/screens/resume_landing_screen.dart';
import '../../features/resume/screens/resume_builder_screen.dart';
import '../../features/resume/screens/resume_preview_screen.dart';
import '../../features/resume/screens/my_resumes_screen.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_type_screen.dart';
import '../../features/auth/screens/job_seeker_register_screen.dart';
import '../../features/auth/screens/company_register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/jobs/screens/all_jobs_screen.dart';
import '../../features/jobs/screens/remote_jobs_screen.dart';
import '../../features/jobs/screens/nigeria_jobs_screen.dart';
import '../../features/jobs/screens/job_details_screen.dart';
import '../../features/jobs/screens/search_screen.dart';
import '../../features/jobs/screens/categories_screen.dart';
import '../../features/jobs/screens/category_jobs_screen.dart';
import '../../features/company/screens/company_profile_screen.dart';

import '../../features/job_seeker/screens/job_seeker_dashboard_screen.dart';
import '../../features/job_seeker/screens/saved_jobs_screen.dart';
import '../../features/job_seeker/screens/applications_screen.dart';
import '../../features/job_seeker/screens/job_seeker_profile_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../features/payments/screens/pricing_screen.dart';



final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final user = auth.currentUser;
      final role = auth.role;
      final loc = state.matchedLocation;

      final isAuthRoute = loc.startsWith('/login') ||
          loc.startsWith('/register') ||
          loc.startsWith('/forgot-password');

      // Not logged in → private routes redirect
      if (user == null) {
        if (loc.startsWith('/job-seeker') || loc.startsWith('/company')) {
          return '/login';
        }
        return null;
      }

      // Logged in but visiting auth pages → send to their dashboard
      if (isAuthRoute) {
        return role == 'company' ? '/company/dashboard' : '/job-seeker/dashboard';
      }

      // Role guard
      if (loc.startsWith('/company') && role != 'company') {
        return '/job-seeker/dashboard';
      }
      if (loc.startsWith('/job-seeker') && role != 'job_seeker') {
        return '/company/dashboard';
      }
      return null;
    },
    routes: [
      // ---------- PUBLIC ----------
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/jobs', builder: (_, __) => const AllJobsScreen()),
          GoRoute(
              path: '/remote-jobs',
              builder: (_, __) => const RemoteJobsScreen()),
          GoRoute(
            path: '/pricing',
            builder: (_, __) => const PricingScreen(),
          ),
  GoRoute(
  path: '/resume',
  builder: (_, __) => const ResumeLandingScreen(),
),
GoRoute(
  path: '/my-resumes',
  builder: (_, __) => const MyResumesScreen(),
),
GoRoute(
  path: '/resume/create',
  builder: (_, s) =>
      ResumeBuilderScreen(editId: s.uri.queryParameters['editId']),
),
GoRoute(
  path: '/resume/preview',
  builder: (_, s) =>
      ResumePreviewScreen(resumeId: s.uri.queryParameters['id'] ?? ''),
),
          GoRoute(
              path: '/nigeria-jobs',
              builder: (_, __) => const NigeriaJobsScreen()),
          GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
          GoRoute(
            path: '/category/:name',
            builder: (_, s) =>
                CategoryJobsScreen(category: s.pathParameters['name']!),
          ),
          GoRoute(
            path: '/jobs/:id',
            builder: (_, s) => JobDetailsScreen(jobId: s.pathParameters['id']!),
          ),
        GoRoute(
  path: '/companies/:id',
  builder: (_, s) =>
      CompanyProfileScreen(companyId: s.pathParameters['id']!),
),
          GoRoute(
            path: '/search',
            builder: (_, s) =>
                SearchScreen(initialQuery: s.uri.queryParameters['q'] ?? ''),
          ),
        ],
      ),
      GoRoute(
  path: '/company/checkout',
  builder: (_, s) => CheckoutScreen(
    packageId: s.uri.queryParameters['package'] ?? 'job-basic',
    jobId: s.uri.queryParameters['job'],    // ← must be here
  ),
),

      // ---------- AUTH ----------
    GoRoute(
  path: '/login',
  builder: (_, s) => LoginScreen(
    redirect: s.uri.queryParameters['redirect'],
  ),
),
     GoRoute(
  path: '/register',
  builder: (_, s) => RegisterTypeScreen(
    redirect: s.uri.queryParameters['redirect'],
  ),
),
   GoRoute(
  path: '/register/job-seeker',
  builder: (_, s) => JobSeekerRegisterScreen(
    redirect: s.uri.queryParameters['redirect'],
  ),
),
    GoRoute(
  path: '/register/company',
  builder: (_, s) => CompanyRegisterScreen(
    redirect: s.uri.queryParameters['redirect'],
  ),
),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),

      // ---------- JOB SEEKER ----------
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
              path: '/job-seeker/dashboard',
              builder: (_, __) => const JobSeekerDashboardScreen()),
          GoRoute(
              path: '/job-seeker/saved-jobs',
              builder: (_, __) => const SavedJobsScreen()),
          GoRoute(
              path: '/job-seeker/applications',
              builder: (_, __) => const ApplicationsScreen()),
          GoRoute(
              path: '/job-seeker/profile',
              builder: (_, __) => const JobSeekerProfileScreen()),
        ],
      ),

      // ---------- COMPANY ----------
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
              path: '/company/dashboard',
              builder: (_, __) => const CompanyDashboardScreen()),
              GoRoute(
  path: '/company/checkout',
  builder: (_, s) => CheckoutScreen(
    packageId: s.uri.queryParameters['package'] ?? 'job-basic',
  ),
),
GoRoute(
  path: '/company/payment/pending',
  builder: (_, s) => PaymentPendingScreen(
    orderId: s.uri.queryParameters['order'] ?? '',
    reference: s.uri.queryParameters['ref'] ?? '',
  ),
),
          GoRoute(
              path: '/company/jobs',
              builder: (_, __) => const ManageJobsScreen()),
          GoRoute(
              path: '/company/jobs/create',
              builder: (_, __) => const PostJobScreen()),
          GoRoute(
              path: '/company/applications',
              builder: (_, __) => const CompanyApplicationsScreen()),
        ],
      ),
    ],
    errorBuilder: (context, s) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('404', style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
            Text('Page not found: ${s.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => context.go('/'), child: const Text('Go Home')),
          ],
        ),
      ),
    ),
  );
});