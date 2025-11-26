/**
 * Admin Interface JavaScript
 * Handles client-side interactions for administrative operations
 */

(function() {
    'use strict';

    let allRoles = [];
    let currentEditUserId = null;

    /**
     * Construct API URL using window.API_BASE
     */
    function getApiUrl(action, params = {}) {
        const url = new URL(window.API_BASE + 'admin_api.php', window.location.origin);
        url.searchParams.append('action', action);
        
        Object.keys(params).forEach(key => {
            url.searchParams.append(key, params[key]);
        });

        return url.toString();
    }

    /**
     * Make an API call
     */
    async function apiCall(action, params = {}, method = 'GET', body = null) {
        try {
            const url = getApiUrl(action, params);

            const options = {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                },
                credentials: 'same-origin'
            };

            if (body && method !== 'GET') {
                options.body = JSON.stringify(body);
            }

            const response = await fetch(url, options);
            
            let data;
            try {
                data = await response.json();
            } catch (jsonError) {
                const text = await response.text();
                console.error('Failed to parse JSON response:', text);
                throw new Error('Invalid JSON response from server');
            }

            if (!response.ok) {
                throw new Error(data.error || 'Request failed');
            }

            return data;
        } catch (error) {
            console.error('API call error:', error);
            throw error;
        }
    }

    /**
     * Format date for display
     */
    function formatDate(dateString) {
        if (!dateString) return 'Jamais';
        const date = new Date(dateString);
        return date.toLocaleDateString('fr-FR', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    /**
     * Show alert message
     */
    function showAlert(message, type = 'info') {
        const alertDiv = document.createElement('div');
        alertDiv.className = `alert alert-${type}`;
        alertDiv.textContent = message;
        alertDiv.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 15px 20px;
            background-color: ${type === 'success' ? '#27ae60' : type === 'error' ? '#e74c3c' : '#3498db'};
            color: white;
            border-radius: 4px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.2);
            z-index: 10000;
            animation: slideIn 0.3s ease-out;
        `;
        
        document.body.appendChild(alertDiv);
        
        setTimeout(() => {
            alertDiv.style.animation = 'slideOut 0.3s ease-out';
            setTimeout(() => alertDiv.remove(), 300);
        }, 3000);
    }

    /**
     * Tab switching
     */
    function initTabs() {
        const tabButtons = document.querySelectorAll('.admin-tab-button');
        const tabContents = document.querySelectorAll('.admin-tab-content');

        tabButtons.forEach(button => {
            button.addEventListener('click', () => {
                const tabName = button.getAttribute('data-tab');
                
                // Update active tab button
                tabButtons.forEach(btn => btn.classList.remove('active'));
                button.classList.add('active');
                
                // Update active tab content
                tabContents.forEach(content => content.classList.remove('active'));
                document.getElementById(`tab-${tabName}`).classList.add('active');
                
                // Load data for the active tab
                switch(tabName) {
                    case 'users':
                        loadUsers();
                        break;
                    case 'roles':
                        loadRoles();
                        break;
                    case 'mappings':
                        loadMappings();
                        break;
                }
            });
        });
    }

    /**
     * Load users list
     */
    async function loadUsers(filters = {}) {
        const tbody = document.getElementById('users-tbody');
        tbody.innerHTML = '<tr><td colspan="9" class="loading">Chargement des utilisateurs...</td></tr>';

        try {
            const data = await apiCall('list_users', filters);
            
            if (data.data.length === 0) {
                tbody.innerHTML = '<tr><td colspan="9" style="text-align: center;">Aucun utilisateur trouvé</td></tr>';
                return;
            }

            tbody.innerHTML = data.data.map(user => {
                const roles = user.roles.map(role => 
                    `<span class="badge badge-${role.name}">${role.name}</span>`
                ).join(' ');
                
                const statusBadge = user.is_active === 1 || user.is_active === '1'
                    ? '<span class="badge badge-active">Actif</span>'
                    : '<span class="badge badge-inactive">Inactif</span>';
                
                const authBadge = `<span class="badge badge-${user.auth_method}">${user.auth_method}</span>`;
                
                const isCurrentUser = window.CURRENT_USER_ID && user.id === window.CURRENT_USER_ID;
                const isActive = user.is_active === 1 || user.is_active === '1';
                
                // Show deactivate button only if: not current user, and user is active
                const deactivateButton = (!isCurrentUser && isActive)
                    ? `<button class="btn btn-danger btn-deactivate-user" data-user-id="${user.id}" data-username="${escapeHtml(user.username)}">Supprimer</button>`
                    : '';

                return `
                    <tr data-user-id="${user.id}">
                        <td>${user.id}</td>
                        <td>${escapeHtml(user.username)}</td>
                        <td>${escapeHtml(user.email)}</td>
                        <td>${authBadge}</td>
                        <td>${roles || '<em>Aucun rôle</em>'}</td>
                        <td class="user-status-cell">${statusBadge}</td>
                        <td>${formatDate(user.created_at)}</td>
                        <td>${formatDate(user.last_login)}</td>
                        <td>
                            <button class="btn btn-edit" onclick="editUser(${user.id})">Modifier</button>
                            ${deactivateButton}
                        </td>
                    </tr>
                `;
            }).join('');
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="9" style="text-align: center; color: #e74c3c;">Erreur: ${escapeHtml(error.message)}</td></tr>`;
            showAlert('Erreur lors du chargement des utilisateurs: ' + error.message, 'error');
        }
    }

    /**
     * Load roles list
     */
    async function loadRoles() {
        const tbody = document.getElementById('roles-tbody');
        tbody.innerHTML = '<tr><td colspan="4" class="loading">Chargement des rôles...</td></tr>';

        try {
            const data = await apiCall('list_roles');
            allRoles = data.data; // Store for use in other forms
            
            if (data.data.length === 0) {
                tbody.innerHTML = '<tr><td colspan="4" style="text-align: center;">Aucun rôle trouvé</td></tr>';
                return;
            }

            tbody.innerHTML = data.data.map(role => `
                <tr>
                    <td>${role.id}</td>
                    <td><span class="badge badge-${role.name}">${escapeHtml(role.name)}</span></td>
                    <td>${escapeHtml(role.description || '')}</td>
                    <td>${formatDate(role.created_at)}</td>
                </tr>
            `).join('');
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="4" style="text-align: center; color: #e74c3c;">Erreur: ${escapeHtml(error.message)}</td></tr>`;
            showAlert('Erreur lors du chargement des rôles: ' + error.message, 'error');
        }
    }

    /**
     * Load mappings list
     */
    async function loadMappings() {
        const tbody = document.getElementById('mappings-tbody');
        tbody.innerHTML = '<tr><td colspan="8" class="loading">Chargement des mappings...</td></tr>';

        try {
            const data = await apiCall('list_mappings');
            
            if (data.data.length === 0) {
                tbody.innerHTML = '<tr><td colspan="8" style="text-align: center;">Aucun mapping trouvé</td></tr>';
                return;
            }

            tbody.innerHTML = data.data.map(mapping => {
                const sourceBadge = `<span class="badge badge-${mapping.source}">${mapping.source.toUpperCase()}</span>`;
                const roleBadge = `<span class="badge badge-${mapping.role_name}">${escapeHtml(mapping.role_name)}</span>`;
                
                return `
                    <tr>
                        <td>${mapping.id}</td>
                        <td>${sourceBadge}</td>
                        <td><code style="font-size: 11px;">${escapeHtml(mapping.dn_or_group)}</code></td>
                        <td>${roleBadge}</td>
                        <td>${escapeHtml(mapping.created_by_username || 'N/A')}</td>
                        <td>${formatDate(mapping.created_at)}</td>
                        <td>${escapeHtml(mapping.notes || '')}</td>
                        <td>
                            <button class="btn btn-danger" onclick="deleteMapping(${mapping.id})">Supprimer</button>
                        </td>
                    </tr>
                `;
            }).join('');
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="8" style="text-align: center; color: #e74c3c;">Erreur: ${escapeHtml(error.message)}</td></tr>`;
            showAlert('Erreur lors du chargement des mappings: ' + error.message, 'error');
        }
    }

    /**
     * Open create user modal
     */
    window.openCreateUserModal = async function() {
        currentEditUserId = null;
        
        // Load roles if not already loaded
        if (allRoles.length === 0) {
            try {
                const data = await apiCall('list_roles');
                allRoles = data.data;
            } catch (error) {
                showAlert('Erreur lors du chargement des rôles', 'error');
                return;
            }
        }
        
        document.getElementById('modal-user-title').textContent = 'Créer un utilisateur';
        document.getElementById('user-id').value = '';
        document.getElementById('form-user').reset();
        document.getElementById('password-group').style.display = 'block';
        document.getElementById('password-hint').style.display = 'none';
        document.getElementById('password-required-indicator').style.display = 'inline';
        document.getElementById('user-password').required = true;
        
        // Hide auth_method field for new users (always database)
        document.getElementById('auth-method-group').style.display = 'none';
        
        // Hide delete button for new users
        const deleteBtn = document.getElementById('btn-delete-user-modal');
        if (deleteBtn) {
            deleteBtn.style.display = 'none';
        }
        
        // Populate roles checkboxes
        populateRolesCheckboxes([]);
        
        // Use the new modal helper
        window.openModalById('modal-user');
    };

    /**
     * Edit user
     */
    window.editUser = async function(userId) {
        currentEditUserId = userId;
        
        try {
            // Load roles if not already loaded
            if (allRoles.length === 0) {
                const rolesData = await apiCall('list_roles');
                allRoles = rolesData.data;
            }
            
            // Load user data
            const data = await apiCall('get_user', { id: userId });
            const user = data.data;
            
            document.getElementById('modal-user-title').textContent = 'Modifier un utilisateur';
            document.getElementById('user-id').value = user.id;
            document.getElementById('user-username').value = user.username;
            document.getElementById('user-email').value = user.email;
            document.getElementById('user-auth-method').value = user.auth_method;
            document.getElementById('user-is-active').value = user.is_active;
            document.getElementById('user-password').value = '';
            document.getElementById('user-password').required = false;
            document.getElementById('password-hint').style.display = 'block';
            document.getElementById('password-required-indicator').style.display = 'none';
            
            // Show auth_method field for existing users (read-only display)
            const authMethodGroup = document.getElementById('auth-method-group');
            authMethodGroup.style.display = 'block';
            // Make auth_method read-only to prevent changes
            document.getElementById('user-auth-method').disabled = true;
            
            // Password field visibility based on auth method
            if (user.auth_method === 'database') {
                document.getElementById('password-group').style.display = 'block';
            } else {
                // Hide password field for AD/LDAP users
                document.getElementById('password-group').style.display = 'none';
            }
            
            // Populate roles checkboxes with current user roles
            const userRoleIds = user.roles.map(role => role.id);
            populateRolesCheckboxes(userRoleIds);
            
            // Show/hide delete button in modal
            // Hide if: editing current user OR user is already inactive
            const deleteBtn = document.getElementById('btn-delete-user-modal');
            const isCurrentUser = window.CURRENT_USER_ID && userId === window.CURRENT_USER_ID;
            const isActive = user.is_active === 1 || user.is_active === '1';
            
            if (deleteBtn) {
                if (!isCurrentUser && isActive) {
                    deleteBtn.style.display = 'inline-block';
                } else {
                    deleteBtn.style.display = 'none';
                }
            }
            
            // Use the new modal helper
            window.openModalById('modal-user');
        } catch (error) {
            showAlert('Erreur lors du chargement de l\'utilisateur: ' + error.message, 'error');
        }
    };

    /**
     * Close user modal
     */
    window.closeUserModal = function() {
        window.closeModalById('modal-user');
        document.getElementById('form-user').reset();
        currentEditUserId = null;
    };

    /**
     * Populate roles checkboxes
     */
    function populateRolesCheckboxes(selectedRoleIds) {
        const container = document.getElementById('user-roles-checkboxes');
        container.innerHTML = allRoles.map(role => {
            const checked = selectedRoleIds.includes(role.id) ? 'checked' : '';
            return `
                <label>
                    <input type="checkbox" name="role_ids[]" value="${role.id}" ${checked}>
                    ${escapeHtml(role.name)} - ${escapeHtml(role.description || '')}
                </label>
            `;
        }).join('');
    }

    /**
     * Save user (create or update)
     */
    async function saveUser(event) {
        event.preventDefault();
        
        const formData = new FormData(event.target);
        const userData = {
            username: formData.get('username'),
            email: formData.get('email'),
            is_active: formData.get('is_active')
        };
        
        // ENFORCE: All admin-created users use database authentication
        // AD/LDAP users are created automatically during their first login
        if (!currentEditUserId) {
            userData.auth_method = 'database';
        }
        
        const password = formData.get('password');
        if (password) {
            userData.password = password;
        }
        
        // Get selected role IDs
        const roleCheckboxes = document.querySelectorAll('input[name="role_ids[]"]:checked');
        const selectedRoleIds = Array.from(roleCheckboxes).map(cb => parseInt(cb.value));
        
        try {
            if (currentEditUserId) {
                // Update existing user
                await apiCall('update_user', { id: currentEditUserId }, 'POST', userData);
                
                // Update roles: get current roles and add/remove as needed
                const userResponse = await apiCall('get_user', { id: currentEditUserId });
                const currentRoleIds = userResponse.data.roles.map(r => r.id);
                
                // Add new roles
                for (const roleId of selectedRoleIds) {
                    if (!currentRoleIds.includes(roleId)) {
                        await apiCall('assign_role', { user_id: currentEditUserId, role_id: roleId }, 'POST');
                    }
                }
                
                // Remove old roles
                for (const roleId of currentRoleIds) {
                    if (!selectedRoleIds.includes(roleId)) {
                        await apiCall('remove_role', { user_id: currentEditUserId, role_id: roleId }, 'POST');
                    }
                }
                
                showAlert('Utilisateur mis à jour avec succès', 'success');
            } else {
                // Create new user
                userData.role_ids = selectedRoleIds;
                await apiCall('create_user', {}, 'POST', userData);
                showAlert('Utilisateur créé avec succès', 'success');
            }
            
            closeUserModal();
            loadUsers();
        } catch (error) {
            showAlert('Erreur: ' + error.message, 'error');
        }
    }

    /**
     * Open create mapping modal
     */
    window.openCreateMappingModal = async function() {
        // Load roles if not already loaded
        if (allRoles.length === 0) {
            try {
                const data = await apiCall('list_roles');
                allRoles = data.data;
            } catch (error) {
                showAlert('Erreur lors du chargement des rôles', 'error');
                return;
            }
        }
        
        // Populate roles dropdown
        const roleSelect = document.getElementById('mapping-role');
        roleSelect.innerHTML = allRoles.map(role => 
            `<option value="${role.id}">${escapeHtml(role.name)} - ${escapeHtml(role.description || '')}</option>`
        ).join('');
        
        document.getElementById('form-mapping').reset();
        window.openModalById('modal-mapping');
    };

    /**
     * Close mapping modal
     */
    window.closeMappingModal = function() {
        window.closeModalById('modal-mapping');
        document.getElementById('form-mapping').reset();
    };

    /**
     * Save mapping
     */
    async function saveMapping(event) {
        event.preventDefault();
        
        const formData = new FormData(event.target);
        const mappingData = {
            source: formData.get('source'),
            dn_or_group: formData.get('dn_or_group'),
            role_id: parseInt(formData.get('role_id')),
            notes: formData.get('notes')
        };
        
        try {
            await apiCall('create_mapping', {}, 'POST', mappingData);
            showAlert('Mapping créé avec succès', 'success');
            closeMappingModal();
            loadMappings();
        } catch (error) {
            showAlert('Erreur: ' + error.message, 'error');
        }
    }

    /**
     * Delete mapping
     */
    window.deleteMapping = async function(mappingId) {
        if (!confirm('Êtes-vous sûr de vouloir supprimer ce mapping ?')) {
            return;
        }
        
        try {
            await apiCall('delete_mapping', { id: mappingId }, 'POST');
            showAlert('Mapping supprimé avec succès', 'success');
            loadMappings();
        } catch (error) {
            showAlert('Erreur: ' + error.message, 'error');
        }
    };

    /**
     * Deactivate user (from table button)
     */
    window.deactivateUser = async function(userId, username) {
        if (!confirm('Êtes-vous sûr de vouloir désactiver l\'utilisateur "' + username + '" ?\n\nCette action désactivera le compte (l\'utilisateur ne pourra plus se connecter) mais conservera l\'historique.')) {
            return;
        }
        
        try {
            await apiCall('deactivate_user', { id: userId }, 'POST');
            showAlert('Utilisateur "' + username + '" désactivé avec succès', 'success');
            loadUsers();
        } catch (error) {
            showAlert('Erreur: ' + error.message, 'error');
        }
    };

    /**
     * Deactivate user from modal
     */
    window.deactivateUserFromModal = async function() {
        if (!currentEditUserId) {
            showAlert('ID utilisateur introuvable', 'error');
            return;
        }
        
        const username = document.getElementById('user-username').value;
        
        if (!confirm('Êtes-vous sûr de vouloir désactiver l\'utilisateur "' + username + '" ?\n\nCette action désactivera le compte (l\'utilisateur ne pourra plus se connecter) mais conservera l\'historique.')) {
            return;
        }
        
        try {
            await apiCall('deactivate_user', { id: currentEditUserId }, 'POST');
            showAlert('Utilisateur "' + username + '" désactivé avec succès', 'success');
            closeUserModal();
            loadUsers();
        } catch (error) {
            showAlert('Erreur: ' + error.message, 'error');
        }
    };

    /**
     * Escape HTML to prevent XSS
     */
    function escapeHtml(text) {
        if (text === null || text === undefined) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    /**
     * Get master zone files for domain dropdown
     */
    async function getZoneFilesMaster() {
        try {
            const url = new URL(window.API_BASE + 'zone_api.php', window.location.origin);
            url.searchParams.append('action', 'list_zones');
            url.searchParams.append('file_type', 'master');
            url.searchParams.append('status', 'active');
            url.searchParams.append('per_page', '1000');
            
            const response = await fetch(url.toString(), {
                method: 'GET',
                credentials: 'same-origin'
            });
            
            const data = await response.json();
            if (!response.ok) {
                throw new Error(data.error || 'Failed to load zone files');
            }
            
            return data.data || [];
        } catch (error) {
            console.error('Error loading zone files:', error);
            showAlert('Erreur lors du chargement des fichiers de zone: ' + error.message, 'error');
            return [];
        }
    }

    /**
     * Populate domain zone file dropdown with searchable functionality
     */
    async function populateDomainZoneSelect(selectedId = null) {
        const select = document.getElementById('domain-zone-file');
        const searchInput = document.getElementById('domain-zone-search');
        
        select.innerHTML = '<option value="">Sélectionner un fichier de zone...</option>';
        
        const zones = await getZoneFilesMaster();
        
        // Function to populate select with filtered zones
        function populateOptions(filteredZones) {
            select.innerHTML = '<option value="">Sélectionner un fichier de zone...</option>';
            filteredZones.forEach(zone => {
                const option = document.createElement('option');
                option.value = zone.id;
                // Show domain if available, otherwise show name and filename
                const displayText = zone.domain 
                    ? `${zone.domain} (${zone.name})`
                    : `${zone.name} (${zone.filename})`;
                option.textContent = displayText;
                if (selectedId && zone.id == selectedId) {
                    option.selected = true;
                }
                select.appendChild(option);
            });
        }
        
        // Initial population
        populateOptions(zones);
        
        // Bind search input to filter options (remove old listener first to avoid duplicates)
        if (searchInput) {
            // Clone and replace to remove all event listeners
            const newSearchInput = searchInput.cloneNode(true);
            searchInput.parentNode.replaceChild(newSearchInput, searchInput);
            
            newSearchInput.value = '';
            newSearchInput.addEventListener('input', function() {
                const searchTerm = this.value.toLowerCase();
                const filteredZones = zones.filter(zone => {
                    const name = (zone.name || '').toLowerCase();
                    const filename = (zone.filename || '').toLowerCase();
                    const domain = (zone.domain || '').toLowerCase();
                    return name.includes(searchTerm) || filename.includes(searchTerm) || domain.includes(searchTerm);
                });
                populateOptions(filteredZones);
            });
        }
    }

    /**
     * Load domains list
     */
    async function loadDomains(filters = {}) {
        const tbody = document.getElementById('domains-tbody');
        tbody.innerHTML = '<tr><td colspan="5" class="loading">Chargement des domaines...</td></tr>';

        try {
            const params = { ...filters };
            const url = new URL(window.API_BASE + 'domain_api.php', window.location.origin);
            url.searchParams.append('action', 'list');
            
            Object.keys(params).forEach(key => {
                if (params[key] !== '') {
                    url.searchParams.append(key, params[key]);
                }
            });

            const response = await fetch(url.toString(), {
                method: 'GET',
                credentials: 'same-origin'
            });
            
            const data = await response.json();
            
            if (!response.ok) {
                throw new Error(data.error || 'Failed to load domains');
            }
            
            if (!data.data || data.data.length === 0) {
                tbody.innerHTML = '<tr><td colspan="5" style="text-align: center;">Aucun domaine trouvé</td></tr>';
                return;
            }

            tbody.innerHTML = data.data.map(domain => {
                return `
                    <tr>
                        <td>${escapeHtml(domain.domain)}</td>
                        <td>${escapeHtml(domain.zone_name || 'N/A')}</td>
                        <td>${formatDate(domain.created_at)}</td>
                        <td>${formatDate(domain.updated_at)}</td>
                        <td>
                            <button class="btn btn-edit" onclick="editDomain(${domain.id})">Modifier</button>
                            <button class="btn btn-danger" onclick="deleteDomain(${domain.id})">Supprimer</button>
                        </td>
                    </tr>
                `;
            }).join('');
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="5" style="text-align: center; color: #e74c3c;">Erreur: ${escapeHtml(error.message)}</td></tr>`;
            showAlert('Erreur lors du chargement des domaines: ' + error.message, 'error');
        }
    }

    /**
     * Open create domain modal
     */
    window.openCreateDomainModal = async function() {
        console.warn('DEPRECATION WARNING: Domain management UI is deprecated. Domains are now managed as part of zone files. Use zone file management instead.');
        
        document.getElementById('domainModalTitle').textContent = 'Créer un domaine';
        document.getElementById('domain-id').value = '';
        document.getElementById('form-domain').reset();
        document.getElementById('domain-created-info').style.display = 'none';
        document.getElementById('domain-updated-info').style.display = 'none';
        document.getElementById('btn-delete-domain').style.display = 'none'; // Hide delete button for create
        
        await populateDomainZoneSelect();
        
        window.openModalById('domainModal');
    };

    /**
     * Open edit domain modal
     */
    window.editDomain = async function(domainId) {
        console.warn('DEPRECATION WARNING: Domain management UI is deprecated. Domains are now managed as part of zone files. Use zone file management instead.');
        
        try {
            const url = new URL(window.API_BASE + 'domain_api.php', window.location.origin);
            url.searchParams.append('action', 'get');
            url.searchParams.append('id', domainId);

            const response = await fetch(url.toString(), {
                method: 'GET',
                credentials: 'same-origin'
            });
            
            const data = await response.json();
            
            if (!response.ok) {
                throw new Error(data.error || 'Failed to load domain');
            }

            const domain = data.data;
            
            document.getElementById('domainModalTitle').textContent = 'Modifier un domaine';
            document.getElementById('domain-id').value = domain.id;
            document.getElementById('domain-name').value = domain.domain;
            
            await populateDomainZoneSelect(domain.zone_file_id);
            
            // Show created/updated info
            if (domain.created_at) {
                document.getElementById('domain-created-at').value = formatDate(domain.created_at);
                document.getElementById('domain-created-info').style.display = 'block';
            }
            
            if (domain.updated_at) {
                document.getElementById('domain-updated-at').value = formatDate(domain.updated_at);
                document.getElementById('domain-updated-info').style.display = 'block';
            }
            
            // Show delete button for edit
            document.getElementById('btn-delete-domain').style.display = 'inline-block';
            
            window.openModalById('domainModal');
        } catch (error) {
            showAlert('Erreur lors du chargement du domaine: ' + error.message, 'error');
        }
    };

    /**
     * Close domain modal
     */
    window.closeDomainModal = function() {
        window.closeModalById('domainModal');
    };

    /**
     * Backward-compatible wrapper for editing domain modal
     * Alias for editDomain function
     */
    window.openEditDomainModal = window.editDomain;

    /**
     * Submit domain form (create or update)
     */
    window.submitDomainForm = async function(event) {
        event.preventDefault();
        
        const domainId = document.getElementById('domain-id').value;
        const isEdit = domainId !== '';
        
        const formData = {
            domain: document.getElementById('domain-name').value.trim(),
            zone_file_id: document.getElementById('domain-zone-file').value
        };

        try {
            const url = new URL(window.API_BASE + 'domain_api.php', window.location.origin);
            url.searchParams.append('action', isEdit ? 'update' : 'create');
            if (isEdit) {
                url.searchParams.append('id', domainId);
            }

            const response = await fetch(url.toString(), {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                credentials: 'same-origin',
                body: JSON.stringify(formData)
            });

            // Read response as text first to handle non-JSON responses
            const responseText = await response.text();
            
            let data;
            try {
                data = JSON.parse(responseText);
            } catch (jsonError) {
                // If response is not JSON, show raw text or generic error
                const errorMsg = responseText.trim() || `HTTP ${response.status}: ${response.statusText}`;
                throw new Error(errorMsg);
            }

            if (!response.ok) {
                throw new Error(data.error || 'Failed to save domain');
            }

            showAlert(isEdit ? 'Domaine modifié avec succès' : 'Domaine créé avec succès', 'success');
            closeDomainModal();
            loadDomains();
        } catch (error) {
            showAlert('Erreur: ' + error.message, 'error');
        }
    };

    /**
     * Delete domain (set status to deleted)
     */
    window.deleteDomain = async function(domainId) {
        if (!confirm('Êtes-vous sûr de vouloir supprimer ce domaine ?')) {
            return;
        }

        try {
            const url = new URL(window.API_BASE + 'domain_api.php', window.location.origin);
            url.searchParams.append('action', 'set_status');
            url.searchParams.append('id', domainId);
            url.searchParams.append('status', 'deleted');

            const response = await fetch(url.toString(), {
                method: 'GET',
                credentials: 'same-origin'
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.error || 'Failed to delete domain');
            }

            showAlert('Domaine supprimé avec succès', 'success');
            loadDomains();
        } catch (error) {
            showAlert('Erreur: ' + error.message, 'error');
        }
    };

    /**
     * Delete domain from modal
     */
    window.deleteDomainFromModal = async function() {
        const domainId = document.getElementById('domain-id').value;
        if (!domainId) {
            showAlert('ID du domaine introuvable', 'error');
            return;
        }
        
        if (!confirm('Êtes-vous sûr de vouloir supprimer ce domaine ?')) {
            return;
        }

        try {
            const url = new URL(window.API_BASE + 'domain_api.php', window.location.origin);
            url.searchParams.append('action', 'set_status');
            url.searchParams.append('id', domainId);
            url.searchParams.append('status', 'deleted');

            const response = await fetch(url.toString(), {
                method: 'GET',
                credentials: 'same-origin'
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.error || 'Failed to delete domain');
            }

            showAlert('Domaine supprimé avec succès', 'success');
            closeDomainModal();
            loadDomains();
        } catch (error) {
            showAlert('Erreur: ' + error.message, 'error');
        }
    };

    /**
     * Safely attach an event listener with error handling and debug logging
     */
    function safeAddEventListener(elementId, eventType, handler, description) {
        try {
            var el = document.getElementById(elementId);
            if (el) {
                el.addEventListener(eventType, handler);
                console.debug('[admin.js] Listener attached: ' + description + ' (' + elementId + ')');
                return true;
            } else {
                console.debug('[admin.js] Element not found for listener: ' + elementId);
                return false;
            }
        } catch (error) {
            console.error('[admin.js] Error attaching listener to ' + elementId + ':', error);
            return false;
        }
    }

    /**
     * Initialize filter buttons
     */
    function initFilters() {
        safeAddEventListener('btn-filter-users', 'click', function() {
            var filters = {};
            
            var username = document.getElementById('filter-username').value.trim();
            if (username) filters.username = username;
            
            var authMethod = document.getElementById('filter-auth-method').value;
            if (authMethod) filters.auth_method = authMethod;
            
            var isActive = document.getElementById('filter-is-active').value;
            if (isActive !== '') filters.is_active = isActive;
            
            loadUsers(filters);
        }, 'Filter users button');
        
        safeAddEventListener('btn-reset-filters', 'click', function() {
            document.getElementById('filter-username').value = '';
            document.getElementById('filter-auth-method').value = '';
            document.getElementById('filter-is-active').value = '';
            loadUsers();
        }, 'Reset filters button');
        
        // Domain filter buttons removed - domains are now managed via zone files
    }

    /**
     * Initialize on page load
     */
    document.addEventListener('DOMContentLoaded', function() {
        console.debug('[admin.js] DOMContentLoaded - Starting initialization');
        
        try {
            initTabs();
            console.debug('[admin.js] Tabs initialized');
        } catch (error) {
            console.error('[admin.js] Error initializing tabs:', error);
        }
        
        try {
            initFilters();
            console.debug('[admin.js] Filters initialized');
        } catch (error) {
            console.error('[admin.js] Error initializing filters:', error);
        }
        
        // Load initial data
        try {
            loadUsers();
            loadRoles(); // Pre-load roles for dropdowns
            console.debug('[admin.js] Initial data load started');
        } catch (error) {
            console.error('[admin.js] Error loading initial data:', error);
        }
        
        // Button event listeners with safe attachment
        safeAddEventListener('btn-create-user', 'click', openCreateUserModal, 'Create user button');
        safeAddEventListener('btn-create-mapping', 'click', openCreateMappingModal, 'Create mapping button');
        // Domain button removed - domains are now managed via zone files
        
        // Form submissions with safe attachment
        safeAddEventListener('form-user', 'submit', saveUser, 'User form submission');
        safeAddEventListener('form-mapping', 'submit', saveMapping, 'Mapping form submission');
        // Domain form removed - domains are now managed via zone files
        
        // Close modals on outside click
        window.addEventListener('click', function(e) {
            if (e.target.classList.contains('modal')) {
                e.target.classList.remove('show');
            }
        });
        
        // Global delegation fallback for create buttons
        // This ensures buttons work even if direct attachment failed
        document.addEventListener('click', function(e) {
            try {
                var target = e.target;
                // Check if clicked element or its parent is the button
                var createUserBtn = target.closest('#btn-create-user');
                var createMappingBtn = target.closest('#btn-create-mapping');
                var deactivateUserBtn = target.closest('.btn-deactivate-user');
                
                if (createUserBtn) {
                    console.debug('[admin.js] Delegation fallback triggered for #btn-create-user');
                    if (typeof openCreateUserModal === 'function') {
                        openCreateUserModal();
                    }
                } else if (createMappingBtn) {
                    console.debug('[admin.js] Delegation fallback triggered for #btn-create-mapping');
                    if (typeof openCreateMappingModal === 'function') {
                        openCreateMappingModal();
                    }
                } else if (deactivateUserBtn) {
                    // Handle deactivate user button click via delegation
                    var userId = parseInt(deactivateUserBtn.getAttribute('data-user-id'), 10);
                    var username = deactivateUserBtn.getAttribute('data-username') || '';
                    if (userId && typeof deactivateUser === 'function') {
                        deactivateUser(userId, username);
                    }
                }
            } catch (error) {
                console.error('[admin.js] Error in delegation fallback:', error);
            }
        });
        
        console.debug('[admin.js] Initialization complete');
        
        // Add CSS animations
        var style = document.createElement('style');
        style.textContent = "\n            @keyframes slideIn {\n                from {\n                    transform: translateX(100%);\n                    opacity: 0;\n                }\n                to {\n                    transform: translateX(0);\n                    opacity: 1;\n                }\n            }\n            \n            @keyframes slideOut {\n                from {\n                    transform: translateX(0);\n                    opacity: 1;\n                }\n                to {\n                    transform: translateX(100%);\n                    opacity: 0;\n                }\n            }\n        ";
        document.head.appendChild(style);
    });

    // Domain modal functions removed - domains are now managed via zone files
})();
