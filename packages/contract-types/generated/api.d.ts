/**
 * AUTO-GENERATED — do not edit by hand.
 * Source: contract/schema/*.schema.json and contract/openapi/v1/openapi.yaml
 * Regenerate: npm run generate --workspace=packages/contract-types
 * See contract/README.md for what these files mean.
 */

export interface paths {
    "/v1/health": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Liveness check */
        get: operations["getHealth"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/config": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Fetch the runtime configuration bundle for the calling client
         * @description Returns the effective runtime slice of the Development Schema (locales,
         *     currencies, countries, modules, feature flags, provider selection, social,
         *     support, legal) for the tenant resolved from the auth context / client key.
         *     Supports ETag / If-None-Match caching keyed on configVersion.
         */
        get: operations["getConfig"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/theme": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Fetch the active theme token set for the calling client */
        get: operations["getTheme"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/categories/tree": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Fetch the full category tree
         * @description Returns every active category as a nested tree (unlimited depth in
         *     principle; the default reference marketplace seeds two levels). See
         *     docs/planning/05-dynamic-schema-engine.md §5.
         */
        get: operations["getCategoryTree"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/categories/{categoryId}/schema": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Fetch the composed dynamic listing schema for a leaf category ⭐
         * @description Composes catalog.category + attribute_group + attribute + attribute_option
         *     + attribute_dependency into the one document DynamicForms (and the
         *     dashboard's Schema Builder preview) render from — schema-driven, never
         *     screen-driven. The same shape for every category, however structurally
         *     different (Cars vs. Apartments vs. Phones).
         */
        get: operations["getCategorySchema"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/attributes/{attributeId}/options": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Fetch (optionally dependent) options for an attribute
         * @description Supports the "Model options_filtered_by Brand" pattern via `parent` —
         *     pass the parent attribute's selected option id to get only its
         *     dependent options. Paginated for large option sets (e.g. car models).
         */
        get: operations["getAttributeOptions"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/listings": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Filter/browse published listings
         * @description Filters compile against listing.attributes_index (docs/planning/05
         *     §7). `filters` is a JSON-encoded object: equality (`{"brand":"bmw"}`)
         *     or range (`{"mileage":{"lt":100000}}`) per key, where keys are
         *     attribute `key`s from the category's composed schema.
         */
        get: operations["listListings"];
        put?: never;
        /**
         * Create a listing ⭐
         * @description Attribute values are validated against the target category's schema
         *     at the request level (field-level errors) before the authoritative
         *     database trigger (listing.enforce_attribute_value_type) re-checks
         *     them — see ADR-0003. Requires authentication; the created listing
         *     starts as `draft`.
         */
        post: operations["createListing"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/listings/{listingId}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Fetch a single listing (schema-projected detail view) ⭐
         * @description RLS (owner, moderator, or anyone for a published listing) gates row
         *     access — a listing you can't see resolves to 404, not 403, so
         *     existence isn't leaked. Clients project `attributesIndex` against the
         *     category's composed schema (`GET /v1/categories/{id}/schema`) for
         *     labels/units, the same pattern `GET /v1/listings` uses.
         */
        get: operations["getListing"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        /**
         * Transition a listing's status (submit for review, approve, reject, archive, mark sold) ⭐
         * @description RLS (owner or moderator) gates row access; this endpoint additionally
         *     enforces which status-to-status transitions are legal at all, and
         *     that only a moderator/admin can move a listing to `published` or
         *     `rejected` — the dashboard's moderation queue writes through here.
         *     See docs/planning/06-dashboard-architecture.md and the state machine
         *     in backend/src/listing_service.ts.
         */
        patch: operations["updateListingStatus"];
        trace?: never;
    };
    "/v1/users": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List tenant users (admin only)
         * @description RLS (profile_select_own_or_admin) already scopes reads to "your own
         *     row, or every row if you're an admin/super_admin"; this endpoint
         *     additionally 403s cleanly for non-admins instead of just returning
         *     their own single row, since this is an admin-only screen.
         */
        get: operations["listUsers"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/users/{userId}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        /**
         * Change another user's role (admin only, never your own) ⭐
         * @description RLS (profile_update_admin) gates row access; backend/src/user_service.ts
         *     additionally forbids an actor changing their own role even if they are
         *     an admin — see identity.prevent_self_role_escalation's header comment
         *     (migration 20260704155058) for why this is enforced at both layers.
         */
        patch: operations["updateUserRole"];
        trace?: never;
    };
    "/v1/chat/conversations": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List the caller's conversations
         * @description RLS (conversation_select_participant) scopes this to conversations the
         *     caller participates in as buyer or seller — no explicit filter is
         *     needed server-side. 404s if the `chat` module is disabled for this
         *     client.
         */
        get: operations["listConversations"];
        put?: never;
        /**
         * Start (or resume) a conversation with a listing's seller ⭐
         * @description Buyer-initiated only — a seller cannot proactively start a thread
         *     with a buyer through this endpoint. Re-opening chat about a listing
         *     you've already messaged the seller about resumes that same
         *     conversation (unique on listing + buyer). Rejects starting a
         *     conversation about your own listing.
         */
        post: operations["startConversation"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/chat/conversations/{conversationId}/messages": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Fetch a conversation's messages (poll-based, no Realtime)
         * @description docs/planning/03-backend-architecture.md §6 specifies chat as
         *     Realtime-delivered; real Supabase Realtime needs the hosted/Docker
         *     Realtime service, unavailable in this environment (the same gap as
         *     real GoTrue-backed auth) — so clients poll this endpoint instead.
         *     Fetching also marks every message from the other participant as
         *     read. RLS (message_select_participant) is the actual access gate.
         */
        get: operations["listMessages"];
        put?: never;
        /**
         * Send a message ⭐
         * @description RLS (message_insert_participant) gates this to participants of the
         *     conversation. Creates a `chat_message` notification for the other
         *     participant as part of the same request (backend/src/notifications_
         *     service.ts) — see the `notifications` tag for how that's delivered.
         */
        post: operations["sendMessage"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/favorites": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List the caller's saved listings
         * @description RLS (favorite_all_own) scopes this to the caller's own favorites.
         */
        get: operations["listFavorites"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/favorites/{listingId}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        /**
         * Save a listing (idempotent)
         * @description Calling this twice for the same listing is a no-op returning the same favorite — not an error.
         */
        put: operations["addFavorite"];
        post?: never;
        /**
         * Unsave a listing (idempotent)
         * @description Removing a listing that isn't favorited (or isn't yours) is a harmless no-op.
         */
        delete: operations["removeFavorite"];
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/reviews": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Fetch a seller's reviews
         * @description RLS (review_select_public) makes reviews public read — anyone, including anon.
         */
        get: operations["listReviews"];
        put?: never;
        /**
         * Rate a seller ⭐
         * @description Immutable once posted (no update/delete policy on social.review).
         *     Aggregated onto the seller's public profile (rating_count/rating_sum)
         *     by a database trigger, not client math — see GET /v1/profiles/{id}.
         *     Rejects reviewing yourself and duplicate reviews for the same
         *     (reviewer, reviewee, listing) triple.
         */
        post: operations["createReview"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/notifications": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List the caller's notifications (poll-based, no Realtime)
         * @description docs/planning/03-backend-architecture.md §6 specifies an outbox table
         *     + Realtime channel per user with push (APNs) fan-out via a provider
         *     port; real APNs credentials aren't available in this environment
         *     (backend/src/ports/push_port.ts), so `deliveredAt` reflects a logging
         *     no-op adapter, not a real device delivery. RLS (outbox_select_own)
         *     scopes this to the caller's own notifications.
         */
        get: operations["listNotifications"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/notifications/{notificationId}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        /** Mark a notification read */
        patch: operations["markNotificationRead"];
        trace?: never;
    };
    "/v1/profiles/{userId}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * View a seller's public profile ⭐
         * @description Distinct from GET /v1/users/{id} (admin-only, full profile) — this is
         *     a public, read-only lookup exposing only display name, avatar, bio,
         *     member-since, rating aggregate, and published listing count.
         */
        get: operations["getPublicSellerProfile"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
}
export type webhooks = Record<string, never>;
export interface components {
    schemas: {
        HealthResponse: {
            /** @enum {string} */
            status: "ok";
        };
        ErrorEnvelope: {
            error: {
                /**
                 * @description Stable machine-readable error code driving client behavior.
                 * @example validation_failed
                 * @example unauthorized
                 * @example not_found
                 * @example rate_limited
                 */
                code: string;
                /** @description Localized, human-readable summary. Display-only. */
                message: string;
                requestId: string;
                /** @description Present for validation errors; maps directly onto dynamic form fields. */
                fields?: {
                    field: string;
                    code: string;
                    message: string;
                }[];
            };
        };
        PaginationMeta: {
            nextCursor?: string | null;
            hasMore?: boolean;
        };
        CategoryTreeNode: {
            /** Format: uuid */
            id: string;
            slug: string;
            /** @description Locale-resolved (see the locale query parameter). */
            name: string;
            icon?: string | null;
            sortOrder: number;
            isLeaf: boolean;
            children: components["schemas"]["CategoryTreeNode"][];
        };
        AttributeOption: {
            /** Format: uuid */
            id: string;
            value: string;
            label: string;
            /**
             * Format: uuid
             * @description For dependent option sets (e.g. Model options filtered by Brand) — the parent option this one belongs to.
             */
            parentOptionId: string | null;
        };
        AttributeDependency: {
            /** @description The key of the attribute this one depends on. */
            field: string;
            /** @enum {string} */
            rule: "visible_when" | "required_when" | "options_filtered_by";
            condition: Record<string, never>;
        };
        SchemaField: {
            /**
             * Format: uuid
             * @description The underlying attribute id — present so admin clients (the dashboard) can target POST /v1/attributes/{id}/options and /dependencies; read-only app clients can ignore it.
             */
            id: string;
            key: string;
            label: string;
            /** @enum {string} */
            dataType: "text" | "number" | "bool" | "date" | "option" | "option_multi" | "media" | "location";
            /** @enum {string} */
            inputType: "textfield" | "textarea" | "stepper" | "slider" | "dropdown" | "chips" | "switch" | "datepicker" | "media" | "map";
            required: boolean;
            filterable: boolean;
            searchable: boolean;
            sortOrder: number;
            unit?: string | null;
            validation: Record<string, never>;
            defaultValue?: unknown;
            options: components["schemas"]["AttributeOption"][];
            dependsOn: components["schemas"]["AttributeDependency"][];
        };
        SchemaGroup: {
            /** Format: uuid */
            id: string;
            name: string;
            collapsible: boolean;
            fields: components["schemas"]["SchemaField"][];
        };
        ComposedSchema: {
            /** @description Bumped on any change to this category's groups/attributes/options/dependencies — ETag this for cache invalidation. */
            schemaVersion: number;
            category: {
                /** Format: uuid */
                id: string;
                slug: string;
                name: string;
                /** @description Root-to-leaf breadcrumb, e.g. ["Vehicles", "Cars"]. */
                path: string[];
            };
            groups: components["schemas"]["SchemaGroup"][];
        };
        Listing: {
            /** Format: uuid */
            id: string;
            /**
             * Format: uuid
             * @description The seller — added in Phase 6 to link a listing to its "message seller" / seller-profile affordances (GET /v1/chat/conversations, GET /v1/profiles/{id}).
             */
            ownerId: string;
            /** Format: uuid */
            categoryId: string;
            title: string;
            description?: string | null;
            price?: number | null;
            currency?: string | null;
            /** @enum {string} */
            status: "draft" | "pending_review" | "published" | "rejected" | "archived" | "sold";
            /** @description The listing's attribute values, keyed by attribute key (see listing.attributes_index, ADR-0003). */
            attributesIndex: Record<string, never>;
            /** Format: date-time */
            createdAt: string;
        };
        CreateListingRequest: {
            /** Format: uuid */
            categoryId: string;
            title: string;
            description?: string;
            price?: number;
            currency?: string;
            /** @description Raw submitted values keyed by attribute key, validated against the category's composed schema server-side. */
            attributes: Record<string, never>;
        };
        UserProfile: {
            /** Format: uuid */
            id: string;
            email: string | null;
            displayName: string | null;
            /** @enum {string} */
            appRole: "buyer" | "seller" | "catalog_editor" | "moderator" | "finance" | "support" | "admin" | "super_admin";
            /** Format: date-time */
            createdAt: string;
        };
        Conversation: {
            /** Format: uuid */
            id: string;
            /** Format: uuid */
            listingId: string;
            listingTitle: string;
            /** Format: uuid */
            buyerId: string;
            buyerDisplayName: string | null;
            /** Format: uuid */
            sellerId: string;
            sellerDisplayName: string | null;
            /** Format: date-time */
            lastMessageAt: string | null;
            /** Format: date-time */
            createdAt: string;
        };
        Message: {
            /** Format: uuid */
            id: string;
            /** Format: uuid */
            conversationId: string;
            /** Format: uuid */
            senderId: string;
            body: string;
            /** Format: date-time */
            readAt: string | null;
            /** Format: date-time */
            createdAt: string;
        };
        Favorite: {
            /** Format: uuid */
            id: string;
            /** Format: uuid */
            listingId: string;
            /** Format: date-time */
            createdAt: string;
        };
        Review: {
            /** Format: uuid */
            id: string;
            /** Format: uuid */
            reviewerId: string;
            reviewerDisplayName: string | null;
            /** Format: uuid */
            revieweeId: string;
            /** Format: uuid */
            listingId: string | null;
            rating: number;
            comment: string | null;
            /** Format: date-time */
            createdAt: string;
        };
        CreateReviewRequest: {
            /** Format: uuid */
            revieweeId: string;
            /** Format: uuid */
            listingId?: string;
            rating: number;
            comment?: string;
        };
        Notification: {
            /** Format: uuid */
            id: string;
            /** @enum {string} */
            type: "chat_message" | "listing_favorited" | "review_received";
            /** @description Shape depends on `type` — e.g. a chat_message notification's payload has conversationId/messageId/listingId. */
            payload: Record<string, never>;
            /** Format: date-time */
            readAt: string | null;
            /**
             * Format: date-time
             * @description When the push provider port attempted delivery — not a guarantee of real device delivery (backend/src/ports/push_port.ts).
             */
            deliveredAt: string | null;
            /** Format: date-time */
            createdAt: string;
        };
        PublicSellerProfile: {
            /** Format: uuid */
            id: string;
            displayName: string | null;
            avatarUrl: string | null;
            bio: string | null;
            /** Format: date-time */
            memberSince: string;
            ratingCount: number;
            /** @description rating_sum / rating_count, rounded to 1 decimal; null if ratingCount is 0. */
            ratingAverage: number | null;
            publishedListingCount: number;
        };
        semver: string;
        /** @description Identifier matching a configs/clients/<slug> directory name. Accepts kebab-case or snake_case (the project foundation uses client_a/client_b/client_c). */
        slug: string;
        /** @description A map of BCP-47-ish locale code to translated string. Must include at least the platform default locale's entry at the point of use. */
        localizedString: {
            [key: string]: string;
        };
        /**
         * @example en
         * @example ar
         * @example ar-SA
         * @example en-GB
         */
        localeCode: string;
        /**
         * @description ISO 4217 currency code.
         * @example SAR
         * @example KWD
         * @example USD
         * @example AED
         */
        currencyCode: string;
        /**
         * @description ISO 3166-1 alpha-2 country code.
         * @example SA
         * @example KW
         * @example AE
         */
        countryCode: string;
        /** Format: uri */
        url: string;
        /** Format: email */
        email: string;
        /**
         * Development Schema — runtime slice (config.json)
         * @description Backend-driven configuration fetched by clients at boot (GET /v1/config). Dashboard-editable without a rebuild: locales, currencies, countries, feature flags/modules, provider selection, links, legal, support. See docs/planning/07-configuration-whitelabel-theme.md and ADR-0004. This is deep-merged: configs/clients/default/config.json <- configs/clients/<client>/config.json <- configs/<env>/config.json.
         */
        "config.schema": {
            schemaFormatVersion: components["schemas"]["semver"];
            clientId: components["schemas"]["slug"];
            /** @description Bumped by the backend on every published change; drives client ETag/cache invalidation. Absent in static seed files (assigned when the backend stores the config). */
            configVersion?: number;
            identity?: {
                legalName?: string;
                shortName?: components["schemas"]["localizedString"];
            };
            locales: {
                supported: components["schemas"]["localeCode"][];
                default: components["schemas"]["localeCode"];
                /**
                 * @default [
                 *       "ar"
                 *     ]
                 */
                rtlLocales: components["schemas"]["localeCode"][];
            };
            currencies: {
                supported: components["schemas"]["currencyCode"][];
                default: components["schemas"]["currencyCode"];
            };
            countries: {
                supported: components["schemas"]["countryCode"][];
                default: components["schemas"]["countryCode"];
            };
            /** @description Capability flags — which platform modules are mounted for this client (tabs/coordinators/endpoints exposed). See docs/planning/07 §5 and ADR-0008. A closed set: a new module means new code (a coordinator/tab/endpoint group), so adding one is a schema change, not just a config change — contrast with the open-ended featureFlags below. */
            modules: {
                /** @default true */
                authentication: boolean;
                /** @default true */
                listings: boolean;
                /** @default true */
                search: boolean;
                /** @default true */
                favorites: boolean;
                /** @default true */
                chat: boolean;
                /** @default true */
                notifications: boolean;
                /** @default false */
                sellerDashboard: boolean;
                /** @default false */
                subscriptions: boolean;
                /** @default false */
                payments: boolean;
                /** @default false */
                wallet: boolean;
                /** @default false */
                advertisements: boolean;
                /** @default false */
                reviews: boolean;
                /** @default true */
                moderation: boolean;
            };
            /** @description Operational flags — kill-switches / gradual rollout for already-shipped features. Distinct from `modules` (capability composition). Keys are typed on each client via a generated enum. */
            featureFlags: {
                [key: string]: boolean;
            };
            providers: {
                authentication: {
                    methods: ("email_password" | "phone_otp" | "apple" | "google" | "anonymous")[];
                };
                payments?: {
                    /** @enum {string} */
                    provider?: "none" | "stripe" | "tap" | "hyperpay" | "myfatoorah";
                    /** @default [] */
                    methods: string[];
                };
                maps: {
                    /** @enum {string} */
                    provider: "apple" | "google" | "mapbox";
                };
                push?: {
                    /** @enum {string} */
                    provider?: "apns" | "fcm";
                };
                analytics: {
                    /** @enum {string} */
                    provider: "none" | "firebase" | "amplitude" | "mixpanel";
                };
            };
            social?: {
                instagram?: components["schemas"]["url"];
                twitter?: components["schemas"]["url"];
                facebook?: components["schemas"]["url"];
                tiktok?: components["schemas"]["url"];
                whatsapp?: components["schemas"]["url"];
                website?: components["schemas"]["url"];
            };
            support: {
                email: components["schemas"]["email"];
                phone?: string;
                /** @default false */
                chatEnabled: boolean;
            };
            legal: {
                termsUrl: components["schemas"]["url"];
                privacyUrl: components["schemas"]["url"];
            };
        };
        /**
         * @example #FF7A00
         * @example #1A1A1AFF
         */
        colorHex: string;
        /** @description The full semantic color vocabulary mandated by the project foundation. All keys required so a theme is never partially defined for a given color scheme. */
        semanticColorSet: {
            primary: components["schemas"]["colorHex"];
            secondary: components["schemas"]["colorHex"];
            accent: components["schemas"]["colorHex"];
            background: components["schemas"]["colorHex"];
            surface: components["schemas"]["colorHex"];
            card: components["schemas"]["colorHex"];
            border: components["schemas"]["colorHex"];
            textPrimary: components["schemas"]["colorHex"];
            textSecondary: components["schemas"]["colorHex"];
            placeholder: components["schemas"]["colorHex"];
            success: components["schemas"]["colorHex"];
            warning: components["schemas"]["colorHex"];
            danger: components["schemas"]["colorHex"];
            info: components["schemas"]["colorHex"];
            separator: components["schemas"]["colorHex"];
            overlay: components["schemas"]["colorHex"];
            skeleton: components["schemas"]["colorHex"];
            loading: components["schemas"]["colorHex"];
            selection: components["schemas"]["colorHex"];
            navigation: components["schemas"]["colorHex"];
            toolbar: components["schemas"]["colorHex"];
            tabBar: components["schemas"]["colorHex"];
            glass: components["schemas"]["colorHex"];
            material: components["schemas"]["colorHex"];
            interactive: components["schemas"]["colorHex"];
            badge: components["schemas"]["colorHex"];
            favorite: components["schemas"]["colorHex"];
            online: components["schemas"]["colorHex"];
            offline: components["schemas"]["colorHex"];
        };
        textStyle: {
            size: number;
            /** @enum {string} */
            weight: "regular" | "medium" | "semibold" | "bold" | "heavy";
            lineHeight?: number;
        };
        /**
         * Theme Engine tokens (theme.json)
         * @description Semantic design tokens for the Theme Engine. Views reference these roles, never raw literals (enforced by CI lint on the DesignSystem module). Fetched at boot (GET /v1/theme) and editable live in the dashboard's Theme Studio. See docs/planning/07-configuration-whitelabel-theme.md §4 and ADR-0005.
         */
        "theme.schema": {
            schemaFormatVersion: components["schemas"]["semver"];
            clientId: components["schemas"]["slug"];
            /** @description Bumped on every published theme change; drives client cache invalidation. */
            themeVersion?: number;
            colors: {
                light: components["schemas"]["semanticColorSet"];
                dark: components["schemas"]["semanticColorSet"];
            };
            typography: {
                fontFamily: string;
                scale: {
                    largeTitle: components["schemas"]["textStyle"];
                    title1: components["schemas"]["textStyle"];
                    title2: components["schemas"]["textStyle"];
                    headline: components["schemas"]["textStyle"];
                    body: components["schemas"]["textStyle"];
                    subheadline: components["schemas"]["textStyle"];
                    caption: components["schemas"]["textStyle"];
                    footnote: components["schemas"]["textStyle"];
                };
            };
            shape?: {
                /** @default 4 */
                cornerRadiusSmall: number;
                /** @default 8 */
                cornerRadiusMedium: number;
                /** @default 16 */
                cornerRadiusLarge: number;
            };
            $defs: {
                /** @description The full semantic color vocabulary mandated by the project foundation. All keys required so a theme is never partially defined for a given color scheme. */
                semanticColorSet: {
                    primary: components["schemas"]["colorHex"];
                    secondary: components["schemas"]["colorHex"];
                    accent: components["schemas"]["colorHex"];
                    background: components["schemas"]["colorHex"];
                    surface: components["schemas"]["colorHex"];
                    card: components["schemas"]["colorHex"];
                    border: components["schemas"]["colorHex"];
                    textPrimary: components["schemas"]["colorHex"];
                    textSecondary: components["schemas"]["colorHex"];
                    placeholder: components["schemas"]["colorHex"];
                    success: components["schemas"]["colorHex"];
                    warning: components["schemas"]["colorHex"];
                    danger: components["schemas"]["colorHex"];
                    info: components["schemas"]["colorHex"];
                    separator: components["schemas"]["colorHex"];
                    overlay: components["schemas"]["colorHex"];
                    skeleton: components["schemas"]["colorHex"];
                    loading: components["schemas"]["colorHex"];
                    selection: components["schemas"]["colorHex"];
                    navigation: components["schemas"]["colorHex"];
                    toolbar: components["schemas"]["colorHex"];
                    tabBar: components["schemas"]["colorHex"];
                    glass: components["schemas"]["colorHex"];
                    material: components["schemas"]["colorHex"];
                    interactive: components["schemas"]["colorHex"];
                    badge: components["schemas"]["colorHex"];
                    favorite: components["schemas"]["colorHex"];
                    online: components["schemas"]["colorHex"];
                    offline: components["schemas"]["colorHex"];
                };
                textStyle: {
                    size: number;
                    /** @enum {string} */
                    weight: "regular" | "medium" | "semibold" | "bold" | "heavy";
                    lineHeight?: number;
                };
            };
        };
    };
    responses: {
        /** @description Standard error envelope. */
        Error: {
            headers: {
                [name: string]: unknown;
            };
            content: {
                "application/json": components["schemas"]["ErrorEnvelope"];
            };
        };
    };
    parameters: {
        IfNoneMatch: string;
        /** @description Resolves i18n label maps server-side (docs/planning/05 §5). Defaults to "en". */
        Locale: string;
    };
    requestBodies: never;
    headers: never;
    pathItems: never;
}
export type $defs = Record<string, never>;
export interface operations {
    getHealth: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Service is healthy. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HealthResponse"];
                };
            };
        };
    };
    getConfig: {
        parameters: {
            query?: never;
            header?: {
                "If-None-Match"?: components["parameters"]["IfNoneMatch"];
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Current runtime config. */
            200: {
                headers: {
                    ETag?: string;
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["config.schema"];
                    };
                };
            };
            /** @description Not modified — cached config is current. */
            304: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            default: components["responses"]["Error"];
        };
    };
    getTheme: {
        parameters: {
            query?: never;
            header?: {
                "If-None-Match"?: components["parameters"]["IfNoneMatch"];
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Current theme tokens. */
            200: {
                headers: {
                    ETag?: string;
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["theme.schema"];
                    };
                };
            };
            /** @description Not modified — cached theme is current. */
            304: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            default: components["responses"]["Error"];
        };
    };
    getCategoryTree: {
        parameters: {
            query?: {
                /** @description Resolves i18n label maps server-side (docs/planning/05 §5). Defaults to "en". */
                locale?: components["parameters"]["Locale"];
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The category tree. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["CategoryTreeNode"][];
                    };
                };
            };
            default: components["responses"]["Error"];
        };
    };
    getCategorySchema: {
        parameters: {
            query?: {
                /** @description Resolves i18n label maps server-side (docs/planning/05 §5). Defaults to "en". */
                locale?: components["parameters"]["Locale"];
            };
            header?: never;
            path: {
                categoryId: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The composed schema. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["ComposedSchema"];
                    };
                };
            };
            404: components["responses"]["Error"];
            default: components["responses"]["Error"];
        };
    };
    getAttributeOptions: {
        parameters: {
            query?: {
                /** @description Parent option id — filters to options whose parent_option_id matches. */
                parent?: string;
                limit?: number;
                offset?: number;
                /** @description Resolves i18n label maps server-side (docs/planning/05 §5). Defaults to "en". */
                locale?: components["parameters"]["Locale"];
            };
            header?: never;
            path: {
                attributeId: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Matching options. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["AttributeOption"][];
                    };
                };
            };
            default: components["responses"]["Error"];
        };
    };
    listListings: {
        parameters: {
            query?: {
                category?: string;
                /** @description Defaults to "published" unless `owner=me` is set. Moderators may request e.g. "pending_review" to see the moderation queue (RLS scopes what's actually returned). */
                status?: string;
                /** @description Pass "me" to see every status of your own listings ("my listings") instead of the published-only default. */
                owner?: "me";
                /** @description JSON-encoded attribute filter object. */
                filters?: string;
                cursor?: string;
                limit?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Matching listings. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Listing"][];
                        page: components["schemas"]["PaginationMeta"];
                    };
                };
            };
            default: components["responses"]["Error"];
        };
    };
    createListing: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["CreateListingRequest"];
            };
        };
        responses: {
            /** @description Listing created. */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Listing"];
                    };
                };
            };
            422: components["responses"]["Error"];
            default: components["responses"]["Error"];
        };
    };
    getListing: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                listingId: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The listing. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Listing"];
                    };
                };
            };
            404: components["responses"]["Error"];
            default: components["responses"]["Error"];
        };
    };
    updateListingStatus: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                listingId: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": {
                    /** @enum {string} */
                    status: "draft" | "pending_review" | "published" | "rejected" | "archived" | "sold";
                };
            };
        };
        responses: {
            /** @description Updated listing. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Listing"];
                    };
                };
            };
            403: components["responses"]["Error"];
            422: components["responses"]["Error"];
            default: components["responses"]["Error"];
        };
    };
    listUsers: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Tenant users. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["UserProfile"][];
                    };
                };
            };
            403: components["responses"]["Error"];
            default: components["responses"]["Error"];
        };
    };
    updateUserRole: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                userId: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": {
                    /** @enum {string} */
                    appRole: "buyer" | "seller" | "catalog_editor" | "moderator" | "finance" | "support" | "admin" | "super_admin";
                };
            };
        };
        responses: {
            /** @description Updated user. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["UserProfile"];
                    };
                };
            };
            403: components["responses"]["Error"];
            422: components["responses"]["Error"];
            default: components["responses"]["Error"];
        };
    };
    listConversations: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The caller's conversations, most recently active first. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Conversation"][];
                    };
                };
            };
            default: components["responses"]["Error"];
        };
    };
    startConversation: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": {
                    /** Format: uuid */
                    listingId: string;
                };
            };
        };
        responses: {
            /** @description The conversation (created, or the pre-existing one for this listing+buyer pair). */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Conversation"];
                    };
                };
            };
            422: components["responses"]["Error"];
            default: components["responses"]["Error"];
        };
    };
    listMessages: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                conversationId: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Messages, oldest first. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Message"][];
                    };
                };
            };
            default: components["responses"]["Error"];
        };
    };
    sendMessage: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                conversationId: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": {
                    body: string;
                };
            };
        };
        responses: {
            /** @description Message sent. */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Message"];
                    };
                };
            };
            422: components["responses"]["Error"];
            default: components["responses"]["Error"];
        };
    };
    listFavorites: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The caller's favorites, most recently saved first. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Favorite"][];
                    };
                };
            };
            default: components["responses"]["Error"];
        };
    };
    addFavorite: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                listingId: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The favorite (created, or already existing). */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Favorite"];
                    };
                };
            };
            default: components["responses"]["Error"];
        };
    };
    removeFavorite: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                listingId: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Removed (or was never favorited). */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            default: components["responses"]["Error"];
        };
    };
    listReviews: {
        parameters: {
            query: {
                sellerId: string;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The seller's reviews, newest first. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Review"][];
                    };
                };
            };
            422: components["responses"]["Error"];
            default: components["responses"]["Error"];
        };
    };
    createReview: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["CreateReviewRequest"];
            };
        };
        responses: {
            /** @description Review created. */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Review"];
                    };
                };
            };
            409: components["responses"]["Error"];
            422: components["responses"]["Error"];
            default: components["responses"]["Error"];
        };
    };
    listNotifications: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The caller's notifications, newest first. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Notification"][];
                    };
                };
            };
            default: components["responses"]["Error"];
        };
    };
    markNotificationRead: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                notificationId: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Updated notification. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["Notification"];
                    };
                };
            };
            404: components["responses"]["Error"];
            default: components["responses"]["Error"];
        };
    };
    getPublicSellerProfile: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                userId: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The seller's public profile. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        data: components["schemas"]["PublicSellerProfile"];
                    };
                };
            };
            404: components["responses"]["Error"];
            default: components["responses"]["Error"];
        };
    };
}
