const RESOURCE_META = {
  "All":         { icon: "bi-shield-check",        label: "All Resources" },
  "APIM":        { icon: "bi-cloud",               label: "API Management" },
  "App Gateway": { icon: "bi-diagram-3",            label: "App Gateway" },
  "App Service": { icon: "bi-window",               label: "App Service" },
  "Functions":   { icon: "bi-lightning-charge",     label: "Functions" },
  "Logic Apps":  { icon: "bi-gear-wide-connected",  label: "Logic Apps" },
  "Front Door":  { icon: "bi-door-open",            label: "Front Door" },
};

async function loadDashboard() {
  const container = document.getElementById('dashboardCards');
  try {
    const res = await fetch('/api/dashboard/');
    if (!res.ok) throw new Error('Failed to load dashboard');
    const data = await res.json();
    container.innerHTML = '';
    const order = ["All", "APIM", "App Gateway", "App Service", "Functions", "Logic Apps", "Front Door"];
    for (const key of order) {
      const d = data[key];
      if (!d) continue;
      const meta = RESOURCE_META[key] || { icon: "bi-box", label: key };
      const isAll = key === "All";
      container.innerHTML += `
        <div class="col-12 col-sm-6 col-xl-3">
          <div class="card p-3 h-100 ${isAll ? 'card-aggregate' : ''}">
            <div class="d-flex align-items-center mb-3">
              <i class="bi ${meta.icon} resource-icon me-2 text-primary"></i>
              <div>
                <div class="fw-bold">${meta.label}</div>
                ${isAll ? '<small class="text-muted">Aggregated total</small>' : ''}
              </div>
            </div>
            <div class="row text-center g-0">
              <div class="col">
                <div class="stat-number stat-healthy">${d.healthy}</div>
                <small class="text-muted">Healthy</small>
              </div>
              <div class="col border-start border-end">
                <div class="stat-number stat-warning">${d.warning}</div>
                <small class="text-muted">Expiring</small>
              </div>
              <div class="col">
                <div class="stat-number stat-expired">${d.expired}</div>
                <small class="text-muted">Expired</small>
              </div>
            </div>
          </div>
        </div>`;
    }
  } catch (e) {
    container.innerHTML = `<div class="col-12"><div class="alert alert-danger">Failed to load dashboard data.</div></div>`;
  }
}

loadDashboard();
