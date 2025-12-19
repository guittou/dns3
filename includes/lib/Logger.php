<?php
/**
 * Logger Utility
 * Provides lightweight logging with configurable output path
 * 
 * Features:
 * - Log levels: DEBUG, INFO, WARN, ERROR
 * - Configurable log file path via APP_LOG_PATH config
 * - Configurable log level via APP_LOG_LEVEL (DEBUG or INFO)
 * - Falls back to PHP error_log if APP_LOG_PATH is not set
 * - JSON context serialization for structured data
 * - Consistent log format: [dns3][LEVEL][module] message {context}
 * - No sensitive data logging (passwords, tokens, etc.)
 */

class Logger {
    private const LEVEL_DEBUG = 'DEBUG';
    private const LEVEL_INFO = 'INFO';
    private const LEVEL_WARN = 'WARN';
    private const LEVEL_ERROR = 'ERROR';
    
    // Level hierarchy (higher number = more important)
    private const LEVEL_PRIORITY = [
        'DEBUG' => 1,
        'INFO' => 2,
        'WARN' => 3,
        'ERROR' => 4
    ];
    
    /**
     * Log a debug message (only logged if APP_LOG_LEVEL is DEBUG)
     * Use for verbose logging that may generate high volume
     * 
     * @param string $module Module name (e.g., 'auth', 'acl', 'api')
     * @param string $message Log message
     * @param array $context Additional context data (will be JSON encoded)
     */
    public static function debug($module, $message, $context = []) {
        self::log(self::LEVEL_DEBUG, $module, $message, $context);
    }
    
    /**
     * Log an info message
     * 
     * @param string $module Module name (e.g., 'auth', 'acl', 'api')
     * @param string $message Log message
     * @param array $context Additional context data (will be JSON encoded)
     */
    public static function info($module, $message, $context = []) {
        self::log(self::LEVEL_INFO, $module, $message, $context);
    }
    
    /**
     * Log a warning message
     * 
     * @param string $module Module name (e.g., 'auth', 'acl', 'api')
     * @param string $message Log message
     * @param array $context Additional context data (will be JSON encoded)
     */
    public static function warn($module, $message, $context = []) {
        self::log(self::LEVEL_WARN, $module, $message, $context);
    }
    
    /**
     * Log an error message
     * 
     * @param string $module Module name (e.g., 'auth', 'acl', 'api')
     * @param string $message Log message
     * @param array $context Additional context data (will be JSON encoded)
     */
    public static function error($module, $message, $context = []) {
        self::log(self::LEVEL_ERROR, $module, $message, $context);
    }
    
    /**
     * Core logging method
     * 
     * @param string $level Log level (DEBUG, INFO, WARN, ERROR)
     * @param string $module Module name
     * @param string $message Log message
     * @param array $context Additional context data
     */
    private static function log($level, $module, $message, $context = []) {
        // Check if this log level should be recorded
        $configLevel = defined('APP_LOG_LEVEL') ? APP_LOG_LEVEL : 'INFO';
        $configPriority = self::LEVEL_PRIORITY[$configLevel] ?? self::LEVEL_PRIORITY['INFO'];
        $messagePriority = self::LEVEL_PRIORITY[$level] ?? self::LEVEL_PRIORITY['INFO'];
        
        // Skip if message priority is lower than configured level
        if ($messagePriority < $configPriority) {
            return;
        }
        
        // Build log entry
        $timestamp = date('Y-m-d H:i:s');
        $prefix = "[dns3][$level][$module]";
        
        // Sanitize context to remove sensitive data
        $sanitizedContext = self::sanitizeContext($context);
        
        // Format context as JSON if present
        $contextStr = '';
        if (!empty($sanitizedContext)) {
            $contextJson = json_encode($sanitizedContext, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
            if ($contextJson !== false) {
                $contextStr = ' ' . $contextJson;
            }
        }
        
        // Build final log message
        $logMessage = "$timestamp $prefix $message$contextStr";
        
        // Determine log destination
        $logPath = defined('APP_LOG_PATH') ? APP_LOG_PATH : null;
        
        if ($logPath && is_string($logPath) && $logPath !== '') {
            // Log to custom file
            self::writeToFile($logPath, $logMessage);
        } else {
            // Fall back to PHP error_log
            error_log($logMessage);
        }
    }
    
    /**
     * Sanitize context to remove sensitive data
     * 
     * @param array $context Original context
     * @return array Sanitized context
     */
    private static function sanitizeContext($context) {
        if (empty($context) || !is_array($context)) {
            return $context;
        }
        
        $sanitized = [];
        $sensitiveKeys = ['password', 'passwd', 'pwd', 'token', 'secret', 'api_key', 'apikey'];
        
        foreach ($context as $key => $value) {
            $lowerKey = strtolower($key);
            
            // Remove sensitive keys
            $isSensitive = false;
            foreach ($sensitiveKeys as $sensitiveKey) {
                if (strpos($lowerKey, $sensitiveKey) !== false) {
                    $isSensitive = true;
                    break;
                }
            }
            
            if ($isSensitive) {
                $sanitized[$key] = '[REDACTED]';
            } elseif (is_array($value)) {
                // Recursively sanitize nested arrays
                $sanitized[$key] = self::sanitizeContext($value);
            } else {
                $sanitized[$key] = $value;
            }
        }
        
        return $sanitized;
    }
    
    /**
     * Write log message to file
     * 
     * @param string $path Log file path
     * @param string $message Log message
     */
    private static function writeToFile($path, $message) {
        // Ensure message ends with newline
        if (substr($message, -1) !== "\n") {
            $message .= "\n";
        }
        
        // Attempt to write to file
        // Use @ to suppress warnings if file is not writable
        $result = @file_put_contents($path, $message, FILE_APPEND | LOCK_EX);
        
        // If writing failed, fall back to error_log
        if ($result === false) {
            error_log("Logger: Failed to write to log file '$path'. Message: $message");
        }
    }
}
?>
