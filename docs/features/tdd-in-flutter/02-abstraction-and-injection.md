# Abstraction and dependency injection for testability

## The pattern

1. The consumer (use case, cubit, widget) depends on an **abstract class** describing what it needs.
2. The concrete implementation (HTTP, Firebase, socket, storage) `implements` it and lives in `data/`.
3. Dependencies arrive through the **constructor**. The class never builds them, and never looks them up through a global or `BuildContext`.
4. In a test, a hand-written **fake** implements the same abstract class.

```dart
abstract class UserRepository {
  Future<UserEntity> getUser(String id);
}

class GetUserProfile {
  const GetUserProfile(this._repository);
  final UserRepository _repository;

  Future<UserEntity> call(String id) => _repository.getUser(id);
}

class FakeUserRepository implements UserRepository {
  UserEntity result = testUser;
  final List<String> requestedIds = <String>[];

  @override
  Future<UserEntity> getUser(String id) async {
    requestedIds.add(id);
    return result;
  }
}
```

In Dart every class has an implicit interface, so an `abstract class` is a deliberate contract, not a requirement of the language. Create one where it pays off, below.

## Where to put an abstraction

| Boundary | Abstract it? | Why |
|---|---|---|
| Repository (domain → data) | Yes | The main seam: use cases and cubits are tested without network or DB |
| Data source / API client / socket service | Yes | Repositories are tested with a fake client |
| Platform and plugin access (storage, camera, permissions, analytics) | Yes | Cannot run in unit tests |
| Clock, ID generator, random | Yes (a small function type is enough) | Removes wall-clock and randomness from tests |
| Pure functions, mappers, entities, value objects | No | Test the real thing |
| A class with one implementation and no I/O | No | An interface adds nothing |

## Rules of thumb

- **Define the interface from the consumer's need.** Ask what the use case must call, not what the API offers. Keep it small; split a wide interface rather than faking twenty methods.
- **One seam per I/O boundary**, not one per class.
- **No singletons or `static` state in code under test.** A hard-wired singleton is the usual reason legacy code can't be tested. Add the smallest seam (a constructor parameter with the real thing wired at the composition root), and ask before refactoring a legacy file only for testability.
- **No default parameter that builds a concrete data class**; it hides the dependency and defeats injection (matches `dart-core.md`).
- **Widgets receive their cubit or dependencies from above** (constructor or `BlocProvider`), so a test can supply a fake or a seeded cubit.
- **Bloc/Cubit state needs value equality** (`==`/`hashCode` or `equatable`), otherwise state-sequence assertions are unreliable.

## Source scope

- Andrea Bizzotto, "Take your Flutter tests to the next level with abstract classes and dependency injection"
- Flutter docs, architecture case study: testing
