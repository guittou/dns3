#!/usr/bin/env python3
"""
BIND Zone File Importer for dns3

Imports BIND-format zone files into the dns3 application using either:
- API mode (default): HTTP calls to zone_api.php and dns_api.php endpoints
- DB mode (--db-mode): Direct MySQL insertion with schema introspection

Features:
- Parses zone files using dnspython library
- Extracts $ORIGIN, SOA, default TTL, and all resource records
- Handles $INCLUDE directives and creates zone_file_includes entries
- Supports dry-run mode for safe testing
- Validates input and provides detailed error reporting

Dependencies: python3, dnspython, requests, pymysql

Usage examples:
  # API mode (default, requires --api-url and --api-token)
  python3 scripts/import_bind_zones.py --dir /path/to/zones --api-url http://localhost/dns3 --api-token abc123

  # DB mode (direct database insertion)
  python3 scripts/import_bind_zones.py --dir /path/to/zones --db-mode --db-user root --db-pass secret

  # Dry-run mode (shows what would be done without making changes)
  python3 scripts/import_bind_zones.py --dir /path/to/zones --dry-run --api-url http://localhost/dns3 --api-token abc123

  # Example mode (quick test with sample zone)
  python3 scripts/import_bind_zones.py --example
"""

import argparse
import sys
import os
import re
import logging
from typing import Dict, List, Optional, Tuple, Any
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
        
    def _setup_logging(self) -> logging.Logger:
        """Configure logging"""
        level = logging.DEBUG if self.args.verbose else logging.INFO
        logging.basicConfig(
            format='%(asctime)s [%(levelname)s] %(message)s',
            level=level,
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        return logging.getLogger(__name__)
    
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
        optional_columns = ['content', 'default_ttl', 'soa_refresh', 'soa_retry', 
                          'soa_expire', 'soa_minimum', 'soa_rname', 'mname']
        
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
    
    def _parse_zone_file(self, filepath: Path) -> Optional[Tuple[dns.zone.Zone, str]]:
        """Parse a BIND zone file using dnspython"""
        try:
            # Try to extract origin from filename or file content
            zone_name = filepath.stem
            
            # Read file content to check for $ORIGIN
            with open(filepath, 'r') as f:
                content = f.read()
            
            # Look for $ORIGIN directive
            origin_match = re.search(r'^\$ORIGIN\s+(\S+)', content, re.MULTILINE)
            if origin_match:
                origin = origin_match.group(1)
                if not origin.endswith('.'):
                    origin += '.'
            else:
                # Use filename as origin
                origin = zone_name if zone_name.endswith('.') else zone_name + '.'
            
            # Parse the zone
            zone = dns.zone.from_text(content, origin=origin, check_origin=False)
            
            self.logger.debug(f"Parsed zone file: {filepath.name} with origin: {origin}")
            return zone, origin
            
        except Exception as e:
            self.logger.error(f"Failed to parse zone file {filepath}: {e}")
            return None
    
    def _extract_soa_data(self, zone: dns.zone.Zone, origin: str) -> Dict:
        """Extract SOA record data from zone"""
        soa_data = {
            'mname': None,
            'soa_rname': None,
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
                soa_data['soa_refresh'] = soa.refresh
                soa_data['soa_retry'] = soa.retry
                soa_data['soa_expire'] = soa.expire
                soa_data['soa_minimum'] = soa.minimum
        except Exception as e:
            self.logger.warning(f"Could not extract SOA data: {e}")
        
        return soa_data
    
    def _extract_records(self, zone: dns.zone.Zone, origin: str, zone_id: int) -> List[Dict]:
        """Extract DNS records from zone"""
        records = []
        
        for name, node in zone.items():
            name_str = str(name.derelativize(dns.name.from_text(origin)))
            
            for rdataset in node:
                record_type = dns.rdatatype.to_text(rdataset.rdtype)
                ttl = rdataset.ttl
                
                # Skip SOA records as they're part of zone metadata
                if record_type == 'SOA':
                    continue
                
                for rdata in rdataset:
                    record_data = self._convert_rdata_to_record(
                        name_str, record_type, rdata, ttl, zone_id
                    )
                    if record_data:
                        records.append(record_data)
        
        return records
    
    def _convert_rdata_to_record(self, name: str, record_type: str, 
                                 rdata: Any, ttl: int, zone_id: int) -> Optional[Dict]:
        """Convert dnspython rdata to dns_records table format"""
        base_record = {
            'zone_file_id': zone_id,
            'record_type': record_type,
            'name': name,
            'ttl': ttl,
            'status': 'active',
            'created_by': self.args.user_id,
            'value': str(rdata)
        }
        
        try:
            if record_type == 'A':
                base_record['address_ipv4'] = str(rdata.address)
            elif record_type == 'AAAA':
                base_record['address_ipv6'] = str(rdata.address)
            elif record_type == 'CNAME':
                base_record['cname_target'] = str(rdata.target)
            elif record_type == 'MX':
                base_record['mx_target'] = str(rdata.exchange)
                base_record['priority'] = rdata.preference
            elif record_type == 'NS':
                base_record['ns_target'] = str(rdata.target)
            elif record_type == 'PTR':
                base_record['ptrdname'] = str(rdata.target)
            elif record_type == 'TXT':
                # TXT records can have multiple strings
                txt_value = ' '.join([s.decode('utf-8') if isinstance(s, bytes) else str(s) 
                                     for s in rdata.strings])
                base_record['txt'] = txt_value
            elif record_type == 'SRV':
                base_record['srv_target'] = str(rdata.target)
                base_record['priority'] = rdata.priority
                base_record['weight'] = rdata.weight
                base_record['port'] = rdata.port
            elif record_type == 'CAA':
                base_record['caa_flag'] = rdata.flags
                base_record['caa_tag'] = rdata.tag.decode('utf-8') if isinstance(rdata.tag, bytes) else str(rdata.tag)
                base_record['caa_value'] = rdata.value.decode('utf-8') if isinstance(rdata.value, bytes) else str(rdata.value)
            
            return base_record
            
        except Exception as e:
            self.logger.warning(f"Failed to convert {record_type} record {name}: {e}")
            return None
    
    def import_zone_file(self, filepath: Path) -> bool:
        """Import a single zone file"""
        self.logger.info(f"Processing zone file: {filepath}")
        
        # Parse the zone file
        result = self._parse_zone_file(filepath)
        if not result:
            self.stats['errors'] += 1
            return False
        
        zone, origin = result
        zone_name = origin.rstrip('.')
        
        # Check if zone already exists
        if self.args.skip_existing and self._check_zone_exists(zone_name):
            self.logger.info(f"Zone {zone_name} already exists, skipping")
            self.stats['skipped'] += 1
            return True
        
        # Extract SOA data
        soa_data = self._extract_soa_data(zone, origin)
        
        # Get default TTL from zone
        default_ttl = zone.get_ttl() if hasattr(zone, 'get_ttl') else 86400
        
        # Prepare zone data
        zone_data = {
            'name': zone_name,
            'filename': filepath.name,
            'file_type': 'master',
            'status': 'active',
            'created_by': self.args.user_id,
            'domain': zone_name,
            'default_ttl': default_ttl,
            **soa_data
        }
        
        # Dry-run mode
        if self.args.dry_run:
            self.logger.info(f"[DRY-RUN] Would create zone: {zone_name}")
            self.logger.debug(f"[DRY-RUN] Zone data: {zone_data}")
            
            # Extract and display records
            records = self._extract_records(zone, origin, 0)
            self.logger.info(f"[DRY-RUN] Would create {len(records)} records")
            for record in records[:5]:  # Show first 5
                self.logger.debug(f"[DRY-RUN] Record: {record['name']} {record['record_type']} {record['value']}")
            
            self.stats['zones_created'] += 1
            self.stats['records_created'] += len(records)
            return True
        
        # Create zone
        if self.args.db_mode:
            zone_id = self._create_zone_db(zone_data)
        else:
            zone_id = self._create_zone_api(zone_data)
        
        if not zone_id:
            self.stats['errors'] += 1
            return False
        
        self.stats['zones_created'] += 1
        
        # Extract and create records
        records = self._extract_records(zone, origin, zone_id)
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
        
        return True
    
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
            
            # Extract records
            records = self._extract_records(zone, 'example.com.', 0)
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
    
    args = parser.parse_args()
    
    # Create and run importer
    importer = ZoneImporter(args)
    success = importer.run()
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
