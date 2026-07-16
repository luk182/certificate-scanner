async function loadCerts() {
  const type   = document.getElementById('filterType').value;
  const status = document.getElementById('filterStatus').value;
  let url = '/api/certificates/?';
  if (type)   url += `resource_type=${encodeURIComponent(type)}&`;
  if (status) url += `status=${encodeURIComponent(status)}`;

  const tbody = document.getElementById('certTableBody');
  tbody.innerHTML = `<tr><td colspan="10" class="text-center py-4">
    <div class="spinner-border spinner-border-sm text-primary me-2"></div>Loading...
  </td></tr>`;

  try {
    const res = await fetch(url);
    if (!res.ok) throw new Error('Failed');
    const certs = await res.json();

    document.getElementById('certCount').textContent = `${certs.length} certificate(s) found`;
    tbody.innerHTML = '';

    if (certs.length === 0) {
      tbody.innerHTML = `<tr><td colspan="10" class="text-center text-muted py-4">No certificates found.</td></tr>`;
      return;
    }

    for (const c of certs) {
      const rowClass  = c.status === 'expired' ? 'row-expired' : c.status === 'warning' ? 'row-warning' : 'row-healthy';
      const badgeCls  = c.status === 'healthy'  ? 'badge-healthy' : c.status === 'warning' ? 'badge-warning' : 'badge-expired';
      const badgeTxt  = c.status === 'healthy'  ? 'Healthy' : c.status === 'warning' ? 'Expiring' : 'Expired';
      const expDate   = c.expiration_date ? new Date(c.expiration_date).toLocaleDateString('en-GB') : 'N/A';
      const daysLeft  = c.days_remaining != null
        ? (c.days_remaining < 0 ? `<span class="text-danger fw-bold">${c.days_remaining}d</span>` : `${c.days_remaining}d`)
        : 'N/A';
      const sniHtml   = (c.urls_sni || []).map(s => `<span class="badge bg-light text-dark border">${s}</span>`).join(' ');

      tbody.innerHTML += `
        <tr class="${rowClass}">
          <td class="fw-semibold">${c.cert_name || '-'}</td>
          <td><span class="badge bg-secondary">${c.resource_type}</span></td>
          <td>${c.resource_name}</td>
          <td><small class="text-muted">${c.subscription_name}</small></td>
          <td><small>${sniHtml || '-'}</small></td>
          <td>${expDate}</td>
          <td>${daysLeft}</td>
          <td>${c.cert_location}</td>
          <td>${c.keyvault_name || '<span class="text-muted">-</span>'}</td>
          <td><span class="badge ${badgeCls}">${badgeTxt}</span></td>
        </tr>`;
    }
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="10" class="text-center text-danger py-4">Failed to load certificates.</td></tr>`;
  }
}

loadCerts();
