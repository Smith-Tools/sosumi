# sosumi Development Workflow

sosumi is the Apple documentation and WWDC session search tool. When implementing features that need Apple framework guidance.

## Context Gathering Workflow

### 1. Understand Your Project

Before searching Apple documentation, understand what you're building:

```bash
smith dependencies /path/to/your-project
```

This helps you know:
- Which Apple frameworks matter (SwiftUI, Combine, etc.)
- What versions you're targeting
- What you've already imported

### 2. Search Apple Framework Documentation

When you need official Apple guidance:

```bash
sosumi docs <framework>
```

Examples:
- `sosumi docs SwiftUI` - UI framework reference
- `sosumi docs Combine` - Reactive programming
- `sosumi docs Core Data` - Persistence
- `sosumi docs AVFoundation` - Media handling
- `sosumi docs NavigationStack` - Navigation patterns

### 3. Search WWDC Sessions

When you need Apple engineering talks and best practices:

```bash
sosumi wwdc <topic>
```

Examples:
- `sosumi wwdc state management` - TCA and SwiftUI state
- `sosumi wwdc performance` - Optimization guidance
- `sosumi wwdc testing` - Testing best practices
- `sosumi wwdc accessibility` - Accessibility patterns
- `sosumi wwdc async await` - Concurrency patterns

### 4. Cross-Reference with Personal Knowledge

The maxwell skill auto-triggers to show:
- Past implementations using the framework
- Personal patterns and learnings
- How you've solved similar problems

## Example: Implement NavigationStack

Task: "Add NavigationStack-based navigation"

```
Step 1: smith dependencies
   → Understand current navigation approach
   → See what SwiftUI versions are available

Step 2: sosumi docs NavigationStack
   → Get Apple API reference
   → See example usage patterns

Step 3: sosumi wwdc state management
   → See how Apple recommends state handling
   → Learn modern SwiftUI navigation patterns

Step 4: maxwell skill
   → Search: "NavigationStack patterns"
   → Get past implementations

Step 5: Implement
   → Follow Apple API documentation
   → Use WWDC best practices
   → Reference past patterns
```

## Example: Optimize Performance

Task: "Reduce memory usage in list rendering"

```
Step 1: smith dependencies
   → See what frameworks you use
   → Identify performance-critical code

Step 2: sosumi wwdc performance
   → Get optimization best practices
   → Learn memory management patterns

Step 3: sosumi docs SwiftUI
   → See specific API recommendations
   → Find memoization techniques

Step 4: Implement optimization
   → Apply Apple-recommended patterns
```

## Quick Reference

| Need | Command |
|------|---------|
| Framework API | `sosumi docs <framework>` |
| Apple talks | `sosumi wwdc <topic>` |
| Update cache | `sosumi refresh` |

## Key Principles

✅ **Use official guidance**: Apple docs are authoritative
✅ **Cross-reference WWDC**: Engineering talks explain the "why"
✅ **Check your project context**: smith shows what matters for you
✅ **Combine with personal knowledge**: maxwell shows what you've learned

## Integration with Smith Tools

When you need complete context:

1. `smith dependencies` → Understand your project
2. `sosumi docs <framework>` → Get API documentation
3. `sosumi wwdc <topic>` → Get engineering guidance
4. maxwell skill → See past implementations

## Documentation

For the complete integration architecture, see:
**Smith-Tools/AGENT-INTEGRATION.md**
