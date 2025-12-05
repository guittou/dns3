<?php
/**
 * DnsValidator - Strict ASCII DNS Validation Library
 * 
 * Provides validation for DNS zone names and record data with strict ASCII-only support.
 * NO IDN (Internationalized Domain Names) support - only ASCII characters allowed.
 * 
 * DNS Label Rules (RFC 1035):
 * - Maximum 63 characters per label
 * - Only ASCII letters (a-z, A-Z), digits (0-9), and hyphens (-)
 * - Cannot start or end with a hyphen
 * - Case-insensitive
 * 
 * DNS Name Rules:
 * - Maximum 253 characters total (excluding trailing dot)
 * - Labels separated by dots (.)
 * - Each label must follow label rules
 */
class DnsValidator {
    
    /**
     * Validate a single DNS label
     * 
     * @param string $label The label to validate
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateLabel($label) {
        // Empty label is invalid
        if ($label === '' || $label === null) {
            return ['valid' => false, 'error' => 'Label cannot be empty'];
        }
        
        // Check length (max 63 characters per label)
        if (strlen($label) > 63) {
            return ['valid' => false, 'error' => 'Label exceeds maximum length of 63 characters'];
        }
        
        // Check for non-ASCII characters (strict ASCII only, no IDN)
        if (!mb_check_encoding($label, 'ASCII')) {
            return ['valid' => false, 'error' => 'Label contains non-ASCII characters (IDN not supported)'];
        }
        
        // Additional check for high-bit characters that might pass mb_check_encoding
        if (preg_match('/[^\x00-\x7F]/', $label)) {
            return ['valid' => false, 'error' => 'Label contains non-ASCII characters (IDN not supported)'];
        }
        
        // Check for spaces
        if (strpos($label, ' ') !== false) {
            return ['valid' => false, 'error' => 'Label cannot contain spaces'];
        }
        
        // Check valid characters: only alphanumeric and hyphen
        if (!preg_match('/^[a-zA-Z0-9\-]+$/', $label)) {
            return ['valid' => false, 'error' => 'Label contains invalid characters (only a-z, A-Z, 0-9, and hyphen allowed)'];
        }
        
        // Cannot start with hyphen
        if ($label[0] === '-') {
            return ['valid' => false, 'error' => 'Label cannot start with a hyphen'];
        }
        
        // Cannot end with hyphen
        if ($label[strlen($label) - 1] === '-') {
            return ['valid' => false, 'error' => 'Label cannot end with a hyphen'];
        }
        
        return ['valid' => true, 'error' => null];
    }
    
    /**
     * Validate a DNS name (domain name with multiple labels)
     * 
     * @param string $name The domain name to validate
     * @param bool $allowTrailingDot Whether to allow a trailing dot (FQDN)
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateName($name, $allowTrailingDot = true) {
        // Empty name is invalid
        if ($name === '' || $name === null) {
            return ['valid' => false, 'error' => 'Name cannot be empty'];
        }
        
        // Handle trailing dot for FQDN
        $hasTrailingDot = false;
        if (substr($name, -1) === '.') {
            $hasTrailingDot = true;
            $name = substr($name, 0, -1);
        }
        
        // After removing trailing dot, check if empty
        if ($name === '') {
            return ['valid' => false, 'error' => 'Name cannot be just a dot'];
        }
        
        // Check total length (max 253 characters excluding trailing dot)
        if (strlen($name) > 253) {
            return ['valid' => false, 'error' => 'Name exceeds maximum length of 253 characters'];
        }
        
        // Split into labels
        $labels = explode('.', $name);
        
        // Validate each label
        foreach ($labels as $label) {
            $result = self::validateLabel($label);
            if (!$result['valid']) {
                return $result;
            }
        }
        
        // Check if trailing dot is allowed
        if ($hasTrailingDot && !$allowTrailingDot) {
            return ['valid' => false, 'error' => 'Trailing dot not allowed in this context'];
        }
        
        return ['valid' => true, 'error' => null];
    }
    
    /**
     * Validate a record owner (name field in DNS record)
     * Can be a relative name (@, subdomain) or FQDN
     * 
     * @param string $owner The owner/name to validate
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateOwner($owner) {
        // Empty owner is invalid
        if ($owner === '' || $owner === null) {
            return ['valid' => false, 'error' => 'Owner cannot be empty'];
        }
        
        // Special case: @ represents the zone origin
        if ($owner === '@') {
            return ['valid' => true, 'error' => null];
        }
        
        // Check for non-ASCII characters
        if (!mb_check_encoding($owner, 'ASCII')) {
            return ['valid' => false, 'error' => 'Owner contains non-ASCII characters (IDN not supported)'];
        }
        
        if (preg_match('/[^\x00-\x7F]/', $owner)) {
            return ['valid' => false, 'error' => 'Owner contains non-ASCII characters (IDN not supported)'];
        }
        
        // Check for spaces
        if (strpos($owner, ' ') !== false) {
            return ['valid' => false, 'error' => 'Owner cannot contain spaces'];
        }
        
        // Validate as DNS name
        return self::validateName($owner, true);
    }
    
    /**
     * Validate an A record (IPv4 address)
     * 
     * @param string $value The IPv4 address
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateA($value) {
        if ($value === '' || $value === null) {
            return ['valid' => false, 'error' => 'A record value cannot be empty'];
        }
        
        if (filter_var($value, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) === false) {
            return ['valid' => false, 'error' => 'A record must contain a valid IPv4 address'];
        }
        
        return ['valid' => true, 'error' => null];
    }
    
    /**
     * Validate an AAAA record (IPv6 address)
     * 
     * @param string $value The IPv6 address
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateAAAA($value) {
        if ($value === '' || $value === null) {
            return ['valid' => false, 'error' => 'AAAA record value cannot be empty'];
        }
        
        if (filter_var($value, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6) === false) {
            return ['valid' => false, 'error' => 'AAAA record must contain a valid IPv6 address'];
        }
        
        return ['valid' => true, 'error' => null];
    }
    
    /**
     * Validate an MX record
     * 
     * @param string $value The MX target hostname
     * @param int|null $priority The MX priority (optional)
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateMX($value, $priority = null) {
        if ($value === '' || $value === null) {
            return ['valid' => false, 'error' => 'MX record target cannot be empty'];
        }
        
        // Validate priority if provided
        if ($priority !== null) {
            if (!is_numeric($priority) || $priority < 0 || $priority > 65535) {
                return ['valid' => false, 'error' => 'MX priority must be between 0 and 65535'];
            }
        }
        
        // MX target must be a valid hostname (not an IP address)
        if (filter_var($value, FILTER_VALIDATE_IP) !== false) {
            return ['valid' => false, 'error' => 'MX target cannot be an IP address, must be a hostname'];
        }
        
        // Validate as DNS name
        return self::validateName($value, true);
    }
    
    /**
     * Validate a CNAME record
     * 
     * @param string $value The CNAME target hostname
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateCNAME($value) {
        if ($value === '' || $value === null) {
            return ['valid' => false, 'error' => 'CNAME record target cannot be empty'];
        }
        
        // CNAME target must be a valid hostname (not an IP address)
        if (filter_var($value, FILTER_VALIDATE_IP) !== false) {
            return ['valid' => false, 'error' => 'CNAME target cannot be an IP address, must be a hostname'];
        }
        
        // Validate as DNS name
        return self::validateName($value, true);
    }
    
    /**
     * Validate a TXT record
     * 
     * @param string $value The TXT record content
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateTXT($value) {
        if ($value === '' || $value === null) {
            return ['valid' => false, 'error' => 'TXT record value cannot be empty'];
        }
        
        // TXT records can contain almost any text, but we enforce ASCII-only
        if (!mb_check_encoding($value, 'ASCII')) {
            return ['valid' => false, 'error' => 'TXT record contains non-ASCII characters (IDN not supported)'];
        }
        
        if (preg_match('/[^\x00-\x7F]/', $value)) {
            return ['valid' => false, 'error' => 'TXT record contains non-ASCII characters (IDN not supported)'];
        }
        
        // Check maximum length (TXT records have a 255 character limit per string)
        // But in practice, they can be split into multiple strings
        // We'll allow up to 65535 characters total (max DNS message size consideration)
        if (strlen($value) > 65535) {
            return ['valid' => false, 'error' => 'TXT record value exceeds maximum length'];
        }
        
        return ['valid' => true, 'error' => null];
    }
    
    /**
     * Validate a DNS record (dispatcher method)
     * 
     * @param string $recordType The record type (A, AAAA, MX, CNAME, TXT, etc.)
     * @param string $owner The record owner/name
     * @param string $value The record value (rdata)
     * @param array $extraData Additional data (e.g., priority for MX, port for SRV, etc.)
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateRecord($recordType, $owner, $value, $extraData = []) {
        // Validate owner first
        $ownerResult = self::validateOwner($owner);
        if (!$ownerResult['valid']) {
            return $ownerResult;
        }
        
        // Validate value based on record type
        switch (strtoupper($recordType)) {
            case 'A':
                return self::validateA($value);
                
            case 'AAAA':
                return self::validateAAAA($value);
                
            case 'MX':
                $priority = $extraData['priority'] ?? null;
                return self::validateMX($value, $priority);
                
            case 'CNAME':
                return self::validateCNAME($value);
                
            case 'TXT':
                return self::validateTXT($value);
                
            case 'NS':
                return self::validateNS($value);
                
            case 'PTR':
                return self::validatePTR($value);
                
            case 'SRV':
                return self::validateSRV($extraData);
                
            case 'CAA':
                return self::validateCAA($extraData);
                
            case 'TLSA':
                return self::validateTLSA($extraData);
                
            case 'SSHFP':
                return self::validateSSHFP($extraData);
                
            case 'NAPTR':
                return self::validateNAPTR($extraData);
                
            case 'SVCB':
            case 'HTTPS':
                return self::validateSVCB($extraData);
                
            case 'DNAME':
                return self::validateDNAME($value);
                
            case 'LOC':
                return self::validateLOC($extraData);
                
            case 'RP':
                return self::validateRP($extraData);
                
            case 'SOA':
                // SOA records are typically managed by zone generation, not user input
                return ['valid' => true, 'error' => null];
                
            case 'SPF':
            case 'DKIM':
            case 'DMARC':
                // These are stored as TXT records
                return self::validateTXT($value);
                
            default:
                // Allow unknown types but warn (for extensibility)
                return ['valid' => true, 'error' => null, 'warning' => "Unknown record type: $recordType"];
        }
    }
    
    /**
     * Validate an NS record
     * 
     * @param string $value The NS target hostname
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateNS($value) {
        if ($value === '' || $value === null) {
            return ['valid' => false, 'error' => 'NS record target cannot be empty'];
        }
        
        // NS target must be a valid hostname (not an IP address)
        if (filter_var($value, FILTER_VALIDATE_IP) !== false) {
            return ['valid' => false, 'error' => 'NS target cannot be an IP address, must be a hostname'];
        }
        
        // Validate as DNS name
        return self::validateName($value, true);
    }
    
    /**
     * Validate a PTR record
     * 
     * @param string $value The PTR target hostname
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validatePTR($value) {
        if ($value === '' || $value === null) {
            return ['valid' => false, 'error' => 'PTR record target cannot be empty'];
        }
        
        // Validate as DNS name
        return self::validateName($value, true);
    }
    
    /**
     * Validate an SRV record
     * 
     * @param array $data SRV record data (priority, weight, port, srv_target)
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateSRV($data) {
        // Priority
        if (isset($data['priority'])) {
            if (!is_numeric($data['priority']) || $data['priority'] < 0 || $data['priority'] > 65535) {
                return ['valid' => false, 'error' => 'SRV priority must be between 0 and 65535'];
            }
        }
        
        // Weight
        if (isset($data['weight'])) {
            if (!is_numeric($data['weight']) || $data['weight'] < 0 || $data['weight'] > 65535) {
                return ['valid' => false, 'error' => 'SRV weight must be between 0 and 65535'];
            }
        }
        
        // Port (required)
        if (!isset($data['port']) || $data['port'] === '' || $data['port'] === null) {
            return ['valid' => false, 'error' => 'SRV port is required'];
        }
        if (!is_numeric($data['port']) || $data['port'] < 0 || $data['port'] > 65535) {
            return ['valid' => false, 'error' => 'SRV port must be between 0 and 65535'];
        }
        
        // Target (required)
        $target = $data['srv_target'] ?? $data['target'] ?? null;
        if ($target === '' || $target === null) {
            return ['valid' => false, 'error' => 'SRV target is required'];
        }
        
        // Target must be a valid hostname
        return self::validateName($target, true);
    }
    
    /**
     * Validate a CAA record
     * 
     * @param array $data CAA record data (caa_flag, caa_tag, caa_value)
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateCAA($data) {
        // Flag (0 or 128)
        if (isset($data['caa_flag'])) {
            $flag = (int)$data['caa_flag'];
            if ($flag !== 0 && $flag !== 128) {
                return ['valid' => false, 'error' => 'CAA flag must be 0 or 128'];
            }
        }
        
        // Tag (required: issue, issuewild, or iodef)
        $tag = $data['caa_tag'] ?? null;
        if ($tag === '' || $tag === null) {
            return ['valid' => false, 'error' => 'CAA tag is required'];
        }
        $validTags = ['issue', 'issuewild', 'iodef'];
        if (!in_array(strtolower($tag), $validTags)) {
            return ['valid' => false, 'error' => 'CAA tag must be one of: issue, issuewild, iodef'];
        }
        
        // Value (required)
        $value = $data['caa_value'] ?? null;
        if ($value === '' || $value === null) {
            return ['valid' => false, 'error' => 'CAA value is required'];
        }
        
        return ['valid' => true, 'error' => null];
    }
    
    /**
     * Validate a TLSA record
     * 
     * @param array $data TLSA record data (tlsa_usage, tlsa_selector, tlsa_matching, tlsa_data)
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateTLSA($data) {
        // Usage (0-3)
        if (!isset($data['tlsa_usage']) || $data['tlsa_usage'] === '' || $data['tlsa_usage'] === null) {
            return ['valid' => false, 'error' => 'TLSA usage is required'];
        }
        $usage = (int)$data['tlsa_usage'];
        if ($usage < 0 || $usage > 3) {
            return ['valid' => false, 'error' => 'TLSA usage must be between 0 and 3'];
        }
        
        // Selector (0 or 1)
        if (!isset($data['tlsa_selector']) || $data['tlsa_selector'] === '' || $data['tlsa_selector'] === null) {
            return ['valid' => false, 'error' => 'TLSA selector is required'];
        }
        $selector = (int)$data['tlsa_selector'];
        if ($selector < 0 || $selector > 1) {
            return ['valid' => false, 'error' => 'TLSA selector must be 0 or 1'];
        }
        
        // Matching type (0-2)
        if (!isset($data['tlsa_matching']) || $data['tlsa_matching'] === '' || $data['tlsa_matching'] === null) {
            return ['valid' => false, 'error' => 'TLSA matching type is required'];
        }
        $matching = (int)$data['tlsa_matching'];
        if ($matching < 0 || $matching > 2) {
            return ['valid' => false, 'error' => 'TLSA matching type must be between 0 and 2'];
        }
        
        // Data (hex string, required)
        $tlsaData = $data['tlsa_data'] ?? null;
        if ($tlsaData === '' || $tlsaData === null) {
            return ['valid' => false, 'error' => 'TLSA data is required'];
        }
        if (!preg_match('/^[0-9A-Fa-f]+$/', $tlsaData)) {
            return ['valid' => false, 'error' => 'TLSA data must be a valid hex string'];
        }
        
        return ['valid' => true, 'error' => null];
    }
    
    /**
     * Validate an SSHFP record
     * 
     * @param array $data SSHFP record data (sshfp_algo, sshfp_type, sshfp_fingerprint)
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateSSHFP($data) {
        // Algorithm (1=RSA, 2=DSA, 3=ECDSA, 4=Ed25519)
        if (!isset($data['sshfp_algo']) || $data['sshfp_algo'] === '' || $data['sshfp_algo'] === null) {
            return ['valid' => false, 'error' => 'SSHFP algorithm is required'];
        }
        $algo = (int)$data['sshfp_algo'];
        if ($algo < 1 || $algo > 4) {
            return ['valid' => false, 'error' => 'SSHFP algorithm must be between 1 and 4'];
        }
        
        // Fingerprint type (1=SHA1, 2=SHA256)
        if (!isset($data['sshfp_type']) || $data['sshfp_type'] === '' || $data['sshfp_type'] === null) {
            return ['valid' => false, 'error' => 'SSHFP fingerprint type is required'];
        }
        $fpType = (int)$data['sshfp_type'];
        if ($fpType < 1 || $fpType > 2) {
            return ['valid' => false, 'error' => 'SSHFP fingerprint type must be 1 or 2'];
        }
        
        // Fingerprint (hex string, required)
        $fingerprint = $data['sshfp_fingerprint'] ?? null;
        if ($fingerprint === '' || $fingerprint === null) {
            return ['valid' => false, 'error' => 'SSHFP fingerprint is required'];
        }
        if (!preg_match('/^[0-9A-Fa-f]+$/', $fingerprint)) {
            return ['valid' => false, 'error' => 'SSHFP fingerprint must be a valid hex string'];
        }
        
        return ['valid' => true, 'error' => null];
    }
    
    /**
     * Validate a NAPTR record
     * 
     * @param array $data NAPTR record data
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateNAPTR($data) {
        // Order (required, 0-65535)
        if (!isset($data['naptr_order']) || $data['naptr_order'] === '' || $data['naptr_order'] === null) {
            return ['valid' => false, 'error' => 'NAPTR order is required'];
        }
        if (!is_numeric($data['naptr_order']) || $data['naptr_order'] < 0 || $data['naptr_order'] > 65535) {
            return ['valid' => false, 'error' => 'NAPTR order must be between 0 and 65535'];
        }
        
        // Preference (required, 0-65535)
        if (!isset($data['naptr_pref']) || $data['naptr_pref'] === '' || $data['naptr_pref'] === null) {
            return ['valid' => false, 'error' => 'NAPTR preference is required'];
        }
        if (!is_numeric($data['naptr_pref']) || $data['naptr_pref'] < 0 || $data['naptr_pref'] > 65535) {
            return ['valid' => false, 'error' => 'NAPTR preference must be between 0 and 65535'];
        }
        
        // Flags (optional but if provided, should be valid)
        $flags = $data['naptr_flags'] ?? null;
        if ($flags !== null && $flags !== '') {
            if (!preg_match('/^[A-Za-z0-9]*$/', $flags)) {
                return ['valid' => false, 'error' => 'NAPTR flags must be alphanumeric'];
            }
        }
        
        // Service (optional)
        // Regexp and Replacement are mutually exclusive but we don't enforce here
        
        return ['valid' => true, 'error' => null];
    }
    
    /**
     * Validate a SVCB/HTTPS record
     * 
     * @param array $data SVCB/HTTPS record data
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateSVCB($data) {
        // Priority (required, 0-65535, 0 = AliasMode)
        if (!isset($data['svc_priority']) || $data['svc_priority'] === '' || $data['svc_priority'] === null) {
            return ['valid' => false, 'error' => 'SVCB/HTTPS priority is required'];
        }
        if (!is_numeric($data['svc_priority']) || $data['svc_priority'] < 0 || $data['svc_priority'] > 65535) {
            return ['valid' => false, 'error' => 'SVCB/HTTPS priority must be between 0 and 65535'];
        }
        
        // Target (required)
        $target = $data['svc_target'] ?? null;
        if ($target === '' || $target === null) {
            return ['valid' => false, 'error' => 'SVCB/HTTPS target is required'];
        }
        
        // Validate target as DNS name (except for "." which means use owner name)
        if ($target !== '.') {
            $nameResult = self::validateName($target, true);
            if (!$nameResult['valid']) {
                return $nameResult;
            }
        }
        
        // Params (optional, should be valid JSON if provided)
        $params = $data['svc_params'] ?? null;
        if ($params !== null && $params !== '') {
            // Try to parse as JSON if it looks like JSON
            if (substr($params, 0, 1) === '{' || substr($params, 0, 1) === '[') {
                $decoded = json_decode($params);
                if ($decoded === null && json_last_error() !== JSON_ERROR_NONE) {
                    return ['valid' => false, 'error' => 'SVCB/HTTPS params must be valid JSON'];
                }
            }
        }
        
        return ['valid' => true, 'error' => null];
    }
    
    /**
     * Validate a DNAME record
     * 
     * @param string $value The DNAME target
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateDNAME($value) {
        if ($value === '' || $value === null) {
            return ['valid' => false, 'error' => 'DNAME record target cannot be empty'];
        }
        
        // Validate as DNS name
        return self::validateName($value, true);
    }
    
    /**
     * Validate a LOC record
     * 
     * @param array $data LOC record data
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateLOC($data) {
        // LOC records have complex format, basic validation only
        // Latitude (required)
        $lat = $data['loc_latitude'] ?? null;
        if ($lat === '' || $lat === null) {
            return ['valid' => false, 'error' => 'LOC latitude is required'];
        }
        
        // Longitude (required)
        $lon = $data['loc_longitude'] ?? null;
        if ($lon === '' || $lon === null) {
            return ['valid' => false, 'error' => 'LOC longitude is required'];
        }
        
        // Altitude (optional)
        
        return ['valid' => true, 'error' => null];
    }
    
    /**
     * Validate an RP record
     * 
     * @param array $data RP record data
     * @return array ['valid' => bool, 'error' => string|null]
     */
    public static function validateRP($data) {
        // Mailbox (required)
        $mbox = $data['rp_mbox'] ?? null;
        if ($mbox === '' || $mbox === null) {
            return ['valid' => false, 'error' => 'RP mailbox is required'];
        }
        
        // TXT domain (required)
        $txt = $data['rp_txt'] ?? null;
        if ($txt === '' || $txt === null) {
            return ['valid' => false, 'error' => 'RP TXT domain is required'];
        }
        
        return ['valid' => true, 'error' => null];
    }
    
    /**
     * Get the list of all supported record types
     * 
     * @return array Array of supported record type names
     */
    public static function getSupportedTypes() {
        return [
            // Pointing
            'A', 'AAAA', 'NS', 'CNAME', 'DNAME',
            // Extended
            'CAA', 'TXT', 'NAPTR', 'SRV', 'LOC', 'SSHFP', 'TLSA', 'RP', 'SVCB', 'HTTPS',
            // Mail
            'MX', 'SPF', 'DKIM', 'DMARC',
            // Other
            'PTR', 'SOA'
        ];
    }
    
    /**
     * Get record types organized by category
     * 
     * @return array Associative array of categories with their types
     */
    public static function getTypesByCategory() {
        return [
            'pointing' => [
                'A' => 'IPv4 address record',
                'AAAA' => 'IPv6 address record',
                'NS' => 'Name server record',
                'CNAME' => 'Canonical name (alias)',
                'DNAME' => 'Delegation name record'
            ],
            'extended' => [
                'CAA' => 'Certification Authority Authorization',
                'TXT' => 'Text record',
                'NAPTR' => 'Naming Authority Pointer',
                'SRV' => 'Service location record',
                'LOC' => 'Location record',
                'SSHFP' => 'SSH Fingerprint record',
                'TLSA' => 'DANE TLS Association',
                'RP' => 'Responsible Person',
                'SVCB' => 'Service Binding record',
                'HTTPS' => 'HTTPS Service Binding'
            ],
            'mail' => [
                'MX' => 'Mail exchange record',
                'SPF' => 'Sender Policy Framework',
                'DKIM' => 'DomainKeys Identified Mail',
                'DMARC' => 'Domain-based Message Authentication'
            ],
            'other' => [
                'PTR' => 'Pointer record (reverse DNS)',
                'SOA' => 'Start of Authority'
            ]
        ];
    }
}
?>
