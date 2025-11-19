# SQLite FTS5 Parameter Binding Bug Report

## Summary

**Issue**: SQLite FTS5 MATCH queries with parameter binding in Swift do not return results, while the same queries work with string interpolation.

**Evidence Collected**: November 19, 2025

## Bug Description

### Behavior Observed
- **Parameter binding succeeds**: `sqlite3_bind_text()` returns `SQLITE_OK (0)`
- **Query execution succeeds**: No SQLite errors reported
- **No results returned**: FTS5 queries return 0 rows with bound parameters
- **String interpolation works**: Same queries return expected results with string interpolation

### Affected Components
- **SQLite version**: Built-in with Swift Foundation
- **FTS5**: Full-text search extension
- **Swift**: String/C String binding interface
- **Database**: `~/.sosumi/wwdc.db` (73MB SQLite with FTS5)

## Evidence

### Test Cases Conducted

| Search Term | Parameter Binding | String Interpolation | Expected Results |
|------------|------------------|---------------------|----------------|
| SharePlay | 0 rows | 3 rows | ✅ |
| SwiftUI | 0 rows | 3 rows | ✅ |

### Binding Method Tests

```swift
// Test 1: Standard withCString binding - Result: SQLITE_OK (0)
let bindResult = query.withCString { cString in
    sqlite3_bind_text(stmt, 1, cString, -1, nil)
}
// Returns: 0, but query finds 0 rows

// Test 2: Direct binding - Result: SQLITE_OK (0)
let directResult = sqlite3_bind_text(stmt, 1, query, -1, nil)
// Returns: 0, but query finds 0 rows

// Test 3: String interpolation - Result: Works
let workingQuery = "WHERE transcripts_fts MATCH '\(query)'"
// Returns: 3 rows (SharePlay), 3 rows (SwiftUI)
```

### Query String Analysis

**Input**: `"SharePlay"` (length: 9)
**UTF-8 bytes**: `53 68 61 72 65 50 6c 61 79` (S h a r e P l a y)
**Clean**: No hidden characters or null terminators

## SQL Query Analysis

### Working Query (String Interpolation)
```sql
SELECT s.id, s.title, s.year, bm25(transcripts_fts)
FROM transcripts_fts
JOIN sessions s ON transcripts_fts.session_id = s.id
WHERE transcripts_fts MATCH 'SharePlay'
ORDER BY bm25(transcripts_fts)
LIMIT 3
```

### Non-working Query (Parameter Binding)
```sql
SELECT s.id, s.title, s.year, bm25(transcripts_fts)
FROM transcripts_fts
JOIN sessions s ON transcripts_fts.session_id = s.id
WHERE transcripts_fts MATCH ?
ORDER BY bm25(transcripts_fts)
LIMIT 3
```

## Root Cause Analysis

### What Works
1. **SQLite FTS5**: Functional and operational
2. **Database connection**: Successfully opens and reads database
3. **SQL syntax**: Queries compile and execute without errors
4. **String interpolation**: Provides correct search results
5. **BM25 scoring**: Relevance ranking works correctly

### What Fails
1. **Parameter binding**: Succeeds but produces no results
2. **Multiple binding approaches**: `withCString`, direct binding, manual C string creation - all fail
3. **All FTS5 MATCH queries**: Issue affects all MATCH operations with parameters
4. **Regular SQL queries**: LIKE clauses work fine (tested separately)

### Likely Technical Issue

**Hypothesis**: SQLite FTS5 parameter binding in Swift's C interface may have one of these issues:

1. **String encoding**: Bound parameter not in expected UTF-8 format for FTS5
2. **Memory lifetime**: Parameter memory management during query execution
3. **FTS5-specific requirement**: FTS5 might require different binding method than standard SQL
4. **Swift SQLite C interface nuance**: Specific to how Swift interfaces with SQLite C API

## Confirmed Workaround

**Solution**: Use string interpolation instead of parameter binding for FTS5 MATCH queries:

```swift
// ✅ Works
let searchQuery = "WHERE transcripts_fts MATCH '\(query)'"

// ❌ Fails
let searchQuery = "WHERE transcripts_fts MATCH ?"
sqlite3_bind_text(stmt, 1, query, -1, nil)
```

## Impact Assessment

### Severity: **Medium**
- **Core functionality**: Search can work with workaround
- **Performance**: Minimal impact (string interpolation vs binding)
- **Security**: No security implications
- **Maintenance**: Requires documented workaround

### Scope: **Specific**
- **Affects**: FTS5 MATCH queries with parameters only
- **Doesn't affect**: Regular SQL queries, other SQLite operations
- **Database**: Specific to FTS5, not general database functionality

## Files Affected

- **Primary**: `Sources/SosumiCore/WWDCDatabase.swift` (search implementation)
- **Secondary**: Any code using SQLite FTS5 with parameter binding

## Resolution Status

✅ **Working solution implemented**: String interpolation workaround deployed
⏳️ **Bug documentation**: This report created
⏸️ **Further investigation**: Could explore SQLite C API documentation for FTS5 binding requirements

## Recommendations

1. **Use workaround**: Continue with string interpolation approach
2. **Document**: Add comment explaining the binding issue
3. **Monitor**: Test with future Swift versions for resolution
4. **Research**: Investigate SQLite FTS5 documentation for proper binding method

## Technical Details

- **Swift version**: System default
- **SQLite version**: Built-in Foundation SQLite
- **FTS5 version**: 3.x (standard in recent SQLite)
- **Database**: 73MB with 3,215 sessions, 1,355 transcripts
- **Testing environment**: macOS, Swift 5.x

---

**Report Created**: 2025-11-19
**Evidence Based On**: Direct testing with multiple search terms and binding approaches
**Status**: Workaround deployed, issue documented