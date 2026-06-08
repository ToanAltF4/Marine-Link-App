# MarineLink Manual Demo Path

Use this checklist for the PM review demo. Run it after `dev` is synced and the backend/frontend verification commands pass.

## Automated Smoke Coverage

- Frontend app path: `flutter test test/app/manual_demo_path_smoke_test.dart`
- Notification UI path: `flutter test test/features/notifications/notification_screens_test.dart`
- Full frontend suite: `flutter test`
- Backend smoke/regression suite: `mvn -q -B -ntp clean verify`

## Buyer Flow

1. Login as `daily-a@marinelink.demo` with the documented demo password.
2. Open product list, search/browse products, and add an in-stock product to cart.
3. Open checkout, fill receiver name, phone, address, payment method, and submit.
4. Confirm the success panel appears, then open the order list.
5. Open notifications and verify unread/read grouping is visible.
6. Open buyer chat and send a non-empty support message.

## Admin Flow

1. Login as `admin@marinelink.demo` with the documented demo password.
2. Verify the dashboard summary, pending orders, revenue, low-stock, and active user cards load.
3. Open product management and verify list/filter/create/edit/delete controls are reachable.
4. Open user management and verify role/status filters and pending approval actions are reachable.
5. Open order management and verify status filters/actions are reachable.

## Staff Flow

1. Login as `staff@marinelink.demo` with the documented demo password.
2. Open staff orders and verify the same order status workflow used by admin is available.
3. Open staff chat, filter rooms, reply to a user, close/reopen a room, and create a complaint from a chat room.
4. Open warehouses and verify map/list fallback plus Google Maps launch action.

## Review Notes

- Do not print tokens or `.env` values while demoing.
- Use Jira Backlog tasks only for new work; do not take tasks already In Progress unless they are assigned to you.
- Move a Jira Story to Done only after its PR is merged into `dev`.
