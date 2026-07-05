/**
 * AUTO-GENERATED — do not edit by hand.
 * Source: contract/schema/*.schema.json and contract/openapi/v1/openapi.yaml
 * Regenerate: npm run generate --workspace=packages/contract-types
 * See contract/README.md for what these files mean.
 */

/**
 * Semantic design tokens for the Theme Engine. Views reference these roles, never raw literals (enforced by CI lint on the DesignSystem module). Fetched at boot (GET /v1/theme) and editable live in the dashboard's Theme Studio. See docs/planning/07-configuration-whitelabel-theme.md §4 and ADR-0005.
 */
export interface ThemeTokens {
  schemaFormatVersion: string;
  /**
   * Identifier matching a configs/clients/<slug> directory name. Accepts kebab-case or snake_case (the project foundation uses client_a/client_b/client_c).
   */
  clientId: string;
  /**
   * Bumped on every published theme change; drives client cache invalidation.
   */
  themeVersion?: number;
  colors: {
    light: SemanticColorSet;
    dark: SemanticColorSet;
  };
  typography: {
    fontFamily: string;
    scale: {
      largeTitle: TextStyle;
      title1: TextStyle;
      title2: TextStyle;
      headline: TextStyle;
      body: TextStyle;
      subheadline: TextStyle;
      caption: TextStyle;
      footnote: TextStyle;
    };
  };
  shape?: {
    cornerRadiusSmall?: number;
    cornerRadiusMedium?: number;
    cornerRadiusLarge?: number;
  };
}
/**
 * The full semantic color vocabulary mandated by the project foundation. All keys required so a theme is never partially defined for a given color scheme.
 */
export interface SemanticColorSet {
  primary: string;
  secondary: string;
  accent: string;
  background: string;
  surface: string;
  card: string;
  border: string;
  textPrimary: string;
  textSecondary: string;
  placeholder: string;
  success: string;
  warning: string;
  danger: string;
  info: string;
  separator: string;
  overlay: string;
  skeleton: string;
  loading: string;
  selection: string;
  navigation: string;
  toolbar: string;
  tabBar: string;
  glass: string;
  material: string;
  interactive: string;
  badge: string;
  favorite: string;
  online: string;
  offline: string;
}
export interface TextStyle {
  size: number;
  weight: 'regular' | 'medium' | 'semibold' | 'bold' | 'heavy';
  lineHeight?: number;
}
