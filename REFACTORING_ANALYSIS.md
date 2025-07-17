# JavaScript Implementation Differences Analysis

## Critical Finding: NO FUNCTIONS ARE SAFELY EXTRACTABLE YET

This analysis reveals that even seemingly identical utility functions have important differences that must be preserved.

## evaluateExpression Function Differences

### Files with Full Implementation:
- `mapboxgl.js`: Full implementation with number-format support
- `maplibregl.js`: Full implementation with number-format support  
- `mapboxgl_compare.js`: Full implementation with number-format support

### maplibregl_compare.js: DUAL IMPLEMENTATION
- **Line 1**: Full implementation (identical to others)
- **Line ~2800**: Simplified implementation (only get, concat, to-string, to-number)

### Code Style Differences:
- **maplibregl_compare.js**: Uses single quotes, different indentation
- **Others**: Use double quotes, consistent indentation

### Functional Differences:
- **Simplified version**: Missing `number-format` case - could break number formatting
- **Context**: Simplified version appears in different widget initialization context

## Key Insights for Refactoring

### 1. ZERO SAFE EXTRACTIONS FOUND
Even the most basic utility functions have:
- Different code styles
- Different feature sets
- Different contexts of usage
- Potential version conflicts within same file

### 2. Risk Assessment: EXTREMELY HIGH
- Any extraction could break subtle functionality
- Compare files have different requirements
- Code style differences suggest intentional variations
- Duplicate implementations in same file indicates complex context needs

### 3. Recommended Approach: 
**ABANDON UTILITY EXTRACTION** - The differences are too significant and risky.

## Alternative Strategies

### 1. Focus on Architecture Pattern Abstraction
Instead of function extraction, focus on:
- Clean up code organization within each file
- Standardize coding patterns without sharing code
- Improve documentation and comments

### 2. Engine Namespace Abstraction
Create minimal abstraction for:
```javascript
const MapEngine = engine === 'mapbox' ? mapboxgl : maplibregl;
```
But keep ALL implementation separate.

### 3. Documentation-First Approach
- Document all differences thoroughly
- Create decision matrix for each function
- Mark functions as "never extract" vs "potential future extraction"

## Conclusion

The JavaScript implementations have evolved separately for good reasons. Each has context-specific optimizations, workarounds, and features that must be preserved exactly as-is.

**RECOMMENDATION: Do not extract any utility functions. Focus on organizational improvements within each file instead.**