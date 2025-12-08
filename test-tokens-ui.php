<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Admin Tokens UI</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
        }
        
        .admin-container {
            padding: 20px;
            max-width: 1400px;
            margin: 0 auto;
        }
        
        .admin-container h1 {
            margin-bottom: 20px;
            color: #2c3e50;
        }
        
        .admin-tabs {
            display: flex;
            border-bottom: 2px solid #e0e0e0;
            margin-bottom: 20px;
        }
        
        .admin-tab-button {
            padding: 12px 24px;
            background: none;
            border: none;
            border-bottom: 3px solid transparent;
            cursor: pointer;
            font-size: 16px;
            color: #666;
            transition: all 0.3s;
        }
        
        .admin-tab-button:hover {
            color: #2c3e50;
            background-color: #f5f5f5;
        }
        
        .admin-tab-button.active {
            color: #2c3e50;
            border-bottom-color: #3498db;
            font-weight: bold;
        }
        
        .admin-tab-content {
            display: none;
        }
        
        .admin-tab-content.active {
            display: block;
        }
        
        .tab-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        
        .tab-header h2 {
            margin: 0;
            color: #2c3e50;
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .btn-primary {
            background-color: #3498db;
            color: white;
        }
        
        .btn-primary:hover {
            background-color: #2980b9;
        }
        
        .btn .icon {
            font-size: 18px;
            font-weight: bold;
        }
        
        .info-box {
            background-color: #e8f4f8;
            border-left: 4px solid #3498db;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 4px;
        }
        
        .info-box p {
            margin: 5px 0;
        }
        
        .info-box code {
            background-color: #34495e;
            color: #ecf0f1;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: monospace;
            font-size: 12px;
        }
        
        .table-container {
            overflow-x: auto;
            background: white;
            border-radius: 4px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .admin-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .admin-table th {
            background-color: #34495e;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: bold;
        }
        
        .admin-table td {
            padding: 12px;
            border-bottom: 1px solid #ecf0f1;
        }
        
        .admin-table tbody tr:hover {
            background-color: #f8f9fa;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: bold;
        }
        
        .badge-token-active {
            background-color: #27ae60;
            color: white;
        }
        
        .badge-revoked {
            background-color: #e74c3c;
            color: white;
        }
        
        .badge-expired {
            background-color: #e67e22;
            color: white;
        }
        
        .btn-danger {
            background-color: #e74c3c;
            color: white;
            padding: 6px 12px;
            font-size: 12px;
            margin-right: 5px;
        }
        
        .btn-danger:hover {
            background-color: #c0392b;
        }
    </style>
</head>
<body>
    <div class="admin-container">
        <h1>Administration - Test Interface Tokens API</h1>
        
        <!-- Tabs Navigation -->
        <div class="admin-tabs">
            <button class="admin-tab-button active" data-tab="tokens">Tokens API</button>
        </div>
        
        <!-- Tab Content: API Tokens -->
        <div class="admin-tab-content active" id="tab-tokens">
            <div class="tab-header">
                <h2>Tokens API</h2>
                <button class="btn btn-primary" id="btn-create-token">
                    <span class="icon">+</span> Créer un token
                </button>
            </div>
            
            <div class="info-box">
                <p><strong>Tokens API</strong> permettent l'authentification via Bearer token pour les appels API automatisés.</p>
                <p>⚠️ <strong>Important:</strong> Le token en clair n'est visible qu'une seule fois après création. Copiez-le et conservez-le en lieu sûr.</p>
                <p><strong>Utilisation:</strong> Ajoutez l'en-tête <code>Authorization: Bearer VOTRE_TOKEN</code> à vos requêtes API.</p>
            </div>
            
            <div class="table-container">
                <table class="admin-table" id="tokens-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Nom</th>
                            <th>Préfixe</th>
                            <th>Créé le</th>
                            <th>Expire le</th>
                            <th>Dernier usage</th>
                            <th>Statut</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="tokens-tbody">
                        <!-- Sample data for visual testing -->
                        <tr>
                            <td>1</td>
                            <td>Script de backup</td>
                            <td><code>a1b2c3d4...</code></td>
                            <td>8 déc. 2025, 22:15</td>
                            <td>Jamais</td>
                            <td>8 déc. 2025, 22:20</td>
                            <td><span class="badge badge-token-active">Actif</span></td>
                            <td>
                                <button class="btn btn-danger">Révoquer</button>
                                <button class="btn btn-danger">Supprimer</button>
                            </td>
                        </tr>
                        <tr>
                            <td>2</td>
                            <td>CI/CD Pipeline</td>
                            <td><code>e5f6g7h8...</code></td>
                            <td>5 déc. 2025, 10:30</td>
                            <td>5 janv. 2026, 10:30</td>
                            <td>7 déc. 2025, 15:45</td>
                            <td><span class="badge badge-token-active">Actif</span></td>
                            <td>
                                <button class="btn btn-danger">Révoquer</button>
                                <button class="btn btn-danger">Supprimer</button>
                            </td>
                        </tr>
                        <tr>
                            <td>3</td>
                            <td>Token de test</td>
                            <td><code>i9j0k1l2...</code></td>
                            <td>1 déc. 2025, 08:00</td>
                            <td>Jamais</td>
                            <td>2 déc. 2025, 14:20</td>
                            <td><span class="badge badge-revoked">Révoqué</span></td>
                            <td>
                                <button class="btn btn-danger">Supprimer</button>
                            </td>
                        </tr>
                        <tr>
                            <td>4</td>
                            <td>Token temporaire</td>
                            <td><code>m3n4o5p6...</code></td>
                            <td>20 nov. 2025, 16:00</td>
                            <td>30 nov. 2025, 16:00</td>
                            <td>28 nov. 2025, 12:00</td>
                            <td><span class="badge badge-expired">Expiré</span></td>
                            <td>
                                <button class="btn btn-danger">Supprimer</button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    
    <script>
        // Simple test script to show button interaction
        document.getElementById('btn-create-token').addEventListener('click', function() {
            alert('Bouton "Créer un token" fonctionnel!\n\nDans l\'application réelle, cela ouvrira le modal de création.');
        });
    </script>
</body>
</html>
