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
  if (!obj) return;
  const chain = [];
  const back = kd.contextVariable(context, 'back');
  if (back) chain.push({ dashboard: back, text: '←', title: 'back' });
  const realm = obj.spec?.realm;
  if (realm) {
    chain.push({ dashboard: 'keycloak-realm', vars: { name: realm }, text: realm, icon: k8s.kindIcon('Realm', obj.apiVersion), back: true });
  }
  kd.feed(context, { 'kd-bar': { data: { ...k8s.bar(obj), chain } } });
});
