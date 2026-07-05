// Provider port for push notification delivery (docs/planning/03-backend-
// architecture.md §7 — payments/maps/push all sit behind a port interface,
// with the concrete adapter chosen by the deployment's config, mirroring the
// PaymentPort pattern already documented there). Real APNs delivery needs
// Apple Developer credentials (a signing key, bundle id, device tokens) not
// available in this environment — the same class of external-service gap as
// real GoTrue-backed auth (see backend/supabase/functions/_shared/auth.ts's
// header). LoggingPushAdapter is the only implementation here: it never
// contacts a real device, just records what would have been sent, so the
// orchestration around it (notifications_service.ts) is fully real and
// testable even though delivery isn't. A production deployment swaps in an
// APNsPushAdapter without changing any caller of PushPort.

export interface PushMessage {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, unknown>;
}

export interface PushPort {
  send(message: PushMessage): Promise<{ delivered: boolean }>;
}

export class LoggingPushAdapter implements PushPort {
  send(message: PushMessage): Promise<{ delivered: boolean }> {
    console.log(`[push:noop] would deliver to user ${message.userId}: "${message.title}" — ${message.body}`);
    return Promise.resolve({ delivered: true });
  }
}
