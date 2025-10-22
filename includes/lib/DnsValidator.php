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
     * @param string $recordType The record type (A, AAAA, MX, CNAME, TXT)
     * @param string $owner The record owner/name
     * @param string $value The record value (rdata)
     * @param array $extraData Additional data (e.g., priority for MX)
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
                
            default:
                return ['valid' => false, 'error' => "Unsupported record type: $recordType"];
        }
    }
}
?>
