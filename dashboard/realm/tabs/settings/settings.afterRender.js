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
  const sec = s.securityDefenses ?? {};
  const p = s.policies ?? {};
  el('general').data = { name: 'General' };
  el('login').data = { name: 'Login' };
  const lg = s.login ?? {};
  kd.feed(context, {
    '#general-sheet': { data: [
      { key: 'Display name', value: s.displayName },
      { key: 'Enabled', value: yes(s.enabled !== false) },
      { key: 'SSL required', value: show(s.sslRequired, 'external') },
      { key: 'Organizations', value: flag(s.organizationsEnabled, 'off') },
      { key: 'User-managed access', value: flag(s.userManagedAccess, 'off') },
      { key: 'Admin permissions', value: flag(s.adminPermissionsEnabled, 'off') },
      ...sheet(s.themes),
      { key: 'Locales', value: value(s.internationalization?.supportedLocales) },
      { key: 'Default locale', value: s.internationalization?.defaultLocale },
    ] },
    '#login-sheet': { data: [
      { key: 'User registration', value: flag(lg.registrationAllowed, 'off') },
      { key: 'Email as username', value: flag(lg.registrationEmailAsUsername, 'off') },
      { key: 'Edit username', value: flag(lg.editUsernameAllowed, 'off') },
      { key: 'Forgot password', value: flag(lg.resetPasswordAllowed, 'off') },
      { key: 'Remember me', value: flag(lg.rememberMe, 'off') },
      { key: 'Verify email', value: flag(lg.verifyEmail, 'off') },
      { key: 'Login with email', value: flag(lg.loginWithEmailAllowed, 'on') },
      { key: 'Duplicate emails', value: flag(lg.duplicateEmailsAllowed, 'off') },
    ] },
    '#tokens': { data: sheet(s.tokens) },
    '#smtp': { data: s.smtp ? [
      { key: 'Server', value: { code: `${s.smtp.host ?? ''}:${s.smtp.port ?? ''}` } },
      { key: 'From', value: [s.smtp.fromDisplayName, s.smtp.from ? { code: s.smtp.from } : undefined] },
      { key: 'Reply to', value: s.smtp.replyTo ? [s.smtp.replyToDisplayName, { code: s.smtp.replyTo }] : undefined },
      { key: 'Envelope from', value: s.smtp.envelopeFrom },
      { key: 'StartTLS', value: flag(s.smtp.starttls, 'off') },
      { key: 'SSL', value: flag(s.smtp.ssl, 'off') },
      { key: 'Credentials', value: s.smtp.credentialsRef ? k8s.refLink({ kind: 'Secret', name: s.smtp.credentialsRef.name, namespace: s.smtp.credentialsRef.namespace, apiVersion: 'v1' }) : undefined },
    ] : [] },
    '#events': { data: sheet(s.events) },
  });
  count('sec-tokens', Object.keys(s.tokens ?? {}).length);
  count('sec-email', s.smtp ? 1 : 0);
  count('sec-events', Object.keys(s.events ?? {}).length);

  // The client scopes the realm gives every new client.
  const managed = Object.fromEntries(docs.filter((d) => d.kind === 'OpenidClientScope' && d.spec?.realm === obj.metadata.name).map((d) => [d.spec?.name ?? d.metadata.name, d]));
  const HOW = { default: { text: 'default', tone: 'success' }, optional: { text: 'optional', tone: 'info' } };
  const items = ['default', 'optional'].flatMap((how) => (s.clientScopes?.[how] ?? []).map((name) => ({ id: name, label: name, sub: managed[name]?.spec?.description ?? 'Keycloak built-in', cells: [HOW[how]], data: { name, how, m: managed[name] } })));
  const scopes = el('scopes');
  scopes.items = items;
  scopes.detail = (item) => {
    const { how, m } = item.data;
    return [make('kd-sheet', { data: [
      { key: 'Added to new clients as', value: HOW[how] },
      { key: 'Managed by', value: m ? view('openid-client-scope', m.metadata.name) : { text: 'Keycloak built-in', tone: 'neutral' } },
      { key: 'Description', value: m?.spec?.description, wide: true },
      { key: 'Mappers', value: (m?.spec?.protocolMappers ?? []).map((x) => ({ text: x.name, tone: 'info' })) },
    ] }, { layout: 'grid' })];
  };
  count('sec-scopes', items.length);

  // Security: the password policy in words, then brute force, OTP, headers and required actions.
  const RULE = {
    length: (n) => `at least ${n} characters`, maxLength: (n) => `at most ${n} characters`,
    digits: (n) => `${n} digit${n === '1' ? '' : 's'}`, lowerCase: (n) => `${n} lowercase`, upperCase: (n) => `${n} uppercase`,
    specialChars: (n) => `${n} special character${n === '1' ? '' : 's'}`, notUsername: () => 'not the username', notEmail: () => 'not the email',
    passwordHistory: (n) => `not one of the last ${n}`, forceExpiredPasswordChange: (n) => `expires after ${n} days`,
    regexPattern: (x) => `matches ${x}`, hashIterations: (n) => `${n} hash iterations`, hashAlgorithm: (x) => `hashed with ${x}`,
  };
  const rules = (p.passwordPolicy ?? '').split(/[ ]+and[ ]+/).filter(Boolean).map((r) => {
    const m = r.match(/^(\w+)(?:\((.*)\))?$/);
    const f = m && RULE[m[1]];
    return { label: f ? f(m[2]) : r, ok: true };
  });
  el('password').data = { headline: [rules.length ? 'Passwords must be' : { text: 'no password policy', tone: 'warning' }], checks: rules };
  el('brute').data = { name: 'Brute-force detection', cells: [sec.bruteForceDetection ? { text: 'on', tone: 'success' } : { text: 'off', tone: 'neutral' }] };
  const mfa = [p.otpPolicy, p.webAuthnPolicy, p.webAuthnPasswordlessPolicy].some((x) => x && Object.keys(x).length);
  el('otp').data = { name: 'OTP and WebAuthn', message: mfa ? undefined : "Keycloak's defaults: time-based OTP, 6 digits, every 30 seconds." };
  kd.feed(context, {
    '#brute-sheet': { data: sheet(sec.bruteForceDetection) },
    '#otp-sheet': { data: [...sheet(p.otpPolicy), ...sheet(p.webAuthnPolicy), ...sheet(p.webAuthnPasswordlessPolicy)] },
    '#headers': { data: Object.keys(sec.headers ?? {}).length ? { columns: [{ key: 'header', label: 'Security header' }, { key: 'value', label: 'Value' }], rows: Object.entries(sec.headers).map(([k, v]) => ({ header: words(k), value: { code: String(v) } })) } : undefined },
    '#actions': { data: Object.keys(s.requiredActions ?? {}).length ? { columns: [{ key: 'alias', label: 'Required action' }, { key: 'enabled', label: 'Enabled' }, { key: 'dflt', label: 'For new users' }, { key: 'priority', label: 'Priority', align: 'right' }, { key: 'config', label: 'Config' }], rows: Object.entries(s.requiredActions).map(([alias, r]) => ({ alias: r.name ?? alias, enabled: yes(r.enabled !== false), dflt: r.defaultAction ? yes(true) : undefined, priority: r.priority, config: value(r.config) })) } : undefined },
  });
  count('sec-security', rules.length + Object.keys(sec).length + Object.keys(s.requiredActions ?? {}).length);

  // The user profile: one attribute at a time.
  const up = s.userProfile ?? {};
  const label = (a) => (a.displayName && !a.displayName.startsWith('${') ? a.displayName : a.name);
  const attrs = el('attributes');
  attrs.items = (up.attributes ?? []).map((a) => ({ id: a.name, label: label(a), sub: a.name, cells: [(a.requiredForRoles ?? []).length || a.required ? { text: 'required', tone: 'warning' } : undefined, a.group ? { text: a.group, tone: 'neutral' } : undefined], data: a }));
  attrs.detail = (item) => {
    const a = item.data;
    const roles = (list) => (list ?? []).map((r) => ({ text: r, tone: 'primary' }));
    const out = [make('kd-sheet', { data: [
      { key: 'Attribute', value: { code: a.name } },
      { key: 'Label', value: a.displayName?.startsWith('${') ? { text: 'translated', tone: 'neutral', title: `message key ${a.displayName}` } : a.displayName },
      { key: 'Required for', value: roles(a.requiredForRoles ?? (a.required ? ['everyone'] : [])) },
      { key: 'Who sees it', value: roles(a.permissions?.view) },
      { key: 'Who edits it', value: roles(a.permissions?.edit) },
      { key: 'Group', value: a.group },
      { key: 'Multivalued', value: a.multivalued === undefined ? undefined : yes(a.multivalued) },
      ...sheet(rest(a, 'name', 'displayName', 'requiredForRoles', 'required', 'permissions', 'validators', 'group', 'multivalued')),
    ] }, { layout: 'grid' })];
    const v = Object.entries(a.validators ?? {});
    if (v.length) out.push(make('kd-table', { data: { columns: [{ key: 'name', label: 'Validator' }, { key: 'settings', label: 'Settings' }], rows: v.map(([name, cfg]) => ({ name: { code: name }, settings: value(cfg) })) } }, { style: 'display: block; margin-top: 12px' }));
    return out;
  };
  kd.feed(context, { '#groups': { data: (up.groups ?? []).length ? { columns: [{ key: 'name', label: 'Attribute group' }, { key: 'header', label: 'Header' }, { key: 'description', label: 'Description' }], rows: up.groups.map((g) => ({ name: { code: g.name }, header: g.displayHeader, description: g.displayDescription })) } : undefined } });
  count('sec-profile', (up.attributes ?? []).length);

  // Client policies, profiles and registration policies.
  kd.feed(context, {
    '#cprofiles': { data: (s.clientProfiles ?? []).length ? { columns: [{ key: 'name', label: 'Client profile' }, { key: 'description', label: 'Description' }, { key: 'executors', label: 'Executors' }], rows: s.clientProfiles.map((x) => ({ name: x.name, description: x.description, executors: value(x.executors) })) } : undefined },
    '#cpolicies': { data: (s.clientPolicies ?? []).length ? { columns: [{ key: 'name', label: 'Client policy' }, { key: 'enabled', label: 'Enabled' }, { key: 'profiles', label: 'Profiles' }, { key: 'conditions', label: 'Conditions' }], rows: s.clientPolicies.map((x) => ({ name: x.name, enabled: yes(x.enabled !== false), profiles: value(x.profiles), conditions: value(x.conditions) })) } : undefined },
    '#registration': { data: (s.clientRegistration ?? []).length ? { columns: [{ key: 'name', label: 'Registration policy' }, { key: 'provider', label: 'Provider' }, { key: 'sub', label: 'For' }, { key: 'config', label: 'Config' }], rows: s.clientRegistration.map((x) => ({ name: x.name, provider: { code: x.providerId }, sub: x.subType, config: value(x.config) })) } : undefined },
  });
  count('sec-clientpolicies', (s.clientProfiles ?? []).length + (s.clientPolicies ?? []).length + (s.clientRegistration ?? []).length);
});
