@_exported import Factory

// Every other module resolves dependencies via `import Core` and Factory's
// `Container`/`@Injected`/`Factory<T>` — never `import Factory` directly
// (ADR-0012). This file is the entire "swap the DI library" blast radius.
