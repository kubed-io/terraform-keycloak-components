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
Promise.all([import(base + '/kd.js'), import(base + '/k8s.js')]).then(([kd, k8s]) => {
  const ws = docs.find((d) => d.kind === 'Workspace');
  const conds = ws?.status?.conditions ?? [];
  const ready = conds.find((c) => c.type === 'Ready');
  const synced = conds.find((c) => c.type === 'Synced');
  const ok = ready ? k8s.conditionOk(ready) : null;
  const vars = ws?.spec?.forProvider ?? {};
  kd.feed(context, {
    'kd-status': { data: { checks: obj ? k8s.conditions(obj) : [] } },
    'kd-card': {
      data: ws
        ? {
            name: ws.metadata.name,
            icon: k8s.kindIcon(ws.kind, ws.apiVersion),
            tone: ok ? 'success' : ok === false ? 'error' : 'warning',
            state: ok ? 'Applied' : ready?.reason ?? 'Pending',
            message: ok ? undefined : ready?.message,
            cells: [{ dashboard: 'k8s-workspace', vars: { wsname: ws.metadata.name }, text: 'workspace', back: true }],
          }
        : { name: 'No Workspace', tone: 'warning', message: 'Crossplane has not composed one yet.' },
    },
    'kd-card kd-sheet': {
      data: ws
        ? [
            { key: 'Module', value: { code: vars.module }, wide: true },
            { key: 'Provider config', value: ws.spec?.providerConfigRef?.name },
            { key: 'Outputs', value: Object.keys(ws.status?.atProvider?.outputs ?? {}).length },
            { key: 'Synced', value: synced ? `${synced.reason} · ${kd.age(synced.lastTransitionTime)}` : undefined },
            { key: 'Ready since', value: ready ? kd.age(ready.lastTransitionTime) : undefined },
          ]
        : [],
    },
  });
});
