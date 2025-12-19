#!/usr/bin/env python3
"""
BIND Zone File Importer for dns3

Imports BIND-format zone files into the dns3 application using either:
- API mode (default): HTTP calls to zone_api.php and dns_api.php endpoints
- DB mode (--db-mode): Direct MySQL insertion with schema introspection

Features:
- Parses zone files using dnspython library
- Extracts $ORIGIN, SOA, default TTL, and all resource records
- Handles $INCLUDE directives with --create-includes flag:
  * Creates separate zone_file entries for master and include files
  * Establishes zone_file_includes relationships
  * Preserves $INCLUDE directives in master zone content
  * Supports deduplication by file path or content hash
  * Detects circular includes and limits recursion depth
  * Robust path resolution: tries multiple strategies to locate include files
  * Security: prevents includes outside base directory (unless --allow-abs-include)
- Supports dry-run mode for safe testing
- Validates input and provides detailed error reporting
- Transaction support with rollback on errors (DB mode)

Dependencies: python3, dnspython, requests, pymysql

Usage examples:
  # API mode with $INCLUDE support
  python3 scripts/import_bind_zones.py --dir /path/to/zones --api-url http://localhost/dns3 --api-token abc123 --create-includes

  # DB mode with $INCLUDE support
  python3 scripts/import_bind_zones.py --dir /path/to/zones --db-mode --db-user root --db-pass secret --create-includes
  
  # With additional search paths for includes
  python3 scripts/import_bind_zones.py --dir /path/to/zones --db-mode --db-user root --db-pass secret --create-includes --include-search-paths "/var/named/includes:/etc/bind/includes"

  # Dry-run mode to preview changes
  python3 scripts/import_bind_zones.py --dir /path/to/zones --dry-run --api-url http://localhost/dns3 --api-token abc123 --create-includes

  # Example mode (quick test with sample zone)
  python3 scripts/import_bind_zones.py --example
"""

import argparse
import sys
import os
import re
import logging
import hashlib
from typing import Dict, List, Optional, Tuple, Any, Set
from pathlib import Path

# Check for required dependencies
try:
    import dns.zone
    import dns.rdatatype
    import dns.name
    import dns.rdataclass
except ImportError:
    print("ERROR: dnspython library not found. Install with: pip install dnspython", file=sys.stderr)
    sys.exit(1)

try:
    import requests
except ImportError:
    print("WARNING: requests library not found. API mode will not work. Install with: pip install requests", file=sys.stderr)
    requests = None

try:
    import pymysql
    import pymysql.cursors
except ImportError:
    print("WARNING: pymysql library not found. DB mode will not work. Install with: pip install pymysql", file=sys.stderr)
    pymysql = None


class ZoneImporter:
    """Main class for importing BIND zone files"""
    
    # Common DNS record types for parsing
    COMMON_RECORD_TYPES = ('A', 'AAAA', 'CNAME', 'MX', 'NS', 'PTR', 'TXT', 'SRV', 
                          'CAA', 'SSHFP', 'TLSA', 'NAPTR', 'DNSKEY', 'RRSIG', 
                          'NSEC', 'NSEC3', 'DS')
    
    def __init__(self, args):
        self.args = args
        self.logger = self._setup_logging()
        self.db_conn = None
        self.db_columns = {}
        self.stats = {
            'zones_created': 0,
            'records_created': 0,
            'includes_created': 0,
            'errors': 0,
            'skipped': 0
        }
        # Track processed includes to avoid duplicates
        self.processed_includes: Dict[str, int] = {}  # path -> zone_id mapping
        self.include_depth: int = 0  # Track recursion depth
        self.max_include_depth: int = 50  # Maximum include depth
        self.visited_includes: Set[str] = set()  # Detect cycles
        
    def _setup_logging(self) -> logging.Logger:
        """Configure logging with optional file output and rotation"""
        # Determine log level
        if hasattr(self.args, 'log_level') and self.args.log_level:
            level_name = self.args.log_level.upper()
            level = getattr(logging, level_name, logging.INFO)
        elif self.args.verbose:
            level = logging.DEBUG
        else:
            level = logging.INFO
        
        # Configure formatters
        formatter = logging.Formatter(
            '%(asctime)s [%(levelname)s] %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
        # Get root logger
        logger = logging.getLogger(__name__)
        logger.setLevel(level)
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(level)
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)
        
        # File handler with rotation (if log_file specified)
        if hasattr(self.args, 'log_file') and self.args.log_file:
            from logging.handlers import RotatingFileHandler
            import os
            
            # Ensure log directory exists
            log_dir = os.path.dirname(self.args.log_file)
            if log_dir and not os.path.exists(log_dir):
                os.makedirs(log_dir, exist_ok=True)
            
            # Create rotating file handler (10MB max, 5 backups)
            file_handler = RotatingFileHandler(
                self.args.log_file,
                maxBytes=10 * 1024 * 1024,  # 10 MB
                backupCount=5,
                encoding='utf-8'
            )
            file_handler.setLevel(level)
            file_handler.setFormatter(formatter)
            logger.addHandler(file_handler)
            
            logger.info(f"Logging to file: {self.args.log_file}")
        
        return logger
    
    def _connect_db(self):
        """Connect to MySQL database (DB mode only)"""
        if not pymysql:
            self.logger.error("pymysql not installed. Cannot use DB mode.")
            sys.exit(1)
            
        try:
            self.db_conn = pymysql.connect(
                host=self.args.db_host,
                port=self.args.db_port,
                user=self.args.db_user,
                password=self.args.db_pass,
                database=self.args.db_name,
                charset='utf8mb4',
                cursorclass=pymysql.cursors.DictCursor
            )
            self.logger.info(f"Connected to database: {self.args.db_name}@{self.args.db_host}")
            self._detect_schema()
        except pymysql.Error as e:
            self.logger.error(f"Database connection failed: {e}")
            sys.exit(1)
    
    def _detect_schema(self):
        """Detect available columns in zone_files and dns_records tables"""
        tables = ['zone_files', 'dns_records', 'zone_file_includes']
        
        with self.db_conn.cursor() as cursor:
            for table in tables:
                cursor.execute(
                    "SELECT COLUMN_NAME FROM information_schema.COLUMNS "
                    "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s",
                    (self.args.db_name, table)
                )
                columns = [row['COLUMN_NAME'] for row in cursor.fetchall()]
                self.db_columns[table] = columns
                self.logger.debug(f"Table {table} has columns: {', '.join(columns)}")
    
    def _check_zone_exists(self, zone_name: str) -> bool:
        """Check if zone already exists in database"""
        if self.args.db_mode:
            with self.db_conn.cursor() as cursor:
                cursor.execute("SELECT id FROM zone_files WHERE name = %s", (zone_name,))
                return cursor.fetchone() is not None
        else:
            # API mode: query via API
            try:
                response = requests.get(
                    f"{self.args.api_url}/api/zone_api.php",
                    params={'action': 'list_zones', 'search': zone_name},
                    headers={'Authorization': f'Bearer {self.args.api_token}'},
                    timeout=10
                )
                if response.status_code == 200:
                    data = response.json()
                    zones = data.get('zones', [])
                    return any(z.get('name') == zone_name for z in zones)
                return False
            except Exception as e:
                self.logger.warning(f"Failed to check zone existence via API: {e}")
                return False
    
    def _create_zone_api(self, zone_data: Dict) -> Optional[int]:
        """Create zone via API"""
        if not requests:
            self.logger.error("requests library not installed. Cannot use API mode.")
            return None
            
        try:
            response = requests.post(
                f"{self.args.api_url}/api/zone_api.php?action=create_zone",
                json=zone_data,
                headers={'Authorization': f'Bearer {self.args.api_token}'},
                timeout=30
            )
            
            if response.status_code in (200, 201):
                result = response.json()
                zone_id = result.get('id') or result.get('zone_id')
                self.logger.info(f"Zone created via API: {zone_data['name']} (ID: {zone_id})")
                return zone_id
            else:
                self.logger.error(f"API error creating zone: {response.status_code} - {response.text}")
                return None
        except Exception as e:
            self.logger.error(f"Failed to create zone via API: {e}")
            return None
    
    def _create_zone_db(self, zone_data: Dict) -> Optional[int]:
        """Create zone via direct DB insertion"""
        columns = ['name', 'filename', 'file_type', 'status', 'created_by', 'domain']
        optional_columns = [
            'directory', 'default_ttl', 'soa_refresh', 'soa_retry', 
            'soa_expire', 'soa_minimum', 'soa_rname', 'soa_serial', 'mname',
            'dnssec_include_ksk', 'dnssec_include_zsk'
        ]
        
        # Build column list based on what's available in schema
        available_columns = []
        values = []
        
        for col in columns:
            if col in self.db_columns['zone_files']:
                available_columns.append(col)
                values.append(zone_data.get(col))
        
        for col in optional_columns:
            if col in self.db_columns['zone_files'] and col in zone_data:
                available_columns.append(col)
                values.append(zone_data[col])
        
        # Add timestamps
        if 'created_at' in self.db_columns['zone_files']:
            available_columns.append('created_at')
            values.append('NOW()')
        
        try:
            with self.db_conn.cursor() as cursor:
                placeholders = ', '.join(['%s' if v != 'NOW()' else 'NOW()' for v in values])
                actual_values = [v for v in values if v != 'NOW()']
                
                sql = f"INSERT INTO zone_files ({', '.join(available_columns)}) VALUES ({placeholders})"
                cursor.execute(sql, actual_values)
                self.db_conn.commit()
                zone_id = cursor.lastrowid
                self.logger.info(f"Zone created in DB: {zone_data['name']} (ID: {zone_id})")
                return zone_id
        except pymysql.Error as e:
            self.logger.error(f"Failed to create zone in DB: {e}")
            return None
    
    def _create_record_api(self, record_data: Dict) -> bool:
        """Create DNS record via API"""
        try:
            response = requests.post(
                f"{self.args.api_url}/api/dns_api.php?action=create",
                json=record_data,
                headers={'Authorization': f'Bearer {self.args.api_token}'},
                timeout=30
            )
            
            if response.status_code in (200, 201):
                self.logger.debug(f"Record created via API: {record_data['name']} {record_data['record_type']}")
                return True
            else:
                self.logger.error(f"API error creating record: {response.status_code} - {response.text}")
                return False
        except Exception as e:
            self.logger.error(f"Failed to create record via API: {e}")
            return False
    
    def _create_record_db(self, record_data: Dict) -> bool:
        """Create DNS record via direct DB insertion"""
        # Base columns
        base_columns = ['zone_file_id', 'record_type', 'name', 'value', 'ttl', 
                       'status', 'created_by']
        
        # Type-specific columns mapping
        type_columns = {
            'A': ['address_ipv4'],
            'AAAA': ['address_ipv6'],
            'CNAME': ['cname_target'],
            'MX': ['mx_target', 'priority'],
            'NS': ['ns_target'],
            'PTR': ['ptrdname'],
            'TXT': ['txt'],
            'SRV': ['srv_target', 'priority', 'weight', 'port'],
            'CAA': ['caa_flag', 'caa_tag', 'caa_value'],
            'SSHFP': ['sshfp_algo', 'sshfp_type', 'sshfp_fingerprint'],
            'TLSA': ['tlsa_usage', 'tlsa_selector', 'tlsa_matching', 'tlsa_data'],
            'NAPTR': ['naptr_order', 'naptr_pref', 'naptr_flags', 'naptr_service', 
                     'naptr_regexp', 'naptr_replacement'],
        }
        
        available_columns = []
        values = []
        
        # Add base columns
        for col in base_columns:
            if col in self.db_columns['dns_records']:
                available_columns.append(col)
                values.append(record_data.get(col))
        
        # Add type-specific columns
        record_type = record_data.get('record_type', '')
        if record_type in type_columns:
            for col in type_columns[record_type]:
                if col in self.db_columns['dns_records'] and col in record_data:
                    available_columns.append(col)
                    values.append(record_data[col])
        
        # Add timestamps
        if 'created_at' in self.db_columns['dns_records']:
            available_columns.append('created_at')
            values.append('NOW()')
        
        try:
            with self.db_conn.cursor() as cursor:
                placeholders = ', '.join(['%s' if v != 'NOW()' else 'NOW()' for v in values])
                actual_values = [v for v in values if v != 'NOW()']
                
                sql = f"INSERT INTO dns_records ({', '.join(available_columns)}) VALUES ({placeholders})"
                cursor.execute(sql, actual_values)
                self.db_conn.commit()
                return True
        except pymysql.Error as e:
            self.logger.error(f"Failed to create record in DB: {e}")
            return False
    
    def _compute_file_hash(self, filepath: Path) -> str:
        """Compute SHA256 hash of file content for deduplication"""
        try:
            with open(filepath, 'rb') as f:
                return hashlib.sha256(f.read()).hexdigest()
        except Exception as e:
            self.logger.warning(f"Failed to compute hash for {filepath}: {e}")
            return ""
    
    def _is_dnssec_key_file(self, filepath: str) -> Optional[str]:
        """
        Check if a file is a DNSSEC key include (*.ksk.key or *.zsk.key)
        Returns 'ksk' or 'zsk' if it matches, None otherwise
        """
        basename_lower = Path(filepath).name.lower()
        
        if basename_lower.endswith('.ksk.key'):
            return 'ksk'
        elif basename_lower.endswith('.zsk.key'):
            return 'zsk'
        else:
            return None
    
    def _find_include_directives(self, content: str, base_dir: Path) -> List[Tuple[str, str, int]]:
        """
        Find all $INCLUDE directives in zone file content
        Returns list of tuples: (include_path, origin, line_number)
        """
        includes = []
        lines = content.split('\n')
        current_origin = None
        
        for line_num, line in enumerate(lines, 1):
            # Track $ORIGIN changes
            origin_match = re.match(r'^\$ORIGIN\s+(\S+)', line)
            if origin_match:
                current_origin = origin_match.group(1)
                if not current_origin.endswith('.'):
                    current_origin += '.'
                continue
            
            # Find $INCLUDE directives
            include_match = re.match(r'^\$INCLUDE\s+(\S+)(?:\s+(\S+))?', line)
            if include_match:
                include_file = include_match.group(1)
                include_origin = include_match.group(2) if include_match.group(2) else current_origin
                
                # Remove quotes if present
                include_file = include_file.strip('"\'')
                
                includes.append((include_file, include_origin, line_num))
                self.logger.debug(f"Found $INCLUDE directive at line {line_num}: {include_file} origin={include_origin}")
        
        return includes
    
    def _extract_dnssec_includes(self, include_directives: List[Tuple[str, str, int]], base_dir: Path) -> Dict[str, Optional[str]]:
        """
        Extract DNSSEC key includes from list of include directives.
        Returns dict with 'ksk' and 'zsk' keys containing resolved paths or None.
        """
        dnssec_includes = {'ksk': None, 'zsk': None}
        
        for include_path, include_origin, line_num in include_directives:
            key_type = self._is_dnssec_key_file(include_path)
            
            if key_type:
                # This is a DNSSEC key file - try to resolve the path
                resolved_path = None
                
                # Attempt resolution via existing path resolution logic
                try:
                    result = self._resolve_include_path(include_path, base_dir)
                    if result:
                        resolved, _ = result  # Unpack tuple (path, strategy)
                        resolved_path = str(resolved)
                        self.logger.info(f"Detected DNSSEC {key_type.upper()} include at line {line_num}: {resolved_path}")
                    else:
                        # Could not resolve - keep original path and warn
                        resolved_path = include_path
                        self.logger.warning(f"Could not resolve DNSSEC {key_type.upper()} include '{include_path}' (keeping original path)")
                except Exception as e:
                    # Resolution failed - keep original path and warn
                    resolved_path = include_path
                    self.logger.warning(f"Could not resolve DNSSEC {key_type.upper()} include '{include_path}': {e} (keeping original path)")
                
                # Store the resolved (or original) path
                # Warn if multiple keys of the same type
                if dnssec_includes[key_type]:
                    self.logger.warning(f"Multiple {key_type.upper()} includes detected. Using last one: {resolved_path} (previous: {dnssec_includes[key_type]})")
                dnssec_includes[key_type] = resolved_path
        
        return dnssec_includes
    
    def _resolve_include_path(self, include_path: str, base_dir: Path) -> Optional[Tuple[Path, Optional[str]]]:
        """
        Resolve include path to absolute path using multiple strategies.
        
        Resolution order (for relative paths):
        1. Resolve relative to base_dir (directory of master zone file)
        2. Resolve relative to import_root (--dir argument)
        3. Resolve relative to current working directory (CWD)
        4. Try each path in --include-search-paths
        5. If include_path is a basename (no slash), do recursive search under import_root
        
        For absolute paths: respects --allow-abs-include security setting.
        
        Returns:
            Tuple of (Resolved Path object, resolution strategy string) if file found, None otherwise
            Strategy string examples: "base_dir", "import_root", "search_path:/var/named/includes"
        """
        include_file = Path(include_path)
        attempted_paths = []
        import_root = Path(self.args.dir).resolve() if self.args.dir else None
        
        # If absolute path
        if include_file.is_absolute():
            if not self.args.allow_abs_include:
                self.logger.error(f"Absolute include path not allowed: {include_path}")
                self.logger.error("Use --allow-abs-include to override this restriction")
                return None
            
            # For absolute paths with allow_abs_include, still check import_root security unless explicitly allowed
            resolved = include_file.resolve()
            if not self.args.allow_abs_include and import_root:
                try:
                    resolved.relative_to(import_root)
                except ValueError:
                    self.logger.error(f"Absolute include path outside import root: {include_path}")
                    return None
            
            if resolved.exists():
                self.logger.debug(f"Resolved absolute include path: {resolved}")
                return (resolved, "absolute")
            else:
                self.logger.error(f"Absolute include file not found: {resolved}")
                return None
        
        # Relative path - try multiple strategies in order
        candidates = []
        
        # Strategy 1: Resolve relative to base_dir (directory of current master/include file)
        candidate = (base_dir / include_file).resolve()
        candidates.append(("base_dir", candidate))
        
        # Strategy 2: Resolve relative to import_root (--dir argument)
        if import_root and import_root != base_dir.resolve():
            candidate = (import_root / include_file).resolve()
            candidates.append(("import_root", candidate))
        
        # Strategy 3: Resolve relative to current working directory
        cwd = Path.cwd()
        if cwd != base_dir.resolve() and (not import_root or cwd != import_root):
            candidate = (cwd / include_file).resolve()
            candidates.append(("cwd", candidate))
        
        # Strategy 4: Try each path in --include-search-paths
        if hasattr(self.args, 'include_search_paths') and self.args.include_search_paths:
            for search_path in self.args.include_search_paths:
                search_path_obj = Path(search_path).resolve()
                candidate = (search_path_obj / include_file).resolve()
                candidates.append((f"search_path:{search_path}", candidate))
        
        # Check each candidate, ensuring it's within import_root (unless allow_abs_include)
        for strategy, candidate in candidates:
            attempted_paths.append(f"{strategy} -> {candidate}")
            
            # Security check: ensure resolved path is within import_root
            if not self.args.allow_abs_include and import_root:
                try:
                    candidate.relative_to(import_root)
                except ValueError:
                    self.logger.debug(f"Path outside import_root (skipping): {candidate}")
                    continue
            
            # Check if file exists
            if candidate.exists() and candidate.is_file():
                self.logger.debug(f"Resolved include via {strategy}: {candidate}")
                return (candidate, strategy)
        
        # Strategy 5: If include_path is a basename (no directory separators), 
        # do recursive search under import_root
        if '/' not in include_path and '\\' not in include_path and import_root:
            self.logger.debug(f"Attempting recursive search for basename: {include_path}")
            try:
                # Use rglob to search recursively, limit results for safety
                matches = list(import_root.rglob(include_path))
                
                # Filter to only files (not directories)
                matches = [m for m in matches if m.is_file()]
                
                if matches:
                    if len(matches) > 1:
                        self.logger.warning(f"Multiple matches found for '{include_path}': {len(matches)} files")
                        self.logger.warning(f"Using first match: {matches[0]}")
                        for idx, match in enumerate(matches[:5], 1):
                            self.logger.debug(f"  Match {idx}: {match}")
                    
                    resolved = matches[0].resolve()
                    attempted_paths.append(f"recursive_search -> {resolved}")
                    self.logger.debug(f"Resolved include via recursive search: {resolved}")
                    return (resolved, "recursive_search")
                else:
                    attempted_paths.append(f"recursive_search under {import_root} -> no matches")
            except Exception as e:
                self.logger.debug(f"Recursive search failed: {e}")
                attempted_paths.append(f"recursive_search -> error: {e}")
        
        # No candidate found - log all attempted paths
        self.logger.error(f"Include file not found: {include_path}")
        if self.args.verbose:
            self.logger.error("Attempted paths:")
            for path in attempted_paths:
                self.logger.error(f"  - {path}")
        else:
            self.logger.error(f"Tried {len(attempted_paths)} location(s). Use --verbose to see all attempted paths.")
        
        return None
    
    def _compute_directory_to_store(self, resolved_path: Path, resolution_strategy: Optional[str] = None) -> str:
        """
        Compute the directory path to store in the database based on priority logic.
        
        Priority:
        1. If resolved path is under a search path used for resolution, store relative to that search path
        2. Else if under --dir (import root), store relative to --dir
        3. Else store absolute path
        
        Args:
            resolved_path: The resolved absolute path to the include file
            resolution_strategy: Optional strategy string from _resolve_include_path (e.g., "search_path:/var/named/includes")
        
        Returns:
            Directory path to store (either relative or absolute)
        """
        import_root = Path(self.args.dir).resolve() if self.args.dir else None
        resolved_dir = resolved_path.parent.resolve()
        
        # Priority 1: Check if resolved via a search path
        if resolution_strategy and resolution_strategy.startswith("search_path:"):
            # Extract the search path from the strategy string
            search_path_str = resolution_strategy.split(":", 1)[1]
            search_path = Path(search_path_str).resolve()
            
            try:
                relative_to_search = resolved_dir.relative_to(search_path)
                result = str(relative_to_search)
                self.logger.debug(f"Storing directory relative to search path {search_path}: {result}")
                return result if result != '.' else ''
            except ValueError:
                # Not under this search path, continue to next priority
                pass
        
        # Priority 2: Check if under import_root (--dir)
        if import_root:
            try:
                relative_to_import = resolved_dir.relative_to(import_root)
                result = str(relative_to_import)
                self.logger.debug(f"Storing directory relative to import root: {result}")
                return result if result != '.' else ''
            except ValueError:
                # Not under import_root, use absolute
                pass
        
        # Priority 3: Store absolute path
        result = str(resolved_dir)
        self.logger.debug(f"Storing absolute directory path: {result}")
        return result
    
    def _create_zone_file_include_relationship(self, parent_id: int, include_id: int, position: int) -> bool:
        """Create a relationship between parent zone and include zone"""
        if self.args.dry_run:
            self.logger.info(f"[DRY-RUN] Would create zone_file_includes relationship: parent={parent_id}, include={include_id}, position={position}")
            return True
        
        if self.args.db_mode:
            try:
                with self.db_conn.cursor() as cursor:
                    # Check if relationship already exists
                    cursor.execute(
                        "SELECT id FROM zone_file_includes WHERE parent_id = %s AND include_id = %s",
                        (parent_id, include_id)
                    )
                    if cursor.fetchone():
                        self.logger.debug(f"zone_file_includes relationship already exists")
                        return True
                    
                    cursor.execute(
                        "INSERT INTO zone_file_includes (parent_id, include_id, position) VALUES (%s, %s, %s)",
                        (parent_id, include_id, position)
                    )
                    self.db_conn.commit()
                    self.logger.debug(f"Created zone_file_includes relationship")
                    return True
            except pymysql.Error as e:
                self.logger.error(f"Failed to create zone_file_includes relationship: {e}")
                return False
        else:
            # API mode - use assign_include endpoint
            try:
                response = requests.post(
                    f"{self.args.api_url}/api/zone_api.php?action=assign_include",
                    json={'master_id': parent_id, 'include_id': include_id, 'position': position},
                    headers={'Authorization': f'Bearer {self.args.api_token}'},
                    timeout=30
                )
                
                if response.status_code in (200, 201):
                    self.logger.debug(f"Created zone_file_includes relationship via API")
                    return True
                else:
                    self.logger.error(f"API error creating relationship: {response.status_code} - {response.text}")
                    return False
            except Exception as e:
                self.logger.error(f"Failed to create relationship via API: {e}")
                return False
    
    def _process_include_file(self, include_path: Path, origin: Optional[str], base_dir: Path, parent_zone_name: str, master_ttl: Optional[int] = None, resolution_strategy: Optional[str] = None) -> Optional[int]:
        """
        Process an include file and create zone_file entry with dns_records
        Returns zone_id of the created/existing include, or None on error
        
        Args:
            include_path: Path to the include file
            origin: Optional origin for the include
            base_dir: Base directory for resolving relative paths
            parent_zone_name: Name of the parent zone
            master_ttl: Default TTL from the master zone (used if include has no $TTL)
            resolution_strategy: Optional resolution strategy string from _resolve_include_path
        """
        # Check include depth
        self.include_depth += 1
        if self.include_depth > self.max_include_depth:
            self.logger.error(f"Maximum include depth ({self.max_include_depth}) exceeded")
            self.include_depth -= 1
            return None
        
        # Check for cycles
        include_path_str = str(include_path.resolve())
        if include_path_str in self.visited_includes:
            self.logger.error(f"Circular include detected: {include_path}")
            self.include_depth -= 1
            return None
        
        self.visited_includes.add(include_path_str)
        
        try:
            # Check if already processed (deduplication)
            file_hash = self._compute_file_hash(include_path)
            if file_hash and file_hash in self.processed_includes:
                zone_id = self.processed_includes[file_hash]
                self.logger.info(f"Include already processed (dedup by hash): {include_path.name} (ID: {zone_id})")
                self.include_depth -= 1
                self.visited_includes.discard(include_path_str)
                return zone_id
            
            # Check by absolute path
            if include_path_str in self.processed_includes:
                zone_id = self.processed_includes[include_path_str]
                self.logger.info(f"Include already processed (dedup by path): {include_path.name} (ID: {zone_id})")
                self.include_depth -= 1
                self.visited_includes.discard(include_path_str)
                return zone_id
            
            # Read include file content
            with open(include_path, 'r', encoding='utf-8') as f:
                include_content = f.read()
            
            # Determine origin for include file
            # Check for $ORIGIN in include file first
            origin_match = re.search(r'^\$ORIGIN\s+(\S+)', include_content, re.MULTILINE)
            if origin_match:
                effective_origin = origin_match.group(1)
                if not effective_origin.endswith('.'):
                    effective_origin += '.'
            elif origin:
                # Use origin passed from $INCLUDE directive
                effective_origin = origin
            else:
                # Use parent zone's origin
                effective_origin = parent_zone_name if parent_zone_name.endswith('.') else parent_zone_name + '.'
            
            self.logger.info(f"Processing include file: {include_path.name} with origin: {effective_origin}")
            
            # Check for nested $INCLUDE directives in include file
            nested_includes = self._find_include_directives(include_content, include_path.parent)
            
            # Prepare content for parsing - filter out $INCLUDE directives
            # dnspython's zone.from_text() does not support $INCLUDE directives
            # Filter them out regardless of --create-includes flag to allow parsing to continue
            lines = include_content.split('\n')
            filtered_lines = []
            nested_include_count = 0
            
            for line in lines:
                # Check if line contains $INCLUDE directive (consistent with _find_include_directives)
                if re.match(r'^\$INCLUDE\s+\S+', line):
                    nested_include_count += 1
                    self.logger.debug(f"Filtering out nested $INCLUDE line: {line.strip()}")
                    continue
                filtered_lines.append(line)
            
            parse_text = '\n'.join(filtered_lines)
            
            # Log appropriate message if nested includes were found
            if nested_include_count > 0:
                if self.args.create_includes:
                    self.logger.debug(f"Filtered {nested_include_count} nested $INCLUDE directive(s) from {include_path.name}")
                else:
                    self.logger.warning(f"Ignoring {nested_include_count} nested $INCLUDE directive(s) in {include_path.name}")
            
            # Safety check: verify no $INCLUDE directives remain (using regex for accuracy)
            if re.search(r'^\$INCLUDE\s+\S+', parse_text, re.MULTILINE):
                self.logger.error(f"$INCLUDE directive(s) still present after filtering in {include_path.name}")
            
            # Check if include file has its own $TTL directive
            # BIND supports time unit suffixes: s, m, h, d, w (e.g., $TTL 1h, $TTL 30m)
            # Also supports decimal values: $TTL 1.5h, $TTL 0.5d
            has_ttl = re.search(r'^\$TTL\s+\d+(?:\.\d+)?[smhdw]?', parse_text, re.MULTILINE) is not None
            
            # If no $TTL in include, prefix with master's TTL (or fallback)
            if not has_ttl:
                ttl_to_use = master_ttl if master_ttl else 86400
                if not master_ttl:
                    self.logger.warning(f"Include {include_path.name} has no $TTL and master has no default TTL. Using fallback: {ttl_to_use}")
                else:
                    self.logger.debug(f"Include {include_path.name} has no $TTL directive. Using master's default TTL: {ttl_to_use}")
                
                # Prefix the content with $TTL directive
                parse_text = f"$TTL {ttl_to_use}\n{parse_text}"
            
            # Detect explicit TTLs before parsing (use original include_content, not parse_text)
            explicit_ttls = self._detect_explicit_ttls(include_content, effective_origin)
            self.logger.debug(f"Detected {len(explicit_ttls)} record(s) with explicit TTL in include {include_path.name}")
            
            # Detect FQDN owners in the include file
            fqdn_owners = self._detect_fqdn_owners(include_content)
            self.logger.debug(f"Detected {len(fqdn_owners)} FQDN owner(s) in include {include_path.name}")
            
            # Extract raw RDATA to preserve @ symbols
            raw_rdata_list = self._extract_raw_rdata(include_content, effective_origin)
            self.logger.debug(f"Extracted {len(raw_rdata_list)} raw RDATA value(s) from include {include_path.name}")
            
            # Detect @ owners in the include file
            at_owners = self._detect_at_owners(include_content, effective_origin)
            self.logger.debug(f"Detected {len(at_owners)} @ owner(s) in include {include_path.name}")
            
            # Parse the include file using dnspython
            # Use relativize=True to preserve relative names as-is from the zone file
            try:
                zone = dns.zone.from_text(parse_text, origin=effective_origin, check_origin=False, relativize=True)
            except Exception as e:
                self.logger.error(f"Failed to parse include file {include_path}: {e}")
                self.logger.error(f"  Origin: {effective_origin}")
                self.include_depth -= 1
                self.visited_includes.discard(include_path_str)
                return None
            
            # Extract default TTL
            default_ttl = 86400
            if hasattr(zone, 'default_ttl') and zone.default_ttl:
                default_ttl = zone.default_ttl
            elif hasattr(zone, 'ttl') and zone.ttl:
                default_ttl = zone.ttl
            
            # Prepare zone data for include (content NOT stored - records will be in dns_records)
            # Use filename stem (without extension) as name to avoid conflicts with master zone
            include_zone_name = effective_origin.rstrip('.')
            include_file_stem = include_path.stem  # e.g., "logiciel1" from "logiciel1.db"
            
            # Compute directory to store based on resolution strategy
            directory_to_store = self._compute_directory_to_store(include_path, resolution_strategy)
            
            zone_data = {
                'name': include_file_stem,
                'filename': include_path.name,
                'file_type': 'include',
                'status': 'active',
                'created_by': self.args.user_id,
                'domain': include_zone_name,
                'default_ttl': default_ttl,
                # 'content': NOT stored - records extracted to dns_records table
                'directory': directory_to_store
            }
            
            # Check if include zone already exists
            if self.args.skip_existing:
                # Check by filename and directory (using the computed directory)
                if self.args.db_mode:
                    with self.db_conn.cursor() as cursor:
                        cursor.execute(
                            "SELECT id FROM zone_files WHERE filename = %s AND file_type = 'include' AND directory = %s",
                            (include_path.name, directory_to_store)
                        )
                        existing = cursor.fetchone()
                        if existing:
                            zone_id = existing['id']
                            self.logger.info(f"Include zone already exists, reusing: {include_zone_name} (ID: {zone_id})")
                            self.processed_includes[include_path_str] = zone_id
                            if file_hash:
                                self.processed_includes[file_hash] = zone_id
                            self.stats['skipped'] += 1
                            self.include_depth -= 1
                            self.visited_includes.discard(include_path_str)
                            return zone_id
            
            # Create zone_file entry for include
            if self.args.dry_run:
                self.logger.info(f"[DRY-RUN] Would create include zone: {include_zone_name}")
                zone_id = -1  # Use -1 for dry-run to distinguish from failure (None)
            elif self.args.db_mode:
                zone_id = self._create_zone_db(zone_data)
            else:
                zone_id = self._create_zone_api(zone_data)
            
            if not zone_id and not self.args.dry_run:
                self.logger.error(f"Failed to create include zone: {include_path.name}")
                self.include_depth -= 1
                self.visited_includes.discard(include_path_str)
                return None
            
            # Store in processed includes for deduplication
            self.processed_includes[include_path_str] = zone_id
            if file_hash:
                self.processed_includes[file_hash] = zone_id
            
            self.stats['includes_created'] += 1
            
            # Process nested includes first (if any)
            nested_include_ids = []
            for nested_include_path, nested_origin, _ in nested_includes:
                if self.args.create_includes:
                    result = self._resolve_include_path(nested_include_path, include_path.parent)
                    if result:
                        resolved_nested, nested_strategy = result
                        nested_id = self._process_include_file(resolved_nested, nested_origin, include_path.parent, include_zone_name, master_ttl, nested_strategy)
                        if nested_id:
                            nested_include_ids.append(nested_id)
                            # Create relationship for nested include
                            self._create_zone_file_include_relationship(zone_id, nested_id, len(nested_include_ids))
            
            # Extract and create DNS records from include
            records = self._extract_records(zone, effective_origin, zone_id, explicit_ttls, fqdn_owners, raw_rdata_list, at_owners)
            
            # Extract out-of-origin records from raw include content
            out_of_origin_records = self._extract_out_of_origin_records(
                include_content, effective_origin, zone_id, explicit_ttls, default_ttl
            )
            
            if out_of_origin_records:
                self.logger.info(f"Found {len(out_of_origin_records)} out-of-origin record(s) in include")
                records.extend(out_of_origin_records)
            
            self.logger.info(f"Creating {len(records)} records for include {include_path.name}")
            
            for record in records:
                if self.args.dry_run:
                    self.logger.debug(f"[DRY-RUN] Would create record: {record['name']} {record['record_type']}")
                elif self.args.db_mode:
                    if self._create_record_db(record):
                        self.stats['records_created'] += 1
                else:
                    if self._create_record_api(record):
                        self.stats['records_created'] += 1
            
            self.include_depth -= 1
            self.visited_includes.discard(include_path_str)
            return zone_id
            
        except Exception as e:
            self.logger.error(f"Error processing include file {include_path}: {e}")
            self.include_depth -= 1
            self.visited_includes.discard(include_path_str)
            return None
    
    def _parse_zone_file(self, filepath: Path) -> Optional[Tuple[dns.zone.Zone, str]]:
        """
        Parse a BIND zone file using dnspython
        
        When --create-includes is enabled, $INCLUDE directives are stripped from the
        content before parsing, as dnspython does not support them in zone.from_text.
        The include files are processed separately via _process_include_file.
        """
        try:
            # Try to extract origin from filename or file content
            zone_name = filepath.stem
            
            # Read file content to check for $ORIGIN
            self.logger.debug(f"Reading zone file: {filepath.name}")
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Look for $ORIGIN directive
            origin_match = re.search(r'^\$ORIGIN\s+(\S+)', content, re.MULTILINE)
            if origin_match:
                origin = origin_match.group(1)
                if not origin.endswith('.'):
                    origin += '.'
                self.logger.debug(f"Found $ORIGIN directive: {origin}")
            else:
                # Use filename as origin
                origin = zone_name if zone_name.endswith('.') else zone_name + '.'
                self.logger.debug(f"No $ORIGIN found, using filename as origin: {origin}")
            
            # Prepare content for parsing
            # dnspython's zone.from_text() does not support $INCLUDE directives
            # Filter them out regardless of --create-includes flag to allow parsing to continue
            lines = content.split('\n')
            filtered_lines = []
            include_count = 0
            
            for line in lines:
                # Check if line contains $INCLUDE directive (consistent with _find_include_directives)
                if re.match(r'^\$INCLUDE\s+\S+', line):
                    include_count += 1
                    self.logger.debug(f"Filtering out $INCLUDE line: {line.strip()}")
                    continue
                filtered_lines.append(line)
            
            parse_text = '\n'.join(filtered_lines)
            
            # Log appropriate message based on whether includes are being created
            if include_count > 0:
                if self.args.create_includes:
                    self.logger.info(f"Filtered {include_count} $INCLUDE directive(s) before parsing {filepath.name}")
                else:
                    self.logger.warning(f"Ignoring {include_count} $INCLUDE directive(s) in {filepath.name} (use --create-includes to process them)")
                    self.logger.warning(f"  Parsing will continue with records after $INCLUDE directives")
            
            # Safety check: verify no $INCLUDE directives remain (using regex for accuracy)
            if re.search(r'^\$INCLUDE\s+\S+', parse_text, re.MULTILINE):
                self.logger.error(f"$INCLUDE directive(s) still present after filtering in {filepath.name}")
                self.logger.error("This should not happen - parsing may fail")
            
            # Parse the zone
            # Use relativize=True to preserve relative names as-is from the zone file
            self.logger.debug(f"Calling dns.zone.from_text for {filepath.name} with origin={origin}, create_includes={self.args.create_includes}")
            zone = dns.zone.from_text(parse_text, origin=origin, relativize=True, check_origin=False)
            
            self.logger.info(f"Successfully parsed zone file: {filepath.name} with origin: {origin}")
            return zone, origin
            
        except dns.exception.DNSException as e:
            self.logger.error(f"DNS parsing error in {filepath.name}: {e}")
            self.logger.error(f"  Origin: {origin if 'origin' in locals() else 'unknown'}")
            self.logger.error(f"  create_includes: {self.args.create_includes}")
            return None
        except Exception as e:
            self.logger.error(f"Failed to parse zone file {filepath.name}: {e}")
            self.logger.error(f"  create_includes: {self.args.create_includes}")
            return None
    
    def _detect_explicit_ttls(self, content: str, origin: str) -> Set[Tuple[str, str, str]]:
        """
        Detect which records have explicit TTL in raw zone file content.
        Returns a set of (name, record_type, rdata_key) tuples for records with explicit TTL.
        
        This is needed because dnspython always returns a TTL for every record (either explicit
        or inherited from $TTL), but we need to store NULL in the ttl column for records that
        inherit the default TTL.
        """
        explicit_ttls = set()
        lines = content.split('\n')
        current_origin = origin if origin.endswith('.') else origin + '.'
        
        # TTL can be specified:
        # 1. As a directive: $TTL 3600
        # 2. Per record: name TTL class type rdata
        # 3. Per record with class omitted: name TTL type rdata
        
        # Pattern to match RR lines with explicit TTL
        # Format: name [ttl] [class] type rdata
        # TTL is numeric (possibly with time suffix: s,m,h,d,w)
        # If there's a number after the name and before the type, it's likely a TTL
        
        for line in lines:
            # Skip empty lines, comments, directives
            line = line.strip()
            if not line or line.startswith(';') or line.startswith('$'):
                continue
            
            # Skip multi-line records (continuation lines start with whitespace in original)
            # For simplicity, we'll just mark SOA records as having explicit TTL structure
            if 'SOA' in line.upper():
                continue  # SOA handled separately
            
            # Split the line into parts
            parts = line.split()
            if len(parts) < 3:
                continue
            
            # Try to parse: name [ttl] [class] type rdata
            name = parts[0]
            remaining = parts[1:]
            
            # Check if first field after name is a TTL (number with optional suffix)
            has_explicit_ttl = False
            record_type = None
            rdata_start_idx = None
            
            for idx, part in enumerate(remaining):
                # Check if this looks like a TTL (number with optional time unit)
                if re.match(r'^\d+(?:\.\d+)?[smhdw]?$', part, re.IGNORECASE):
                    # This could be a TTL
                    # Next should be class (IN, CH, HS) or record type
                    if idx + 1 < len(remaining):
                        next_part = remaining[idx + 1].upper()
                        # If next is a class, TTL is explicit
                        if next_part in ('IN', 'CH', 'HS', 'NONE', 'ANY'):
                            has_explicit_ttl = True
                            if idx + 2 < len(remaining):
                                record_type = remaining[idx + 2].upper()
                                rdata_start_idx = idx + 3
                        # If next is a record type, TTL is explicit
                        elif next_part in self.COMMON_RECORD_TYPES:
                            has_explicit_ttl = True
                            record_type = next_part
                            rdata_start_idx = idx + 2
                    break
                # Check if this is a class (without TTL before it)
                elif part.upper() in ('IN', 'CH', 'HS', 'NONE', 'ANY'):
                    # No TTL found, class is here
                    if idx + 1 < len(remaining):
                        record_type = remaining[idx + 1].upper()
                        rdata_start_idx = idx + 2
                    break
                # Check if this is a record type (no TTL, no class)
                elif part.upper() in self.COMMON_RECORD_TYPES:
                    record_type = part.upper()
                    rdata_start_idx = idx + 1
                    break
            
            if has_explicit_ttl and record_type and rdata_start_idx is not None:
                # Normalize name
                if name == '@':
                    normalized_name = current_origin.rstrip('.')
                elif not name.endswith('.'):
                    normalized_name = f"{name}.{current_origin}".rstrip('.')
                else:
                    normalized_name = name.rstrip('.')
                
                # Build rdata key (simplified - just join remaining parts)
                rdata_parts = remaining[rdata_start_idx:]
                rdata_key = ' '.join(rdata_parts) if rdata_parts else ''
                
                # Add to set
                explicit_ttls.add((normalized_name, record_type, rdata_key))
                self.logger.debug(f"Detected explicit TTL: {normalized_name} {record_type} {rdata_key}")
        
        return explicit_ttls
    
    def _detect_fqdn_owners(self, content: str) -> Set[str]:
        """
        Detect which record owners are written as FQDN (with trailing dot) in raw zone file.
        Returns a set of FQDN strings as they appear in the file (with trailing dot).
        
        This is needed to preserve the original format from the zone file - if an owner
        was written as FQDN, we store it with the trailing dot.
        """
        fqdn_owners = set()
        lines = content.split('\n')
        
        for line in lines:
            # Skip empty lines, comments, directives
            stripped_line = line.strip()
            if not stripped_line or stripped_line.startswith(';') or stripped_line.startswith('$'):
                continue
            
            # Split the line into parts
            parts = stripped_line.split()
            if len(parts) < 3:
                continue
            
            # First part should be the owner name
            owner = parts[0]
            
            # Check if owner ends with dot (FQDN)
            if owner.endswith('.') and owner != '@':
                # Store the FQDN (lowercase for comparison)
                fqdn_owners.add(owner.lower())
                self.logger.debug(f"Detected FQDN owner: {owner}")
        
        return fqdn_owners
    
    def _detect_at_owners(self, content: str, origin: str) -> Dict[Tuple[str, str], str]:
        """
        Detect which records use @ as owner in raw zone file.
        Returns a dict mapping (normalized_name, record_type) to the raw owner string '@'.
        
        This is needed to preserve @ as the owner name instead of resolving it to the origin FQDN.
        We map by normalized_name and record_type to match dnspython's parsed records back to raw '@'.
        """
        at_owners = {}
        lines = content.split('\n')
        current_origin = origin if origin.endswith('.') else origin + '.'
        
        for line in lines:
            # Skip empty lines, comments, directives
            stripped_line = line.strip()
            if not stripped_line or stripped_line.startswith(';') or stripped_line.startswith('$'):
                continue
            
            # Skip SOA records (handled separately)
            if 'SOA' in stripped_line.upper():
                continue
            
            # Split the line into parts
            parts = stripped_line.split()
            if len(parts) < 3:
                continue
            
            # First part should be the owner name
            owner = parts[0]
            
            # Check if owner is @
            if owner == '@':
                # Parse the rest to find record type
                remaining = parts[1:]
                record_type = None
                
                for idx, part in enumerate(remaining):
                    part_upper = part.upper()
                    
                    # Check if this looks like a TTL (number with optional time unit)
                    if re.match(r'^\d+(?:\.\d+)?[smhdw]?$', part, re.IGNORECASE):
                        # This could be a TTL, check what follows
                        if idx + 1 < len(remaining):
                            next_part = remaining[idx + 1].upper()
                            # If next is a class
                            if next_part in ('IN', 'CH', 'HS', 'NONE', 'ANY'):
                                if idx + 2 < len(remaining):
                                    record_type = remaining[idx + 2].upper()
                            # If next is a record type
                            elif next_part in self.COMMON_RECORD_TYPES:
                                record_type = next_part
                        break
                    # Check if this is a class (without TTL before it)
                    elif part_upper in ('IN', 'CH', 'HS', 'NONE', 'ANY'):
                        # No TTL found, class is here
                        if idx + 1 < len(remaining):
                            record_type = remaining[idx + 1].upper()
                        break
                    # Check if this is a record type (no TTL, no class)
                    elif part_upper in self.COMMON_RECORD_TYPES:
                        record_type = part_upper
                        break
                
                if record_type:
                    # Normalize the name as dnspython would (@ becomes origin)
                    normalized_name = current_origin.rstrip('.').lower()
                    
                    # Store mapping from (normalized_name, record_type) to '@'
                    # Multiple @ records of same type share one key; each rdata is processed separately later
                    key = (normalized_name, record_type)
                    at_owners[key] = '@'
                    self.logger.debug(f"Detected @ owner for {record_type} record")
        
        return at_owners
    
    def _extract_raw_rdata(self, content: str, origin: str) -> List[Tuple[str, str, str]]:
        """
        Extract raw RDATA values from zone file content.
        Returns a list of tuples (normalized_name, record_type, raw_rdata_string).
        
        This captures the RDATA exactly as written in the zone file, including @ symbols,
        which dnspython would otherwise resolve to FQDN.
        
        Args:
            content: Raw zone file content
            origin: Zone origin (with trailing dot)
            
        Returns:
            List of tuples (normalized_name, record_type, raw_rdata_string)
        """
        raw_rdata_list = []
        lines = content.split('\n')
        current_origin = origin if origin.endswith('.') else origin + '.'
        
        # Parse each line to extract raw RDATA
        for line in lines:
            # Skip empty lines, comments, directives
            line_stripped = line.strip()
            if not line_stripped or line_stripped.startswith(';') or line_stripped.startswith('$'):
                continue
            
            # Skip SOA records (handled separately and complex multi-line format)
            if 'SOA' in line_stripped.upper():
                continue
            
            # Split the line into parts
            parts = line_stripped.split()
            if len(parts) < 3:
                continue
            
            # Parse: name [ttl] [class] type rdata
            name = parts[0]
            remaining = parts[1:]
            
            # Find the record type and RDATA start position
            record_type = None
            rdata_start_idx = None
            
            for idx, part in enumerate(remaining):
                part_upper = part.upper()
                
                # Check if this looks like a TTL (number with optional time unit)
                if re.match(r'^\d+(?:\.\d+)?[smhdw]?$', part, re.IGNORECASE):
                    # This could be a TTL, check what follows
                    if idx + 1 < len(remaining):
                        next_part = remaining[idx + 1].upper()
                        # If next is a class
                        if next_part in ('IN', 'CH', 'HS', 'NONE', 'ANY'):
                            if idx + 2 < len(remaining):
                                record_type = remaining[idx + 2].upper()
                                rdata_start_idx = idx + 3
                        # If next is a record type
                        elif next_part in self.COMMON_RECORD_TYPES:
                            record_type = next_part
                            rdata_start_idx = idx + 2
                    break
                # Check if this is a class (without TTL before it)
                elif part_upper in ('IN', 'CH', 'HS', 'NONE', 'ANY'):
                    # No TTL found, class is here
                    if idx + 1 < len(remaining):
                        record_type = remaining[idx + 1].upper()
                        rdata_start_idx = idx + 2
                    break
                # Check if this is a record type (no TTL, no class)
                elif part_upper in self.COMMON_RECORD_TYPES:
                    record_type = part_upper
                    rdata_start_idx = idx + 1
                    break
            
            if record_type and rdata_start_idx is not None and rdata_start_idx < len(remaining):
                # Keep @ as-is for owner, normalize others to match dnspython processing
                # This preserves the distinction between @ and the origin FQDN
                if name == '@':
                    owner_key = '@'
                elif not name.endswith('.'):
                    # Relative name
                    owner_key = f"{name}.{current_origin}".rstrip('.').lower()
                else:
                    # Absolute name
                    owner_key = name.rstrip('.').lower()
                
                # Extract raw RDATA (everything after the record type)
                rdata_parts = remaining[rdata_start_idx:]
                raw_rdata = ' '.join(rdata_parts) if rdata_parts else ''
                
                # Add to list - we keep all records even if they have the same name+type
                # This allows us to match them to dnspython records by comparing RDATA values
                # Using @ as key preserves the original owner format for lookup
                raw_rdata_list.append((owner_key, record_type, raw_rdata))
                self.logger.debug(f"Extracted raw RDATA: {owner_key} {record_type} -> {raw_rdata}")
        
        return raw_rdata_list
    
    def _extract_out_of_origin_records(self, content: str, origin: str, zone_id: int, 
                                       explicit_ttls: Optional[Set[Tuple[str, str, str]]] = None,
                                       default_ttl: int = 3600) -> List[Dict]:
        """
        Extract records with FQDN owners that are outside the zone origin.
        
        dnspython's parser with relativize=True ignores records whose FQDN is not a
        subdomain of the origin. This function parses the raw zone file content to
        capture those records.
        
        Args:
            content: Raw zone file content
            origin: Zone origin (with trailing dot)
            zone_id: Zone file ID for association
            explicit_ttls: Set of records with explicit TTL
            default_ttl: Default TTL to use if not explicit
            
        Returns:
            List of record dictionaries for out-of-origin records
        """
        records = []
        lines = content.split('\n')
        
        # Normalize origin for comparison (lowercase, no trailing dot)
        origin_normalized = origin.rstrip('.').lower()
        
        # Common record types we support (only those with parsing logic below)
        supported_types = {
            'A', 'AAAA', 'CNAME', 'MX', 'NS', 'PTR', 'TXT', 'SRV', 'CAA'
        }
        
        for line_num, line in enumerate(lines, 1):
            # Skip empty lines, comments, directives
            stripped_line = line.strip()
            if not stripped_line or stripped_line.startswith(';') or stripped_line.startswith('$'):
                continue
            
            # Skip multi-line continuations (SOA, etc.)
            if stripped_line.startswith('(') or stripped_line.startswith(')'):
                continue
            
            # Parse line: owner [ttl] [class] type rdata
            parts = stripped_line.split()
            if len(parts) < 3:
                continue
            
            owner = parts[0]
            
            # Check if owner is a FQDN (ends with dot) and not @ or relative
            if not owner.endswith('.') or owner == '@':
                continue
            
            # Normalize owner for comparison (lowercase, no trailing dot)
            owner_normalized = owner.rstrip('.').lower()
            
            # Check if this FQDN is outside the origin
            # A name is within origin if it equals origin or ends with .origin
            is_in_origin = (
                owner_normalized == origin_normalized or
                owner_normalized.endswith('.' + origin_normalized)
            )
            
            if is_in_origin:
                # This record is within the origin, dnspython will handle it
                continue
            
            # This is an out-of-origin record - parse it
            self.logger.debug(f"Found out-of-origin record at line {line_num}: {owner}")
            
            # Parse remaining fields: [ttl] [class] type rdata
            remaining = parts[1:]
            parsed_ttl = None
            record_class = 'IN'
            record_type = None
            rdata_parts = []
            idx = 0
            
            # Try to parse TTL (numeric with optional time unit)
            if idx < len(remaining) and re.match(r'^\d+(?:\.\d+)?[smhdw]?$', remaining[idx], re.IGNORECASE):
                ttl_str = remaining[idx]
                # Convert time units to seconds
                multipliers = {'s': 1, 'm': 60, 'h': 3600, 'd': 86400, 'w': 604800}
                match = re.match(r'^(\d+)([smhdw]?)$', ttl_str, re.IGNORECASE)
                if match:
                    parsed_ttl = int(match.group(1))
                    if match.group(2):
                        parsed_ttl *= multipliers.get(match.group(2).lower(), 1)
                idx += 1
            
            # Try to parse class
            if idx < len(remaining) and remaining[idx].upper() in ('IN', 'CH', 'HS', 'NONE', 'ANY'):
                record_class = remaining[idx].upper()
                idx += 1
            
            # Parse record type
            if idx < len(remaining):
                record_type = remaining[idx].upper()
                idx += 1
            else:
                self.logger.warning(f"Could not parse record type at line {line_num}: {stripped_line}")
                continue
            
            # Check if we support this record type
            if record_type not in supported_types:
                self.logger.debug(f"Skipping unsupported record type {record_type} at line {line_num}")
                continue
            
            # Remaining parts are rdata
            rdata_parts = remaining[idx:]
            if not rdata_parts:
                self.logger.warning(f"No rdata found at line {line_num}: {stripped_line}")
                continue
            
            # Join rdata parts (may need quotes for TXT records, etc.)
            rdata_str = ' '.join(rdata_parts)
            
            # Determine TTL to use: we parse TTL directly from the raw line,
            # so we don't need to check explicit_ttls (which is for dnspython-parsed records)
            has_explicit_ttl = parsed_ttl is not None
            final_ttl = parsed_ttl if has_explicit_ttl else default_ttl
            
            # Build base record
            record_data = {
                'zone_file_id': zone_id,
                'record_type': record_type,
                'name': owner,  # Preserve FQDN with trailing dot
                'status': 'active',
                'created_by': self.args.user_id,
                'value': rdata_str
            }
            
            # Set TTL only if explicit
            if has_explicit_ttl:
                record_data['ttl'] = final_ttl
            
            # Parse type-specific fields
            try:
                if record_type == 'A':
                    # Simple IPv4 address
                    record_data['address_ipv4'] = rdata_parts[0]
                elif record_type == 'AAAA':
                    # Simple IPv6 address
                    record_data['address_ipv6'] = rdata_parts[0]
                elif record_type == 'CNAME':
                    # CNAME target
                    record_data['cname_target'] = rdata_parts[0]
                elif record_type == 'MX':
                    # Priority + target
                    if len(rdata_parts) >= 2:
                        record_data['priority'] = int(rdata_parts[0])
                        record_data['mx_target'] = rdata_parts[1]
                elif record_type == 'NS':
                    # NS target
                    record_data['ns_target'] = rdata_parts[0]
                elif record_type == 'PTR':
                    # PTR target
                    record_data['ptrdname'] = rdata_parts[0]
                elif record_type == 'TXT':
                    # TXT can have quoted strings
                    # Join all parts and remove quotes if present
                    txt_value = ' '.join(rdata_parts)
                    if txt_value.startswith('"') and txt_value.endswith('"'):
                        txt_value = txt_value[1:-1]
                    record_data['txt'] = txt_value
                elif record_type == 'SRV':
                    # Priority Weight Port Target
                    if len(rdata_parts) >= 4:
                        record_data['priority'] = int(rdata_parts[0])
                        record_data['weight'] = int(rdata_parts[1])
                        record_data['port'] = int(rdata_parts[2])
                        record_data['srv_target'] = rdata_parts[3]
                elif record_type == 'CAA':
                    # Flags Tag Value
                    if len(rdata_parts) >= 3:
                        record_data['caa_flag'] = int(rdata_parts[0])
                        record_data['caa_tag'] = rdata_parts[1]
                        record_data['caa_value'] = ' '.join(rdata_parts[2:])
                
                records.append(record_data)
                self.logger.info(f"Extracted out-of-origin record: {owner} {record_type} {rdata_str}")
                
            except (ValueError, IndexError) as e:
                self.logger.warning(f"Failed to parse {record_type} record at line {line_num}: {e}")
                continue
        
        return records
    
    def _extract_soa_data(self, zone: dns.zone.Zone, origin: str) -> Dict:
        """Extract SOA record data from zone"""
        soa_data = {
            'mname': None,
            'soa_rname': None,
            'soa_serial': None,
            'soa_refresh': 10800,
            'soa_retry': 900,
            'soa_expire': 604800,
            'soa_minimum': 3600,
        }
        
        try:
            # Get SOA record
            soa_rdataset = zone.get_rdataset(dns.name.from_text('@', origin=dns.name.from_text(origin)), 
                                            dns.rdatatype.SOA)
            if soa_rdataset:
                soa = list(soa_rdataset)[0]
                soa_data['mname'] = str(soa.mname)
                soa_data['soa_rname'] = str(soa.rname)
                soa_data['soa_serial'] = soa.serial
                soa_data['soa_refresh'] = soa.refresh
                soa_data['soa_retry'] = soa.retry
                soa_data['soa_expire'] = soa.expire
                soa_data['soa_minimum'] = soa.minimum
        except Exception as e:
            self.logger.warning(f"Could not extract SOA data: {e}")
        
        return soa_data
    
    def _rdata_targets_match(self, raw_target: str, dns_target: str, origin: str, 
                            normalized_name_lower: str) -> bool:
        """
        Check if a raw RDATA target matches a dnspython RDATA target.
        
        Handles cases where:
        - Direct match (including @ symbols which dnspython preserves)
        - Raw is FQDN within origin and dns is relative
        - Raw is @ and dns resolved it to record name (edge case, rarely happens)
        
        Args:
            raw_target: Target from raw zone file (normalized, no trailing dot)
            dns_target: Target from dnspython (normalized, no trailing dot)
            origin: Zone origin (with trailing dot)
            normalized_name_lower: Lowercase normalized record owner name (used for edge case
                                 where @ might resolve to the record's own name)
            
        Returns:
            True if targets match, False otherwise
        """
        # Direct match (most common case, includes @ which dnspython preserves)
        if raw_target == dns_target:
            return True
        
        # Edge case: Handle @ symbol resolution to record name
        # (In practice, dnspython preserves @ as-is, but this handles any edge cases)
        if raw_target == '@' and dns_target == normalized_name_lower:
            return True
        
        # If raw_target looks like it could be within origin, try FQDN comparison
        origin_normalized = origin.rstrip('.').lower()
        if raw_target.endswith('.' + origin_normalized):
            # Raw is FQDN within origin, dns might be relative
            if not dns_target.endswith('.' + origin_normalized):
                dns_target_fqdn = f"{dns_target}.{origin_normalized}"
                if raw_target == dns_target_fqdn:
                    return True
        
        return False
    
    def _extract_records(self, zone: dns.zone.Zone, origin: str, zone_id: int, 
                        explicit_ttls: Optional[Set[Tuple[str, str, str]]] = None,
                        fqdn_owners: Optional[Set[str]] = None,
                        raw_rdata_list: Optional[List[Tuple[str, str, str]]] = None,
                        at_owners: Optional[Dict[Tuple[str, str], str]] = None) -> List[Dict]:
        """Extract DNS records from zone
        
        Args:
            zone: Parsed DNS zone from dnspython
            origin: Zone origin
            zone_id: Zone file ID in database
            explicit_ttls: Set of records with explicit TTL
            fqdn_owners: Set of owner names that were FQDN in original file (lowercase, with trailing dot)
            raw_rdata_list: List of tuples (normalized_name, record_type, raw_rdata_string) from zone file
            at_owners: Dict mapping (normalized_name, record_type) to '@' for records with @ owner
        """
        records = []
        origin_name = dns.name.from_text(origin)
        
        for name, node in zone.items():
            # Derelativize the name to get the full FQDN
            fqdn = name.derelativize(origin_name)
            fqdn_str = fqdn.to_text()
            
            # Check if this name was originally written as FQDN in the file
            # Compare lowercase versions
            fqdn_lower = fqdn_str.lower()
            was_fqdn_in_file = fqdn_owners is not None and fqdn_lower in fqdn_owners
            
            for rdataset in node:
                record_type = dns.rdatatype.to_text(rdataset.rdtype)
                ttl = rdataset.ttl
                
                # Skip SOA records as they're part of zone metadata
                if record_type == 'SOA':
                    continue
                
                # Normalize name for matching
                normalized_name_lower = fqdn_str.rstrip('.').lower()
                at_key = (normalized_name_lower, record_type)
                was_at_in_file = at_owners is not None and at_key in at_owners
                
                for rdata in rdataset:
                    # Get raw RDATA if available by matching with dnspython's RDATA
                    # We try multiple lookup keys to find the right match
                    raw_rdata = None
                    raw_owner_key = None
                    if raw_rdata_list:
                        # Get dnspython's RDATA string (may have resolved @ to FQDN)
                        dnspython_rdata_str = str(rdata).lower().strip()
                        
                        # Build set of possible lookup keys for O(1) lookups
                        # Priority: @ (if was @ in file), normalized name, FQDN
                        lookup_keys = {normalized_name_lower}
                        if was_at_in_file:
                            lookup_keys.add('@')
                        if was_fqdn_in_file:
                            lookup_keys.add(fqdn_str.rstrip('.').lower())
                        
                        # Look for matching raw RDATA entry
                        # Match by name and type, then check if RDATA is compatible
                        for raw_name, raw_type, raw_rdata_str in raw_rdata_list:
                            if raw_name in lookup_keys and raw_type == record_type:
                                # Normalize raw RDATA for comparison
                                raw_rdata_normalized = raw_rdata_str.lower().strip()
                                
                                # Check if they match or if raw has @ which dnspython resolved
                                # For MX: compare without priority
                                # For SRV: compare without priority, weight, port
                                # For others: direct comparison
                                if record_type == 'MX':
                                    # Extract target from raw (format: "priority target")
                                    raw_parts = raw_rdata_normalized.split(None, 1)
                                    dns_parts = dnspython_rdata_str.split(None, 1)
                                    if len(raw_parts) == 2 and len(dns_parts) == 2:
                                        raw_target = raw_parts[1].rstrip('.')
                                        dns_target = dns_parts[1].rstrip('.')
                                        if self._rdata_targets_match(raw_target, dns_target, origin, normalized_name_lower):
                                            raw_rdata = raw_rdata_str
                                            raw_owner_key = raw_name
                                            break
                                elif record_type == 'SRV':
                                    # Extract target from raw (format: "priority weight port target")
                                    raw_parts = raw_rdata_normalized.split(None, 3)
                                    dns_parts = dnspython_rdata_str.split(None, 3)
                                    if len(raw_parts) == 4 and len(dns_parts) == 4:
                                        raw_target = raw_parts[3].rstrip('.')
                                        dns_target = dns_parts[3].rstrip('.')
                                        if self._rdata_targets_match(raw_target, dns_target, origin, normalized_name_lower):
                                            raw_rdata = raw_rdata_str
                                            raw_owner_key = raw_name
                                            break
                                else:
                                    # For CNAME, NS, PTR, and others: direct comparison
                                    raw_target = raw_rdata_normalized.rstrip('.')
                                    dns_target = dnspython_rdata_str.rstrip('.')
                                    if self._rdata_targets_match(raw_target, dns_target, origin, normalized_name_lower):
                                        raw_rdata = raw_rdata_str
                                        raw_owner_key = raw_name
                                        break
                    
                    # Determine the stored name based on the raw owner key (if available)
                    if raw_owner_key == '@':
                        stored_name = '@'
                        self.logger.debug(f"Preserving @ owner for {record_type} record (from raw RDATA match)")
                    elif was_fqdn_in_file:
                        # Preserve the trailing dot as it was in the original file
                        stored_name = fqdn_str
                        self.logger.debug(f"Preserving FQDN format: {stored_name}")
                    else:
                        # Relativize to origin to get relative name (e.g., "ns1" not "ns1.mondomaine.fr.")
                        relative_name = fqdn.relativize(origin_name)
                        stored_name = relative_name.to_text().rstrip('.')
                        self.logger.debug(f"Using relative name: {stored_name}")
                    
                    record_data = self._convert_rdata_to_record(
                        stored_name, record_type, rdata, ttl, zone_id, explicit_ttls,
                        fqdn_str.rstrip('.'),  # Pass normalized name for TTL detection
                        raw_rdata  # Pass raw RDATA from zone file
                    )
                    if record_data:
                        records.append(record_data)
        
        return records
    
    def _convert_rdata_to_record(self, name: str, record_type: str, 
                                 rdata: Any, ttl: int, zone_id: int,
                                 explicit_ttls: Optional[Set[Tuple[str, str, str]]] = None,
                                 normalized_name: Optional[str] = None,
                                 raw_rdata: Optional[str] = None) -> Optional[Dict]:
        """Convert dnspython rdata to dns_records table format
        
        Args:
            name: Record name to store (may have trailing dot if FQDN)
            record_type: Record type
            rdata: Record data from dnspython
            ttl: TTL value
            zone_id: Zone file ID
            explicit_ttls: Set of records with explicit TTL
            normalized_name: Normalized name (lowercase, no trailing dot) for TTL detection.
                           If None, name will be normalized on-the-fly.
            raw_rdata: Raw RDATA string from zone file (preserves @ symbols)
        """
        # Use raw RDATA only if it contains @ symbol, otherwise use dnspython's string representation.
        # Dnspython returns relative names for targets within origin (e.g., "ns1" not "ns1.mondomaine.fr."),
        # but preserves @ symbols as-is when they appear in RDATA.
        if raw_rdata is not None and '@' in raw_rdata:
            rdata_str = raw_rdata
        else:
            rdata_str = str(rdata)
        rdata_key = rdata_str
        
        # Normalize name for TTL detection (lowercase, no trailing dot)
        ttl_check_name = normalized_name if normalized_name is not None else name.rstrip('.').lower()
        
        # Check if this record had an explicit TTL
        has_explicit_ttl = False
        if explicit_ttls is not None:
            # Try to find match in explicit_ttls set
            # Match by name, type, and a normalized form of rdata
            for (exp_name, exp_type, exp_rdata) in explicit_ttls:
                if exp_name == ttl_check_name and exp_type == record_type:
                    # Also check rdata to avoid false positives when multiple records
                    # with same name and type exist
                    # Normalize both for comparison (strip whitespace, lowercase)
                    exp_rdata_norm = exp_rdata.strip().lower()
                    rdata_norm = rdata_str.strip().lower()
                    # Check if rdata starts with expected value (handles variations in formatting)
                    if rdata_norm.startswith(exp_rdata_norm) or exp_rdata_norm.startswith(rdata_norm):
                        has_explicit_ttl = True
                        break
        
        base_record = {
            'zone_file_id': zone_id,
            'record_type': record_type,
            'name': name,
            'status': 'active',
            'created_by': self.args.user_id,
            'value': rdata_str
        }
        
        # Only set TTL if it was explicit in the original file
        if has_explicit_ttl or explicit_ttls is None:
            base_record['ttl'] = ttl
        
        try:
            if record_type == 'A':
                base_record['address_ipv4'] = str(rdata.address)
            elif record_type == 'AAAA':
                base_record['address_ipv6'] = str(rdata.address)
            elif record_type == 'CNAME':
                # Use raw RDATA only if it contains @ symbol, otherwise use dnspython's relativized form
                if raw_rdata and '@' in raw_rdata:
                    base_record['cname_target'] = raw_rdata.strip()
                else:
                    base_record['cname_target'] = str(rdata.target)
            elif record_type == 'MX':
                # For MX, extract the target from raw RDATA (format: "priority target")
                mx_target = str(rdata.exchange)
                # Use raw target only if it contains @ symbol
                if raw_rdata and '@' in raw_rdata:
                    # Parse raw RDATA to get the target (second part)
                    parts = raw_rdata.strip().split(None, 1)
                    if len(parts) == 2:
                        # Use the raw target value to preserve @ symbol
                        mx_target = parts[1].strip()
                base_record['mx_target'] = mx_target
                base_record['priority'] = rdata.preference
            elif record_type == 'NS':
                # Use raw RDATA only if it contains @ symbol, otherwise use dnspython's relativized form
                if raw_rdata and '@' in raw_rdata:
                    base_record['ns_target'] = raw_rdata.strip()
                else:
                    base_record['ns_target'] = str(rdata.target)
            elif record_type == 'PTR':
                # Use raw RDATA only if it contains @ symbol, otherwise use dnspython's relativized form
                if raw_rdata and '@' in raw_rdata:
                    base_record['ptrdname'] = raw_rdata.strip()
                else:
                    base_record['ptrdname'] = str(rdata.target)
            elif record_type == 'TXT':
                # TXT records can have multiple strings
                txt_value = ' '.join([s.decode('utf-8', errors='replace') if isinstance(s, bytes) else str(s) 
                                     for s in rdata.strings])
                base_record['txt'] = txt_value
            elif record_type == 'SRV':
                # For SRV, extract the target from raw RDATA (format: "priority weight port target")
                srv_target = str(rdata.target)
                # Use raw target only if it contains @ symbol
                if raw_rdata and '@' in raw_rdata:
                    # Parse raw RDATA to get the target (fourth part)
                    parts = raw_rdata.strip().split(None, 3)
                    if len(parts) == 4:
                        # Use the raw target value to preserve @ symbol
                        srv_target = parts[3].strip()
                base_record['srv_target'] = srv_target
                base_record['priority'] = rdata.priority
                base_record['weight'] = rdata.weight
                base_record['port'] = rdata.port
            elif record_type == 'CAA':
                base_record['caa_flag'] = rdata.flags
                base_record['caa_tag'] = rdata.tag.decode('utf-8', errors='replace') if isinstance(rdata.tag, bytes) else str(rdata.tag)
                base_record['caa_value'] = rdata.value.decode('utf-8', errors='replace') if isinstance(rdata.value, bytes) else str(rdata.value)
            
            return base_record
            
        except Exception as e:
            self.logger.warning(f"Failed to convert {record_type} record {name}: {e}")
            return None
    
    def import_zone_file(self, filepath: Path) -> bool:
        """Import a single zone file"""
        self.logger.info(f"Processing zone file: {filepath}")
        
        # Read the file content first to check for $INCLUDE directives
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                file_content = f.read()
        except Exception as e:
            self.logger.error(f"Failed to read zone file {filepath}: {e}")
            self.stats['errors'] += 1
            return False
        
        # Reset include tracking for this zone
        self.include_depth = 0
        self.visited_includes.clear()
        
        # Find $INCLUDE directives if --create-includes is enabled
        include_directives = []
        if self.args.create_includes:
            include_directives = self._find_include_directives(file_content, filepath.parent)
            if include_directives:
                self.logger.info(f"Found {len(include_directives)} $INCLUDE directive(s) in {filepath.name}")
        
        # Parse the zone file
        result = self._parse_zone_file(filepath)
        if not result:
            self.stats['errors'] += 1
            return False
        
        zone, origin = result
        zone_name = origin.rstrip('.')
        
        # Get default TTL from zone (check various attributes)
        # Extract this early so it can be passed to includes
        default_ttl = 86400  # Default fallback
        if hasattr(zone, 'default_ttl') and zone.default_ttl:
            default_ttl = zone.default_ttl
        elif hasattr(zone, 'ttl') and zone.ttl:
            default_ttl = zone.ttl
        else:
            # Check for $TTL directive in file content
            # BIND supports time unit suffixes: s, m, h, d, w
            # dnspython already parsed this, so if we got here, there was no TTL
            self.logger.warning(f"Master zone {zone_name} has no default TTL. Using fallback: {default_ttl}")
        
        self.logger.debug(f"Master zone default TTL: {default_ttl}")
        
        # Check if zone already exists
        if self.args.skip_existing and self._check_zone_exists(zone_name):
            self.logger.info(f"Zone {zone_name} already exists, skipping")
            self.stats['skipped'] += 1
            return True
        
        # Start transaction for DB mode
        if self.args.db_mode and not self.args.dry_run:
            try:
                self.db_conn.begin()
            except Exception as e:
                self.logger.warning(f"Could not start transaction: {e}")
        
        try:
            # Detect explicit TTLs before processing records
            explicit_ttls = self._detect_explicit_ttls(file_content, origin)
            self.logger.debug(f"Detected {len(explicit_ttls)} record(s) with explicit TTL in master zone {zone_name}")
            
            # Detect FQDN owners in the zone file
            fqdn_owners = self._detect_fqdn_owners(file_content)
            self.logger.debug(f"Detected {len(fqdn_owners)} FQDN owner(s) in master zone {zone_name}")
            
            # Extract raw RDATA to preserve @ symbols
            raw_rdata_list = self._extract_raw_rdata(file_content, origin)
            self.logger.debug(f"Extracted {len(raw_rdata_list)} raw RDATA value(s) from master zone {zone_name}")
            
            # Detect @ owners in the zone file
            at_owners = self._detect_at_owners(file_content, origin)
            self.logger.debug(f"Detected {len(at_owners)} @ owner(s) in master zone {zone_name}")
            
            # Extract SOA data
            soa_data = self._extract_soa_data(zone, origin)
            
            # Extract DNSSEC key includes if --create-includes is enabled
            dnssec_includes = {'ksk': None, 'zsk': None}
            if self.args.create_includes and include_directives:
                dnssec_includes = self._extract_dnssec_includes(include_directives, filepath.parent)
            
            # Prepare zone data - content NOT stored, records will be in dns_records table
            # Compute directory to store for master zone (no resolution strategy, will use --dir relative or absolute)
            master_directory_to_store = self._compute_directory_to_store(filepath)
            
            zone_data = {
                'name': zone_name,
                'filename': filepath.name,
                'file_type': 'master',
                'status': 'active',
                'created_by': self.args.user_id,
                'domain': zone_name,
                'default_ttl': default_ttl,
                # 'content': NOT stored - SOA/TTL in columns, records in dns_records table
                'directory': master_directory_to_store,
                **soa_data
            }
            
            # Add DNSSEC include paths if present
            if dnssec_includes['ksk']:
                zone_data['dnssec_include_ksk'] = dnssec_includes['ksk']
            if dnssec_includes['zsk']:
                zone_data['dnssec_include_zsk'] = dnssec_includes['zsk']
            
            # Dry-run mode
            if self.args.dry_run:
                self.logger.info(f"[DRY-RUN] Would create master zone: {zone_name}")
                
                # Show DNSSEC includes if detected
                if dnssec_includes['ksk']:
                    self.logger.info(f"[DRY-RUN] Would set dnssec_include_ksk: {dnssec_includes['ksk']}")
                if dnssec_includes['zsk']:
                    self.logger.info(f"[DRY-RUN] Would set dnssec_include_zsk: {dnssec_includes['zsk']}")
                
                self.logger.debug(f"[DRY-RUN] Zone data: {zone_data}")
                
                # Extract and display records
                records = self._extract_records(zone, origin, 0, explicit_ttls, fqdn_owners, raw_rdata_list, at_owners)
                
                # Extract out-of-origin records
                out_of_origin_records = self._extract_out_of_origin_records(
                    file_content, origin, 0, explicit_ttls, default_ttl
                )
                if out_of_origin_records:
                    self.logger.info(f"[DRY-RUN] Found {len(out_of_origin_records)} out-of-origin record(s)")
                    records.extend(out_of_origin_records)
                
                self.logger.info(f"[DRY-RUN] Would create {len(records)} records for master")
                for record in records[:5]:  # Show first 5
                    self.logger.debug(f"[DRY-RUN] Record: {record['name']} {record['record_type']} {record['value']}")
                
                # Process includes in dry-run (skip DNSSEC key files)
                include_count = 0
                if self.args.create_includes and include_directives:
                    for include_path, include_origin, line_num in include_directives:
                        # Skip DNSSEC key files - they're stored in master zone fields
                        if self._is_dnssec_key_file(include_path):
                            self.logger.debug(f"[DRY-RUN] Skipping DNSSEC key include (handled as master zone field): {include_path}")
                            continue
                        
                        result = self._resolve_include_path(include_path, filepath.parent)
                        if result:
                            resolved_path, resolution_strategy = result
                            include_id = self._process_include_file(
                                resolved_path, 
                                include_origin, 
                                filepath.parent,
                                zone_name,
                                default_ttl,
                                resolution_strategy
                            )
                            if include_id:
                                include_count += 1
                    
                    if include_count > 0:
                        self.logger.info(f"[DRY-RUN] Would create {include_count} zone_file_includes relationships")
                
                self.stats['zones_created'] += 1
                self.stats['records_created'] += len(records)
                return True
            
            # Create master zone first (before processing includes)
            if self.args.db_mode:
                zone_id = self._create_zone_db(zone_data)
            else:
                zone_id = self._create_zone_api(zone_data)
            
            if not zone_id:
                self.stats['errors'] += 1
                if self.args.db_mode:
                    self.db_conn.rollback()
                return False
            
            self.stats['zones_created'] += 1
            self.logger.info(f"Master zone created (ID: {zone_id}), now processing includes...")
            
            # Process $INCLUDE files after master zone is created (skip DNSSEC key files)
            include_zone_ids = []
            if self.args.create_includes and include_directives:
                for include_path, include_origin, line_num in include_directives:
                    # Skip DNSSEC key files - they're stored in master zone fields
                    if self._is_dnssec_key_file(include_path):
                        self.logger.info(f"Skipping DNSSEC key include (handled as master zone field): {include_path}")
                        continue
                    
                    result = self._resolve_include_path(include_path, filepath.parent)
                    if result:
                        resolved_path, resolution_strategy = result
                        include_id = self._process_include_file(
                            resolved_path, 
                            include_origin, 
                            filepath.parent,
                            zone_name,
                            default_ttl,  # Pass master's TTL to include
                            resolution_strategy
                        )
                        if include_id:
                            include_zone_ids.append((include_id, line_num))
                        else:
                            self.logger.warning(f"Failed to process include at line {line_num}: {include_path}")
                    else:
                        self.logger.warning(f"Could not resolve include at line {line_num}: {include_path}")
            
            # Create zone_file_includes relationships
            for include_id, position in include_zone_ids:
                self._create_zone_file_include_relationship(zone_id, include_id, position)
            
            # Extract and create records from master zone
            records = self._extract_records(zone, origin, zone_id, explicit_ttls, fqdn_owners, raw_rdata_list, at_owners)
            
            # Extract out-of-origin records from raw content
            out_of_origin_records = self._extract_out_of_origin_records(
                file_content, origin, zone_id, explicit_ttls, default_ttl
            )
            
            if out_of_origin_records:
                self.logger.info(f"Found {len(out_of_origin_records)} out-of-origin record(s)")
                records.extend(out_of_origin_records)
            
            self.logger.info(f"Importing {len(records)} records for zone {zone_name}")
            
            for record in records:
                if self.args.db_mode:
                    success = self._create_record_db(record)
                else:
                    success = self._create_record_api(record)
                
                if success:
                    self.stats['records_created'] += 1
                else:
                    self.stats['errors'] += 1
            
            # Commit transaction if in DB mode
            if self.args.db_mode:
                self.db_conn.commit()
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing zone {filepath}: {e}")
            if self.args.db_mode and not self.args.dry_run:
                try:
                    self.db_conn.rollback()
                    self.logger.info("Transaction rolled back")
                except Exception:
                    pass
            self.stats['errors'] += 1
            return False
    
    def import_directory(self, directory: Path) -> bool:
        """Import all zone files from a directory"""
        if not directory.is_dir():
            self.logger.error(f"Directory not found: {directory}")
            return False
        
        # Find zone files (common extensions)
        zone_files = []
        for ext in ['*.zone', '*.db', '*.conf']:
            zone_files.extend(directory.glob(ext))
        
        # Also check files without extension
        for item in directory.iterdir():
            if item.is_file() and not item.suffix:
                zone_files.append(item)
        
        if not zone_files:
            self.logger.warning(f"No zone files found in {directory}")
            return False
        
        self.logger.info(f"Found {len(zone_files)} zone file(s) in {directory}")
        
        for zone_file in zone_files:
            self.import_zone_file(zone_file)
        
        return True
    
    def print_stats(self):
        """Print import statistics"""
        self.logger.info("=" * 50)
        self.logger.info("Import Statistics:")
        self.logger.info(f"  Zones created: {self.stats['zones_created']}")
        self.logger.info(f"  Records created: {self.stats['records_created']}")
        self.logger.info(f"  Includes created: {self.stats['includes_created']}")
        self.logger.info(f"  Skipped: {self.stats['skipped']}")
        self.logger.info(f"  Errors: {self.stats['errors']}")
        self.logger.info("=" * 50)
    
    def run_example(self):
        """Run with example zone data for testing"""
        self.logger.info("Running in EXAMPLE mode with sample zone data")
        
        example_zone = """
$ORIGIN example.com.
$TTL 3600
@       IN      SOA     ns1.example.com. admin.example.com. (
                        2024120801 ; serial
                        10800      ; refresh
                        900        ; retry
                        604800     ; expire
                        3600       ; minimum
                        )
        IN      NS      ns1.example.com.
        IN      NS      ns2.example.com.
        IN      A       192.0.2.1
www     IN      A       192.0.2.1
mail    IN      A       192.0.2.10
        IN      MX      10 mail.example.com.
ftp     IN      CNAME   www.example.com.
"""
        
        self.logger.info("Sample zone content:")
        print(example_zone)
        
        try:
            zone = dns.zone.from_text(example_zone, origin='example.com.')
            self.logger.info("\nParsed zone successfully!")
            
            # Extract raw RDATA and @ owners to test preservation
            raw_rdata_list = self._extract_raw_rdata(example_zone, 'example.com.')
            at_owners = self._detect_at_owners(example_zone, 'example.com.')
            
            # Extract records
            records = self._extract_records(zone, 'example.com.', 0, None, None, raw_rdata_list, at_owners)
            self.logger.info(f"\nExtracted {len(records)} records:")
            for record in records:
                print(f"  - {record['name']} {record['ttl']} IN {record['record_type']} {record['value']}")
            
        except Exception as e:
            self.logger.error(f"Failed to parse example zone: {e}")
            return False
        
        return True
    
    def run(self):
        """Main execution method"""
        # Example mode
        if self.args.example:
            return self.run_example()
        
        # Validate arguments
        if not self.args.dir:
            self.logger.error("--dir is required (or use --example)")
            return False
        
        # Setup based on mode
        if self.args.db_mode:
            self.logger.info("Using DB mode (direct database insertion)")
            self._connect_db()
        else:
            self.logger.info("Using API mode (HTTP requests)")
            if not self.args.api_url:
                self.logger.error("--api-url is required for API mode (or use --db-mode)")
                return False
            if not self.args.api_token:
                self.logger.warning("--api-token not provided. API calls may fail.")
        
        if self.args.dry_run:
            self.logger.info("DRY-RUN mode enabled - no changes will be made")
        
        # Import zones
        directory = Path(self.args.dir)
        self.import_directory(directory)
        
        # Print statistics
        self.print_stats()
        
        # Cleanup
        if self.db_conn:
            self.db_conn.close()
        
        return self.stats['errors'] == 0


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='Import BIND zone files into dns3 application',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    
    # General options
    parser.add_argument('--dir', type=str, help='Directory containing zone files')
    parser.add_argument('--dry-run', action='store_true', 
                       help='Show what would be done without making changes')
    parser.add_argument('--skip-existing', action='store_true',
                       help='Skip zones that already exist')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Enable verbose logging')
    parser.add_argument('--example', action='store_true',
                       help='Run with example zone data for testing')
    
    # API mode options
    parser.add_argument('--api-url', type=str,
                       help='Base URL for API (e.g., http://localhost/dns3)')
    parser.add_argument('--api-token', type=str,
                       help='API authentication token')
    
    # DB mode options
    parser.add_argument('--db-mode', action='store_true',
                       help='Use direct database insertion instead of API')
    parser.add_argument('--db-host', type=str, default='localhost',
                       help='Database host (default: localhost)')
    parser.add_argument('--db-port', type=int, default=3306,
                       help='Database port (default: 3306)')
    parser.add_argument('--db-user', type=str, default='root',
                       help='Database user (default: root)')
    parser.add_argument('--db-pass', type=str, default='',
                       help='Database password')
    parser.add_argument('--db-name', type=str, default='dns3_db',
                       help='Database name (default: dns3_db)')
    
    # Other options
    parser.add_argument('--user-id', type=int, default=1,
                       help='User ID for created_by field (default: 1)')
    parser.add_argument('--create-includes', action='store_true',
                       help='Create include zone files for $INCLUDE directives')
    parser.add_argument('--allow-abs-include', action='store_true',
                       help='Allow absolute paths in $INCLUDE directives (security: use with caution)')
    parser.add_argument('--include-search-paths', type=str, default='',
                       help='Additional search paths for $INCLUDE files (colon or comma separated, e.g., "/var/named/includes:/etc/bind/includes")')
    
    # Logging options
    parser.add_argument('--log-file', type=str,
                       help='Path to log file (enables file logging with rotation)')
    parser.add_argument('--log-level', type=str, 
                       choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
                       help='Log level (default: INFO, or DEBUG if --verbose)')
    
    args = parser.parse_args()
    
    # Process include-search-paths: split by colon or comma
    if args.include_search_paths:
        # Split by colon or comma, strip whitespace, filter empty strings
        separator = ':' if ':' in args.include_search_paths else ','
        args.include_search_paths = [
            p.strip() for p in args.include_search_paths.split(separator) if p.strip()
        ]
    else:
        args.include_search_paths = []
    
    # Create and run importer
    importer = ZoneImporter(args)
    success = importer.run()
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
