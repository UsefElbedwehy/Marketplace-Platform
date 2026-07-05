/**
 * AUTO-GENERATED — do not edit by hand.
 * Source: contract/schema/*.schema.json and contract/openapi/v1/openapi.yaml
 * Regenerate: npm run generate --workspace=packages/contract-types
 * See contract/README.md for what these files mean.
 */

/**
 * Backend-driven configuration fetched by clients at boot (GET /v1/config). Dashboard-editable without a rebuild: locales, currencies, countries, feature flags/modules, provider selection, links, legal, support. See docs/planning/07-configuration-whitelabel-theme.md and ADR-0004. This is deep-merged: configs/clients/default/config.json <- configs/clients/<client>/config.json <- configs/<env>/config.json.
 */
export interface RuntimeConfig {
  schemaFormatVersion: string;
  /**
   * Identifier matching a configs/clients/<slug> directory name. Accepts kebab-case or snake_case (the project foundation uses client_a/client_b/client_c).
   */
  clientId: string;
  /**
   * Bumped by the backend on every published change; drives client ETag/cache invalidation. Absent in static seed files (assigned when the backend stores the config).
   */
  configVersion?: number;
  identity?: {
    legalName?: string;
    shortName?: LocalizedString;
  };
  locales: {
    /**
     * @minItems 1
     */
    supported: [string, ...string[]];
    default: string;
    rtlLocales?: string[];
  };
  currencies: {
    /**
     * @minItems 1
     */
    supported: [string, ...string[]];
    /**
     * ISO 4217 currency code.
     */
    default: string;
  };
  countries: {
    /**
     * @minItems 1
     */
    supported: [string, ...string[]];
    /**
     * ISO 3166-1 alpha-2 country code.
     */
    default: string;
  };
  /**
   * Capability flags — which platform modules are mounted for this client (tabs/coordinators/endpoints exposed). See docs/planning/07 §5 and ADR-0008. A closed set: a new module means new code (a coordinator/tab/endpoint group), so adding one is a schema change, not just a config change — contrast with the open-ended featureFlags below.
   */
  modules: {
    authentication?: boolean;
    listings?: boolean;
    search?: boolean;
    favorites?: boolean;
    chat?: boolean;
    notifications?: boolean;
    sellerDashboard?: boolean;
    subscriptions?: boolean;
    payments?: boolean;
    wallet?: boolean;
    advertisements?: boolean;
    reviews?: boolean;
    moderation?: boolean;
  };
  /**
   * Operational flags — kill-switches / gradual rollout for already-shipped features. Distinct from `modules` (capability composition). Keys are typed on each client via a generated enum.
   */
  featureFlags: {
    [k: string]: boolean;
  };
  providers: {
    authentication: {
      /**
       * @minItems 1
       */
      methods: [
        'email_password' | 'phone_otp' | 'apple' | 'google' | 'anonymous',
        ...('email_password' | 'phone_otp' | 'apple' | 'google' | 'anonymous')[]
      ];
    };
    payments?: {
      provider?: 'none' | 'stripe' | 'tap' | 'hyperpay' | 'myfatoorah';
      methods?: string[];
    };
    maps: {
      provider: 'apple' | 'google' | 'mapbox';
    };
    push?: {
      provider?: 'apns' | 'fcm';
    };
    analytics: {
      provider: 'none' | 'firebase' | 'amplitude' | 'mixpanel';
    };
  };
  social?: {
    instagram?: string;
    twitter?: string;
    facebook?: string;
    tiktok?: string;
    whatsapp?: string;
    website?: string;
  };
  support: {
    email: string;
    phone?: string;
    chatEnabled?: boolean;
  };
  legal: {
    termsUrl: string;
    privacyUrl: string;
  };
}
/**
 * A map of BCP-47-ish locale code to translated string. Must include at least the platform default locale's entry at the point of use.
 */
export interface LocalizedString {
  /**
   * This interface was referenced by `LocalizedString`'s JSON-Schema definition
   * via the `patternProperty` "^[a-z]{2}(-[A-Z]{2})?$".
   */
  [k: string]: string;
}
