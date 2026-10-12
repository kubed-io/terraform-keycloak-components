const series = context.panelData?.series ?? [];
const docs = series.flatMap((f) => {
  const field = f.fields?.find((x) => x.name === 'doc');
  return Array.from(field?.values ?? []).flatMap((v) => {
    try {
      return [JSON.parse(v)];
    } catch {
      return [];
    }
  });
});
// This dashboard's object, by its kind and name: a panel may also hold lists of other objects.
const self = { kind: context.grafana.replaceVariables('${kind}'), name: context.grafana.replaceVariables('${name}') };
const obj = docs.find((d) => d.kind === self.kind && d.metadata?.name === self.name);
const base = context.grafana.replaceVariables('${assets}');
const yes = (v) => (v === undefined || v === null ? undefined : v ? { text: 'on', tone: 'success' } : { text: 'off', tone: 'neutral' });
const set = (v) => v !== undefined && v !== null && v !== '';
const dflt = (text) => ({ text, tone: 'neutral', title: 'not set: Keycloak default' });
const flag = (v, otherwise) => (set(v) ? yes(v) : dflt(otherwise));
const show = (v, otherwise) => (set(v) ? v : dflt(otherwise));
const link = (u) => (set(u) ? (/^https?:/.test(u) ? { href: u, text: u } : { code: u }) : undefined);
// Any value as cells, never as YAML: lists as pills or code, objects as key=value code.
const value = (v) =>
  typeof v === 'boolean' ? yes(v)
  : Array.isArray(v) ? v.map((x) => (x !== null && typeof x === 'object' ? { code: Object.entries(x).map(([k, y]) => `${k}=${typeof y === 'object' ? JSON.stringify(y) : y}`).join(' ') } : { text: String(x), tone: 'neutral' }))
  : v !== null && typeof v === 'object' ? Object.entries(v).map(([k, y]) => ({ code: `${k}=${typeof y === 'object' ? JSON.stringify(y) : y}` }))
  : v;
const words = (key) => key.replace(/([a-z0-9])([A-Z])/g, '$1 $2').replace(/^./, (c) => c.toUpperCase());
const sheet = (o) => Object.entries(o ?? {}).map(([key, v]) => ({ key: words(key), value: value(v) }));
const view = (module, name) => (name ? { dashboard: `keycloak-${module}`, vars: { name }, text: name, back: true } : undefined);
const rest = (o, ...drop) => Object.fromEntries(Object.entries(o ?? {}).filter(([k]) => !drop.includes(k)));
const make = (tag, props = {}, attrs = {}) => {
  const e = Object.assign(document.createElement(tag), props);
  for (const [k, v] of Object.entries(attrs)) e.setAttribute(k, v);
  return e;
};
const card = (data, rows) => {
  const el = make('kd-card', { data });
  if (rows && rows.length) el.append(make('kd-sheet', { data: rows }, { layout: 'grid' }));
  return el;
};
const el = (id) => context.element.querySelector('#' + id);
const fill = (selector, children) => context.element.querySelector(selector)?.replaceChildren(...children);
const count = (id, n) => el(id)?.setAttribute('count', String(n));
// Protocol mappers, the same everywhere: what each maps, into which claim, which tokens it reaches.
const MAPPER = {
  userProperty: ['User property', (c) => ({ code: c.name }), null],
  userAttribute: ['User attribute', (c) => ({ code: c.name }), null],
  fullName: ['Full name', () => 'first + last name', 'name'],
  groupMembership: ['Group membership', (c) => (c.fullPath ? 'groups, full path' : 'groups'), null],
  userClientRole: ['Client roles', (c) => [view('openid-client', c.clientIdForRoleMappings) ?? 'this client', c.prefix ? { code: `prefix ${c.prefix}` } : undefined], 'resource_access.<client>.roles'],
  userRealmRole: ['Realm roles', (c) => ['realm roles', c.realmRolePrefix ? { code: `prefix ${c.realmRolePrefix}` } : undefined], 'realm_access.roles'],
  hardcodedClaim: ['Hardcoded claim', (c) => ({ code: c.value }), null],
  hardcodedRole: ['Hardcoded role', (c) => ({ code: c.name }), null],
  audience: ['Audience', (c) => view('openid-client', c.includedClient) ?? { code: c.includedCustom }, 'aud'],
  audienceResolve: ['Audience resolve', () => 'clients the user has roles in', 'aud'],
  sub: ['Subject', () => 'the user ID', 'sub'],
  userSessionNote: ['Session note', (c) => ({ code: c.name ?? c.note }), null],
};
const mapperInfo = (m) => {
  const c = m[m.type] ?? {};
  const [label, source, claim] = MAPPER[m.type] ?? [words(m.type ?? ''), () => undefined, null];
  return { c, label, maps: source(c), claim: c.claimName ?? (m.type === 'hardcodedClaim' ? c.name : null) ?? claim };
};
const TARGETS = [['ID token', 'addToIdToken'], ['Access token', 'addToAccessToken'], ['Userinfo', 'addToUserinfo'], ['Introspection', 'addToTokenIntrospection']];
const UNTARGETED = { sub: ['addToIdToken', 'addToUserinfo'], audience: ['addToUserinfo'], hardcodedRole: ['addToIdToken', 'addToUserinfo'] };
const mapperItems = (list) => (list ?? []).map((m, i) => {
  const { label, claim } = mapperInfo(m);
  return { id: m.name ?? `${m.type}-${i}`, label: m.name ?? label, sub: claim ?? undefined, cells: [{ text: label, tone: 'info' }], data: m };
});
const mapperDetail = (m) => {
  const { c, label, maps, claim } = mapperInfo(m);
  const known = ['claimName', 'valueType', 'multivalued', 'aggregate', 'name', 'value', 'clientIdForRoleMappings', 'prefix', 'realmRolePrefix', 'includedClient', 'includedCustom', 'fullPath', ...TARGETS.map(([, k]) => k)];
  const s = make('kd-sheet', {}, { layout: 'grid' });
  s.data = [
    { key: 'Type', value: { text: label, tone: 'info' } },
    { key: 'Maps', value: maps },
    { key: 'Claim', value: claim ? { code: claim } : undefined },
    { key: 'JSON type', value: c.valueType },
    { key: 'Multivalued', value: c.multivalued === undefined ? undefined : yes(c.multivalued) },
    { key: 'Aggregate', value: c.aggregate === undefined ? undefined : yes(c.aggregate) },
    ...sheet(rest(c, ...known)),
  ];
  const into = make('kd-status');
  into.style.marginTop = '12px';
  into.data = { headline: ['Goes into'], checks: TARGETS.filter(([, k]) => !(UNTARGETED[m.type] ?? []).includes(k)).map(([lbl, k]) => ({ label: lbl, ok: c[k] === false ? 'neutral' : true, when: c[k] === undefined ? 'default' : undefined })) };
  return [s, into];
};
Promise.all([import(base + '/kd.js'), import(base + '/k8s.js')]).then(([kd]) => {
  if (!obj) return;
  const s = obj.spec ?? {};
  const a = s.accessSettings ?? {};
  const uriKind = (u) =>
    u.includes('*') ? { text: 'wildcard', tone: 'warning', title: 'matches more than one URL' }
    : /^https?:[/][/](localhost|127[.]0[.]0[.]1|[[]::1[]])([:/]|$)/.test(u) ? { text: 'loopback', tone: 'info', title: 'a local app on this machine' }
    : u.startsWith('https://') ? { text: 'https', tone: 'success' }
    : u.startsWith('http://') ? { text: 'http', tone: 'warning', title: 'not encrypted' }
    : u === '+' ? { text: 'all redirect origins', tone: 'neutral' }
    : { text: 'app scheme', tone: 'neutral' };
  const uriCell = (u) => (/^https?:[/][/][^*]+$/.test(u) ? { href: u, text: u } : { code: u });
  el('general').data = { name: 'General' };
  el('access').data = { name: 'Access' };
  kd.feed(context, {
    '#general-sheet': { data: [
      { key: 'Client ID', value: { code: obj.metadata.name } },
      { key: 'Name', value: s.name },
      { key: 'Description', value: s.description },
      { key: 'Enabled', value: yes(s.enabled !== false) },
      { key: 'In account console', value: flag(s.alwaysDisplayInConsole, 'off') },
      { key: 'Full scope allowed', value: flag(s.fullScopeAllowed, 'on') },
    ] },
    '#urls': { data: [
      { key: 'Root URL', value: link(a.rootUrl) },
      { key: 'Home URL', value: link(a.baseUrl) },
      { key: 'Admin URL', value: link(a.adminUrl) },
    ] },
    '#uris': { data: { columns: [{ key: 'use', label: 'Used for', nowrap: true }, { key: 'uri', label: 'URI' }, { key: 'kind', label: '', nowrap: true }], rows: [
      ...(a.redirectUris ?? []).map((u) => ['Redirect', u]),
      ...(a.postLogoutRedirectUris ?? []).map((u) => ['After logout', u]),
      ...(a.webOrigins ?? []).map((u) => ['Web origin', u]),
    ].map(([use, u]) => ({ use, uri: uriCell(u), kind: uriKind(u) })) } },
  });

  // What Keycloak's own scopes add, for the ones no keycloak.kubed.io object manages.
  const BUILTIN = {
    basic: 'sub and auth_time',
    profile: 'name, family_name, given_name, preferred_username, picture, locale, ...',
    email: 'email and email_verified',
    roles: 'realm_access and resource_access roles, and the audience they imply',
    'web-origins': 'allowed-origins, for CORS',
    acr: 'acr, the authentication context class',
    offline_access: 'an offline refresh token that outlives the session',
    address: 'address',
    phone: 'phone_number and phone_number_verified',
    'microprofile-jwt': 'upn and groups (MicroProfile JWT)',
    organization: 'organization membership',
  };
  const managed = Object.fromEntries(docs.filter((d) => d.kind === 'OpenidClientScope' && (!s.realm || d.spec?.realm === s.realm)).map((d) => [d.spec?.name ?? d.metadata.name, d]));
  const HOW = { default: { text: 'default', tone: 'success', title: 'always in its tokens' }, optional: { text: 'optional', tone: 'info', title: 'only when the app asks for it' } };
  const items = ['default', 'optional'].flatMap((how) => (s.scopes?.[how] ?? []).map((name) => {
    const m = managed[name];
    return { id: name, label: name, sub: m?.spec?.description ?? BUILTIN[name] ?? 'Keycloak built-in', cells: [HOW[how]], data: { name, how, m } };
  }));
  const scopes = el('scopes');
  scopes.items = items;
  scopes.detail = (item) => {
    const { name, how, m } = item.data;
    const ms = m?.spec ?? {};
    const out = [make('kd-sheet', { data: [
      { key: 'Assigned', value: HOW[how] },
      { key: 'Managed by', value: m ? view('openid-client-scope', m.metadata.name) : { text: 'Keycloak built-in', tone: 'neutral' } },
      { key: 'Adds', value: m ? undefined : BUILTIN[name] },
      { key: 'Description', value: ms.description, wide: true },
      { key: 'Consent text', value: ms.consentScreenText },
      { key: 'In token scope', value: m ? flag(ms.includeInTokenScope, 'on') : undefined },
      { key: 'Roles it maps', value: (ms.roles ?? []).map((r) => ({ text: r.client ? `${r.client}: ${r.name}` : r.name, tone: 'primary' })) },
    ] }, { layout: 'grid' })];
    if ((ms.protocolMappers ?? []).length) {
      out.push(make('kd-table', { data: { columns: [{ key: 'name', label: 'Its mappers' }, { key: 'type', label: 'Type' }, { key: 'claim', label: 'Claim' }], rows: ms.protocolMappers.map((x) => { const i = mapperInfo(x); return { name: x.name, type: { text: i.label, tone: 'info' }, claim: i.claim ? { code: i.claim } : undefined }; }) } }, { style: 'display: block; margin-top: 12px' }));
    }
    return out;
  };
  count('sec-scopes', items.length);

  const li = s.login ?? {};
  const lo = s.logout ?? {};
  const tk = s.tokens ?? {};
  const cp = s.compatibility ?? {};
  const not = (v) => (v === undefined ? undefined : !v);
  el('login').data = { name: 'Login' };
  el('logout').data = { name: 'Logout' };
  el('tokens').data = { name: 'Lifespans' };
  el('compat').data = { name: 'Compatibility' };
  kd.feed(context, {
    '#login-sheet': { data: [
      { key: 'Theme', value: show(li.theme, 'realm theme') },
      { key: 'Consent required', value: flag(li.consentRequired, 'off') },
      { key: 'On consent screen', value: flag(li.displayOnConsentScreen, 'on') },
      { key: 'Consent text', value: li.consentScreentText },
    ] },
    '#logout-sheet': { data: [
      { key: 'Front-channel', value: flag(lo.frontChannelLogoutEnabled, 'on') },
      { key: 'Front-channel URL', value: link(lo.frontchannelLogoutUrl) },
      { key: 'Back-channel URL', value: link(lo.backchannelLogoutUrl) ?? dflt('none') },
      { key: 'Session required', value: flag(lo.backchannelLogoutSessionRequired, 'on') },
      { key: 'Revoke offline', value: flag(lo.backchannelLogoutRevokeOfflineSessions, 'off') },
    ] },
    '#tokens-sheet': { data: [
      ['Access token', tk.accessTokenLifespan],
      ['Session idle', tk.clientSessionIdleTimeout],
      ['Session max', tk.clientSessionMaxLifespan],
      ['Offline idle', tk.clientOfflineSessionIdleTimeout],
      ['Offline max', tk.clientOfflineSessionMaxLifespan],
      ['Device code', tk.oauth2DeviceCodeLifespan],
      ['Device polling', tk.oauth2DevicePollingInterval],
    ].map(([key, v]) => ({ key, value: show(v, 'realm default') })).concat([{ key: 'DPoP-bound', value: flag(tk.requireDpopBoundTokens, 'off') }]) },
    '#compat-sheet': { data: [
      { key: 'Refresh tokens', value: flag(cp.useRefreshTokens, 'on') },
      { key: 'Refresh for client credentials', value: flag(cp.useRefreshTokensClientCredentials, 'off') },
      { key: 'Refresh in token exchange', value: flag(cp.allowRefreshTokenInStandardTokenExchange, 'off') },
      { key: 'session_state in response', value: flag(not(cp.excludeSessionStateFromAuthResponse), 'on') },
      { key: 'iss in response', value: flag(not(cp.excludeIssuerFromAuthResponse), 'on') },
    ] },
    '#extra': { data: Object.keys(s.extraConfig ?? {}).length ? { columns: [{ key: 'key', label: 'Extra config' }, { key: 'value', label: 'Value' }], rows: Object.entries(s.extraConfig).map(([key, v]) => ({ key: { code: key }, value: value(v) })) } : undefined },
  });
  count('sec-login', Object.keys(li).length + Object.keys(lo).length);
  count('sec-sessions', Object.keys(tk).length + Object.keys(cp).length + Object.keys(s.extraConfig ?? {}).length);
});
