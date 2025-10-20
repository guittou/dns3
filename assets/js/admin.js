// assets/js/admin.js - minimal admin UI logic (DB-only user creation)
(function(){
  if (!window.BASE_URL) window.BASE_URL = '/';
  const API = (window.API_BASE || (window.BASE_URL + 'api/')) + 'admin_api.php';

  function apiCall(action, data = {}, method = 'GET') {
    const url = new URL(API, location.origin);
    url.searchParams.append('action', action);
    if (method === 'GET') {
      Object.keys(data).forEach(k => url.searchParams.append(k, data[k]));
      return fetch(url.toString(), { credentials: 'same-origin' }).then(async r => {
        const text = await r.text();
        try { return JSON.parse(text); } catch (e) { console.error('Invalid JSON from API:', text); throw e; }
      });
    } else {
      return fetch(url.toString(), {
        method: 'POST',
        credentials: 'same-origin',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify(data)
      }).then(async r => {
        const text = await r.text();
        try { return JSON.parse(text); } catch (e) { console.error('Invalid JSON from API:', text); throw e; }
      });
    }
  }

  document.addEventListener('DOMContentLoaded', function(){
    document.querySelectorAll('.admin-tab-button').forEach(btn=>{
      btn.addEventListener('click', () => {
        document.querySelectorAll('.admin-tab-button').forEach(b=>b.classList.remove('active'));
        btn.classList.add('active');
        const tab = btn.getAttribute('data-tab');
        document.querySelectorAll('.admin-tab').forEach(sec => sec.style.display = 'none');
        document.getElementById('tab-' + tab).style.display = 'block';
      });
    });

    // load users & roles & mappings
    loadUsers();
    loadRoles();
    loadMappings();

    document.getElementById('admin-create-user').addEventListener('click', openCreateUserModal);
    document.getElementById('admin-user-modal-close').addEventListener('click', closeUserModal);
    document.getElementById('admin-user-form').addEventListener('submit', submitUserForm);
    document.getElementById('admin-create-mapping').addEventListener('click', openCreateMappingModal);
  });

  async function loadUsers() {
    const res = await apiCall('list_users');
    const body = document.getElementById('admin-users-body');
    body.innerHTML = '';
    (res.data || []).forEach(u=>{
      const tr = document.createElement('tr');
      tr.innerHTML = `<td>${u.id}</td>
                      <td>${escape(u.username)}</td>
                      <td>${escape(u.email)}</td>
                      <td>${escape(u.roles||'')}</td>
                      <td>${u.is_active ? 'Oui' : 'Non'}</td>
                      <td>
                        <button class="btn-small" data-id="${u.id}" data-action="edit">Éditer</button>
                      </td>`;
      body.appendChild(tr);
    });
    body.querySelectorAll('button[data-action="edit"]').forEach(b=>{
      b.addEventListener('click', async () => {
        const id = b.getAttribute('data-id');
        const r = await apiCall('get_user', {id});
        openEditUserModal(r.data);
      });
    });
  }

  async function loadRoles() {
    const res = await apiCall('list_roles');
    const sel = document.getElementById('admin-roles-select');
    if (sel) {
      sel.innerHTML = '';
      (res.data || []).forEach(r=>{
        const opt = document.createElement('option');
        opt.value = r.id; opt.textContent = r.name;
        sel.appendChild(opt);
      });
    }
    const rolesList = document.getElementById('admin-roles-list');
    if (rolesList) {
      rolesList.innerHTML = '<ul>' + (res.data || []).map(r => `<li>${escape(r.name)} - ${escape(r.description||'')}</li>`).join('') + '</ul>';
    }
  }

  async function loadMappings() {
    const res = await apiCall('list_mappings');
    const body = document.getElementById('admin-mappings-body');
    body.innerHTML = '';
    (res.data || []).forEach(m=>{
      const tr = document.createElement('tr');
      tr.innerHTML = `<td>${m.id}</td><td>${escape(m.source)}</td><td>${escape(m.dn_or_group)}</td><td>${escape(m.role_name)}</td><td>${m.created_at}</td>
                      <td><button class="btn-small" data-id="${m.id}" data-action="del-map">Supprimer</button></td>`;
      body.appendChild(tr);
    });
    body.querySelectorAll('button[data-action="del-map"]').forEach(b=>{
      b.addEventListener('click', async ()=>{
        if (!confirm('Supprimer ce mapping ?')) return;
        await apiCall('delete_mapping', {id: b.getAttribute('data-id')}, 'POST');
        await loadMappings();
      });
    });
  }

  function openCreateUserModal() {
    document.getElementById('admin-user-form').reset();
    document.getElementById('admin-user-id').value = '';
    document.getElementById('admin-user-modal').style.display = 'block';
  }
  function openEditUserModal(user) {
    document.getElementById('admin-user-id').value = user.id;
    document.getElementById('admin-username').value = user.username;
    document.getElementById('admin-email').value = user.email;
    const sel = document.getElementById('admin-roles-select');
    Array.from(sel.options).forEach(o => o.selected = (user.roles||[]).includes(o.text));
    document.getElementById('admin-user-modal').style.display = 'block';
  }
  function closeUserModal(){ document.getElementById('admin-user-modal').style.display = 'none'; }

  async function submitUserForm(ev) {
    ev.preventDefault();
    const id = document.getElementById('admin-user-id').value;
    const payload = {
      username: document.getElementById('admin-username').value,
      email: document.getElementById('admin-email').value,
      password: document.getElementById('admin-password').value,
      roles: Array.from(document.getElementById('admin-roles-select').selectedOptions).map(o => o.value),
      is_active: 1,
      // force DB-only at client-side as well (server enforces too)
      auth_method: 'database'
    };
    if (id) {
      await apiCall('update_user', Object.assign({id}, payload), 'POST');
    } else {
      await apiCall('create_user', payload, 'POST');
    }
    closeUserModal();
    await loadUsers();
  }

  function escape(s){ if (!s && s!==0) return ''; return String(s).replace(/[&<>"']/g, c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;','\'':'&#39;'}[c])); }

  // mapping modal (simplified) - open prompt
  function openCreateMappingModal() {
    const source = prompt('Source (ad or ldap)', 'ad');
    if (!source) return;
    const dn = prompt('DN / Group name (ex: CN=Group,OU=Groups,DC=example,DC=com)');
    if (!dn) return;
    apiCall('list_roles').then(res=>{
      const roles = res.data || [];
      const roleNames = roles.map(r=>`${r.id}:${r.name}`).join(', ');
      const roleChoice = prompt('Role id to assign. Available: ' + roleNames);
      if (!roleChoice) return;
      apiCall('create_mapping', {source, dn_or_group: dn, role_id: parseInt(roleChoice)}, 'POST').then(()=>loadMappings());
    });
  }

})();
