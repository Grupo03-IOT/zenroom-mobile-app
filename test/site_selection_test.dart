import 'package:flutter_test/flutter_test.dart';
import 'package:zenroom/app/app_controller.dart';
import 'package:zenroom/features/identity/domain/session.dart';

void main() {
  test('a member can switch sites and only sees rooms at that site', () async {
    final controller = AppController();
    addTearDown(controller.dispose);

    await controller.signIn(
      'member@example.com',
      '',
      demoRole: UserRole.member,
    );
    expect(controller.admin, isFalse);
    expect(controller.sites, hasLength(2));
    expect(controller.visibleRooms, isNotEmpty);
    expect(
      controller.visibleRooms.every((room) => room.siteId == 'demo-site'),
      isTrue,
    );

    controller.selectSite(controller.sites.last);
    expect(controller.selectedSite?.name, 'San Isidro Hub');
    expect(controller.visibleRooms, hasLength(1));
    expect(controller.visibleRooms.single.siteId, 'demo-site-2');

    await controller.refresh();
    expect(controller.selectedSite?.id, 'demo-site-2');
    expect(controller.visibleRooms, hasLength(1));
  });
}
