export function versionETag(version: number): string {
  return `"v${version}"`;
}

export function matchesIfNoneMatch(req: Request, etag: string): boolean {
  return req.headers.get("if-none-match") === etag;
}
