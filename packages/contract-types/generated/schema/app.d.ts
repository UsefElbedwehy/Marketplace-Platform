/**
 * AUTO-GENERATED — do not edit by hand.
 * Source: contract/schema/*.schema.json and contract/openapi/v1/openapi.yaml
 * Regenerate: npm run generate --workspace=packages/contract-types
 * See contract/README.md for what these files mean.
 */

/**
 * Identity, branding, signing, and entitlement knobs that are baked into an iOS/Android binary at build time and therefore cannot change at runtime. Drives the white-label build pipeline (see docs/planning/07-configuration-whitelabel-theme.md). One file per client under configs/clients/<client>/app.json.
 */
export interface AppConfig {
  /**
   * Version of the Development Schema format this document targets. Bumped when the format changes; migrations ship with upgraders.
   */
  schemaFormatVersion: string;
  /**
   * Stable identifier matching the configs/clients/<clientId> directory name.
   */
  clientId: string;
  displayName: LocalizedString;
  /**
   * Reverse-DNS bundle identifier, e.g. com.acme.marketplace
   */
  bundleIdentifier: string;
  /**
   * Custom URL scheme for deep links, e.g. acme-marketplace
   */
  urlScheme: string;
  /**
   * Universal Link domains, e.g. applinks:acme.example.com
   */
  associatedDomains?: string[];
  entitlements: {
    pushNotifications: boolean;
    signInWithApple: boolean;
    associatedDomainsEnabled?: boolean;
  };
  /**
   * References to signing identity — never secrets. Actual credentials are managed by Fastlane Match / CI secrets, not this file.
   */
  signing?: {
    teamId?: string;
    provisioningProfileName?: string;
  };
  assets: {
    /**
     * Relative path (from the owning client's config directory) to an asset file.
     */
    appIcon: string;
    /**
     * Relative path (from the owning client's config directory) to an asset file.
     */
    launchLogo: string;
    /**
     * Relative path (from the owning client's config directory) to an asset file.
     */
    splashBackground?: string;
  };
}
/**
 * App name as shown on the home screen / App Store, per locale.
 */
export interface LocalizedString {
  /**
   * This interface was referenced by `LocalizedString`'s JSON-Schema definition
   * via the `patternProperty` "^[a-z]{2}(-[A-Z]{2})?$".
   */
  [k: string]: string;
}
