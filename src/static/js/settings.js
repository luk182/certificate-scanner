function toggleScope() {
  const val = document.getElementById('scopeType').value;
  document.getElementById('subscriptionInput').classList.toggle('d-none', val !== 'subscriptions');
  document.getElementById('mgInput').classList.toggle('d-none', val !== 'management_groups');
}

async function loadSettings() {
  try {
    const res = await fetch('/api/settings/');
    const data = await res.json();
    if (!data || Object.keys(data).length === 0) return;
    document.getElementById('scopeType').value = data.scope_type || 'subscriptions';
    toggleScope();
    document.getElementById('subscriptionIds').value = (data.subscription_ids || []).join('\n');
    document.getElementById('mgIds').value = (data.management_group_ids || []).join('\n');
    const freq = data.frequency || 'daily';
    const radio = document.querySelector(`input[name=frequency][value="${freq}"]`);
    if (radio) radio.checked = true;
  } catch (e) {
    console.error('Failed to load settings', e);
  }
}

document.getElementById('settingsForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const scopeType = document.getElementById('scopeType').value;
  const subIds = document.getElementById('subscriptionIds').value
    .split(/[\n,]/).map(s => s.trim()).filter(Boolean);
  const mgIds = document.getElementById('mgIds').value
    .split(/[\n,]/).map(s => s.trim()).filter(Boolean);
  const frequency = document.querySelector('input[name=frequency]:checked').value;

  await fetch('/api/settings/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ scope_type: scopeType, subscription_ids: subIds, management_group_ids: mgIds, frequency }),
  });

  const msg = document.getElementById('saveMsg');
  msg.classList.remove('d-none');
  setTimeout(() => msg.classList.add('d-none'), 3000);
});

loadSettings();
