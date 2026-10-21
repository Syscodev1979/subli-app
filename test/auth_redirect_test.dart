import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/app/auth_redirect.dart';
import 'package:gastroyal_karate_app/app/constants.dart';

void main() {
  test('kijelentkezve csak a belépés és a regisztráció érhető el', () {
    expect(
      authRedirect(
        phase: AuthPhase.signedOut,
        canReviewMembers: false,
        location: AppRoutes.feed,
      ),
      AppRoutes.login,
    );
    expect(
      authRedirect(
        phase: AuthPhase.signedOut,
        canReviewMembers: false,
        location: AppRoutes.register,
      ),
      isNull,
    );
  });

  test('pending és elutasított fiók a várakozó képernyőn marad', () {
    for (final phase in [AuthPhase.pending, AuthPhase.rejected]) {
      expect(
        authRedirect(
          phase: phase,
          canReviewMembers: false,
          location: AppRoutes.feed,
        ),
        AppRoutes.pending,
      );
      expect(
        authRedirect(
          phase: phase,
          canReviewMembers: false,
          location: AppRoutes.pending,
        ),
        isNull,
      );
    }
  });

  test('aktív sportoló nem nyitja meg az adminisztrációt', () {
    expect(
      authRedirect(
        phase: AuthPhase.active,
        canReviewMembers: false,
        location: AppRoutes.admin,
      ),
      AppRoutes.feed,
    );
    expect(
      authRedirect(
        phase: AuthPhase.active,
        canReviewMembers: true,
        location: AppRoutes.admin,
      ),
      isNull,
    );
  });

  test('aktív felhasználó megnyithatja a bejegyzést', () {
    expect(
      authRedirect(
        phase: AuthPhase.active,
        canReviewMembers: false,
        location: AppRoutes.feedPost('post-1'),
      ),
      isNull,
    );
    expect(
      authRedirect(
        phase: AuthPhase.pending,
        canReviewMembers: false,
        location: AppRoutes.newPost,
      ),
      AppRoutes.pending,
    );
  });

  test('aktív felhasználó a hírfolyamra kerül a belépő képernyőkről', () {
    expect(
      authRedirect(
        phase: AuthPhase.active,
        canReviewMembers: false,
        location: AppRoutes.login,
      ),
      AppRoutes.feed,
    );
  });
}
