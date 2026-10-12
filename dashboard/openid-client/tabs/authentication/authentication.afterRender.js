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
Promise.all([import(base + '/kd.js'), import(base + '/k8s.js')]).then(([kd, k8s]) => {
  if (!obj) return;
  const s = obj.spec ?? {};
  const caps = s.capabilities ?? {};
  const st = obj.status ?? {};
  const TYPE = {
    CONFIDENTIAL: { text: 'Confidential', tone: 'success', title: 'authenticates with a secret' },
    PUBLIC: { text: 'Public', tone: 'info', title: 'no secret: a browser or CLI app' },
    'BEARER-ONLY': { text: 'Bearer-only', tone: 'neutral', title: 'never logs anyone in; only accepts tokens' },
  };
  const access = TYPE[s.accessType] ?? { text: s.accessType ?? 'Public', tone: 'info' };
  const pkce = caps.pkceCodeChallengeMethod;
  const FLOWS = [
    ['Standard flow', caps.standardFlowEnabled, 'browser login: the app redirects here and gets a code back'],
    ['Direct access grants', caps.directAccessGrantsEnabled, 'the app sends a username and password itself'],
    ['Implicit flow', caps.implicitFlowEnabled, 'tokens straight in the redirect (legacy)'],
    ['Service account', caps.serviceAccountsEnabled, 'the client logs in as itself (client credentials)'],
    ['Device grant', caps.oauth2DeviceAuthorizationGrantEnabled, 'CLIs and TVs: approve a code on another device'],
    ['Token exchange', caps.standardTokenExchangeEnabled, 'swap a token for one meant for another client'],
  ];
  const secret = s.writeSecretTo?.name ? k8s.refLink({ kind: 'Secret', name: s.writeSecretTo.name, namespace: s.writeSecretTo.namespace, apiVersion: 'v1' }) : undefined;
  el('creds').data = { name: 'Credentials', message: s.accessType === 'CONFIDENTIAL' ? 'Authenticates with its client ID and secret.' : s.accessType === 'BEARER-ONLY' ? 'No credentials: it only checks tokens that other clients bring.' : 'No secret: anyone can start a login as it.' };
  el('sa').data = { name: 'Service account', cells: [caps.serviceAccountsEnabled ? { text: 'on', tone: 'success' } : { text: 'off', tone: 'neutral' }] };
  const byClient = {};
  for (const r of s.serviceAccountRoles ?? []) (byClient[r.client ?? ''] ??= []).push(r.name);
  kd.feed(context, {
    '#flows': { data: {
      headline: [
        access,
        s.authorization ? { text: 'Authorization on', tone: 'success' } : undefined,
        pkce ? { text: `PKCE ${pkce}`, tone: 'success' } : caps.standardFlowEnabled && s.accessType === 'PUBLIC' ? { text: 'no PKCE', tone: 'warning', title: 'a public client that logs users in should require PKCE S256' } : undefined,
      ],
      checks: FLOWS.map(([label, on, what]) => (on ? { label, ok: true, detail: what } : { label, ok: 'neutral' })),
    } },
    '#creds-sheet': { data: [
      { key: 'Secret written to', value: secret ?? (s.accessType === 'CONFIDENTIAL' ? dflt('not written to Kubernetes') : undefined) },
      { key: 'Service account user', value: st.serviceAccountUserId ? { code: st.serviceAccountUserId } : undefined },
      { key: 'Resource server', value: st.resourceServerId ? { code: st.resourceServerId } : undefined },
    ] },
    '#saroles': { empty: caps.serviceAccountsEnabled ? 'It holds no roles.' : 'It has no service account.', data: { columns: [{ key: 'client', label: 'Roles of', nowrap: true }, { key: 'roles', label: 'Roles' }], rows: Object.entries(byClient).map(([c, roles]) => ({ client: c ? view('openid-client', c) : { text: 'realm', tone: 'neutral' }, roles: roles.map((r) => ({ text: r, tone: 'primary' })) })) } },
  });

  const z = s.authorization;
  el('authz-state').data = { headline: z ? [{ text: 'on', tone: 'success' }, { text: z.policyEnforcementMode ?? 'ENFORCING', tone: 'info' }, { text: `decision ${z.decisionStrategy ?? 'UNANIMOUS'}`, tone: 'neutral' }, z.allowRemoteResourceManagement ? { text: 'remote resource management', tone: 'neutral' } : undefined] : [{ text: 'off', tone: 'neutral' }, 'this client uses no fine-grained permissions'] };
  const box = el('authz');
  box.replaceChildren();
  const section = (title, columns, rows) => {
    if (!rows.length) return;
    box.append(make('h3', { textContent: title }), make('kd-table', { data: { columns, rows } }));
  };
  const pills = (list, tone = 'info') => (list ?? []).map((x) => ({ text: typeof x === 'string' ? x : x.name ?? x.id ?? String(x), tone }));
  if (z) {
    const who = (p) => {
      const b = p[p.type] ?? {};
      if (p.type === 'client') return (b.clients ?? []).map((c) => view('openid-client', c));
      if (p.type === 'regex') return { code: `${b.targetClaim} ~ ${b.pattern}` };
      if (p.type === 'time') return { code: [b.notBefore, b.notOnOrAfter].filter(Boolean).join(' -> ') || 'by calendar' };
      if (p.type === 'aggregate') return pills(b.policies, 'neutral');
      return pills(b.roles ?? b.groups ?? b.users ?? b.scopes, 'primary');
    };
    section('Resources', [{ key: 'name', label: 'Resource' }, { key: 'type', label: 'Type' }, { key: 'uris', label: 'URIs' }, { key: 'scopes', label: 'Scopes' }],
      (z.resources ?? []).map((r) => ({ name: r.displayName ?? r.name, type: r.type ? { code: r.type } : undefined, uris: (r.uris ?? []).map((u) => ({ code: u })), scopes: pills(r.scopes) })));
    section('Scopes', [{ key: 'name', label: 'Scope' }, { key: 'display', label: 'Display name' }], (z.scopes ?? []).map((x) => ({ name: { code: x.name }, display: x.displayName })));
    section('Policies', [{ key: 'name', label: 'Policy' }, { key: 'type', label: 'Type', nowrap: true }, { key: 'who', label: 'Who' }, { key: 'logic', label: 'Logic', nowrap: true }, { key: 'description', label: 'Description' }],
      (z.policies ?? []).map((p) => ({ name: p.name, type: { text: p.type, tone: 'info' }, who: who(p), logic: p.logic === 'NEGATIVE' ? { text: 'negative', tone: 'warning' } : 'positive', description: p.description })));
    section('Permissions', [{ key: 'name', label: 'Permission' }, { key: 'type', label: 'On', nowrap: true }, { key: 'policies', label: 'Policies' }, { key: 'decision', label: 'Decision', nowrap: true }, { key: 'description', label: 'Description' }],
      (z.permissions ?? []).map((p) => ({ name: p.name, type: { text: p.type ?? 'resource', tone: 'info' }, policies: pills(p.policies, 'neutral'), decision: p.decisionStrategy ?? 'UNANIMOUS', description: p.description })));
  }
  section('Admin permissions on this client', [{ key: 'scope', label: 'Scope' }, { key: 'policies', label: 'Policies' }, { key: 'decision', label: 'Decision' }, { key: 'description', label: 'Description' }],
    (s.permissions ?? []).map((p) => ({ scope: { code: p.scope }, policies: pills(p.policies, 'neutral'), decision: p.decisionStrategy, description: p.description })));
});
