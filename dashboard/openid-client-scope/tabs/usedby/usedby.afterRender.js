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
  const scope = obj?.spec?.name ?? self.name;
  const realmName = obj?.spec?.realm;
  const rows = [];
  for (const d of docs.filter((x) => x.kind === 'OpenidClient' && (!realmName || x.spec?.realm === realmName))) {
    for (const how of ['default', 'optional']) {
      if ((d.spec?.scopes?.[how] ?? []).includes(scope)) rows.push({ who: view('openid-client', d.metadata.name), how: { text: how, tone: how === 'default' ? 'success' : 'info' } });
    }
  }
  const realm = docs.find((x) => x.kind === 'Realm' && x.metadata.name === realmName);
  for (const how of ['default', 'optional']) {
    if ((realm?.spec?.clientScopes?.[how] ?? []).includes(scope)) rows.push({ who: view('realm', realmName), how: { text: `realm ${how}`, tone: 'neutral' } });
  }
  kd.feed(context, { '#usedby': { data: { columns: [{ key: 'who', label: 'Requested by' }, { key: 'how', label: 'As' }], rows } } });
});
