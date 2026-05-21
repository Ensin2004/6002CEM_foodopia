# 🍽️ Smart Meal & Recipe Assistant — Developer Guide
# 📑 Table of Contents

1. [1.0 Overview](#10-overview)
2. [2.0 Architecture Overview](#20-architecture-overview)
3. [3.0 Project Structure](#30-project-structure)
4. [4.0 Core Layer (core/)](#40-core-layer-core)
    - [4.1 auth/](#41-coreauth)
    - [4.2 config/](#42-coreconfig)
    - [4.3 error/](#43-coreerror)
    - [4.4 extensions/](#44-coreextensions)
    - [4.5 services/](#45-coreservices)
    - [4.6 theme/](#46-coretheme)
    - [4.7 utils/](#47-coreutils)
    - [4.8 widgets/](#48-corewidgets)
5. [5.0 App Layer (app/)](#50-app-layer-app)
    - [5.1 dependency_injection/](#51-appdependency_injection)
    - [5.2 navigation/](#52-appnavigation)
    - [5.3 routers/](#53-approuters)
    - [5.4 app.dart](#54-appdart)
6. [6.0 Entry Point (main.dart)](#60-entry-point-maindart)
7. [7.0 Features Layer (features/)](#70-features-layer-features)
    - [7.1 Feature Structure](#71-feature-structure)
    - [7.2 domain/](#72-domain--business-logic)
    - [7.3 data/](#73-data--data-handling)
    - [7.4 presentation/](#74-presentation--ui-layer)
    - [7.5 Role Separation](#75-role-separation)
8. [8.0 Feature Naming Rules](#80-feature-naming-rules)
9. [9.0 System Modules Mapping](#90-system-modules-mapping)
10. [10.0 Data Flow (MVVM)](#100-data-flow-mvvm)
11. [11.0 Development Rules](#110-development-rules)
12. [12.0 Team Collaboration Guidelines](#120-team-collaboration-guidelines)
13. [13.0 Future Scalability](#130-future-scalability)
14. [14.0 Summary](#140-summary)
15. [15.0 Final Note](#150-final-note)
---

# 1.0 Overview

## 📌 Overview

This project is a **Smart Meal & Recipe Assistant mobile application** built using **Flutter**, following **MVVM (Model-View-ViewModel)** and **Clean Architecture** principles.

The system aims to:

* Help users decide what to cook
* Generate recipes based on available ingredients (AI-based)
* Provide personalized recommendations
* Support meal planning and grocery list generation
* Reduce food waste

---

# 2.0 Architecture Overview

## 🧠 Architecture Overview

This project follows **Clean Architecture**, divided into 3 main layers:

```plaintext
Presentation Layer  → UI + ViewModels
Domain Layer        → Business logic (Use Cases, Entities)
Data Layer          → API, Database, Repositories
```

Additionally, we use:

* `core/` → reusable utilities across the app
* `app/` → app-level configuration (routing, DI, theme setup)
* `features/` → main business modules

---

# 3.0 Project Structure

## 🗂️ Project Structure

```plaintext
lib/
|-- app/
|   |-- app.dart
|   |-- dependency_injection/
|   |-- navigation/
|   `-- routers/
|-- core/
|   |-- auth/
|   |-- config/
|   |-- error/
|   |-- extensions/
|   |-- services/
|   |-- theme/
|   |-- utils/
|   `-- widgets/
|-- features/
`-- main.dart
```

---

# 4.0 Core Layer (`core/`)

## 📌 Purpose

Contains **generic, reusable components** used across multiple features.

⚠️ Rule:

* No business logic here
* No feature-specific code

---

## 4.1 `core/auth/`

### Purpose:

Store reusable authentication and authorization helpers that are not tied to one screen.

### Current files:

```plaintext
auth/
  role_constant.dart
  role_manager.dart
```

### Responsibilities:

* Keep role names in one shared place
* Provide helper logic for checking user roles
* Prevent role strings from being duplicated across features

### Example usage:

```dart
final isAdmin = RoleManager.isAdmin(user.role);
```

### Rule:

Only shared auth or role logic belongs here. Login, signup, and Firebase auth workflows stay inside `features/auth/`.

---

## 4.2 `core/config/`

### Purpose:

Store global application configuration.

### Current file:

```plaintext
config/
  env_config.dart
```

### Responsibilities:

* Keep environment-related values in one place
* Avoid scattering configuration values inside UI or ViewModels
* Make future development, staging, or production configuration easier to manage

### Example:

```dart
final cloudName = EnvConfig.cloudinaryCloudName;
```

---

## 4.3 `core/error/`

### Purpose:

Define shared error objects used across repositories, use cases, and ViewModels.

### Current file:

```plaintext
error/
  failures.dart
```

### Responsibilities:

* Standardize app-level failures
* Keep repository error handling consistent
* Make UI error messages easier to map from domain or data results

### Example:

```dart
return Left(ServerFailure('Unable to load data'));
```

---

## 4.4 `core/extensions/`

### Purpose:

Provide reusable Dart extensions that make common patterns cleaner.

### Current file:

```plaintext
extensions/
  either_extensions.dart
```

### Responsibilities:

* Add helper methods to existing types
* Reduce repeated boilerplate when handling `Either`
* Keep syntax improvements shared across features

### Rule:

Extensions should stay generic. If an extension only helps one feature, place it inside that feature instead.

---

## 4.5 `core/services/`

### Purpose:

Store reusable services used by multiple features.

### Current files:

```plaintext
services/
  cloudinary_service.dart
  network_info.dart
  shared_prefs_manager.dart
```

### Responsibilities:

* `cloudinary_service.dart` handles shared image upload support
* `network_info.dart` checks connectivity before network operations
* `shared_prefs_manager.dart` stores simple local app flags such as onboarding completion

### Example:

```dart
final hasConnection = await networkInfo.isConnected;
await SharedPrefsManager.setOnboardingCompleted(true);
```

### Rule:

Services placed here must be reusable across features. Feature-specific remote data sources still belong inside `features/<feature_name>/data/datasources/`.

---

## 4.6 `core/theme/`

### Purpose:

Define the UI design system for Foodopia.

### Current files:

```plaintext
theme/
  app_colors.dart
  app_theme.dart
  theme_extension.dart
```

### Responsibilities:

* `app_colors.dart` stores shared color values
* `app_theme.dart` configures the Flutter `ThemeData`
* `theme_extension.dart` provides convenient access to theme colors and text styles from `BuildContext`

### Example:

```dart
Text(
  'Foodopia',
  style: context.text.titleLarge,
)
```

---

## 4.7 `core/utils/`

### Purpose:

Provide small reusable helper utilities.

### Current file:

```plaintext
utils/
  firebase_config_checker.dart
```

### Responsibilities:

* Keep one-off shared checks out of UI code
* Support app startup or development diagnostics
* Avoid repeating utility logic in multiple features

### Rule:

Do not use `utils/` as a dumping ground. Prefer a named folder such as `services/`, `extensions/`, `auth/`, or `config/` when the purpose is clear.

---

## 4.8 `core/widgets/`

### Purpose:

Store reusable UI components used across multiple features.

### Current structure:

```plaintext
widgets/
  custom_app_bar.dart
  buttons/
    primary_button.dart
    secondary_button.dart
  dialogs/
    loading_dialog.dart
```

### Responsibilities:

* Keep shared buttons, dialogs, and app bars consistent
* Reduce repeated UI code across feature screens
* Provide common components that match the Foodopia theme

### Rule:

* If a widget is feature-specific -> put it inside that feature
* If a widget is reusable across multiple features -> put it inside `core/widgets/`

---

# 5.0 App Layer (`app/`)

## 📌 Purpose

Handles **how the app is wired together**

⚠️ Rule:

* No business logic here
* Only configuration

---

## 5.1 `app/dependency_injection/`

### Purpose:

Manage dependencies using GetIt.

### Responsibilities:

* Register Firebase and external services
* Register remote data sources
* Register repository implementations
* Register use cases
* Register ViewModels used by presentation screens

### Current file:

```plaintext
dependency_injection/
  injection_container.dart
```

### Why this matters:

Dependency injection keeps object creation out of UI classes. Screens can request a ViewModel, and the ViewModel can receive its use cases or repositories without manually constructing every dependency in the widget tree.

### Example:

```dart
final sl = GetIt.instance;

Future<void> init() async {
  sl.registerFactory(() => LoginViewModel(loginUseCase: sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
}
```

---

## 5.2 `app/navigation/`

### Purpose:

Define type-safe navigation events emitted by ViewModels.

### Current file:

```plaintext
navigation/
  navigation_events.dart
```

### Responsibilities:

* Keep navigation intent separate from actual navigation execution
* Allow ViewModels to request navigation without depending directly on `BuildContext`
* Group events by feature, such as auth, onboarding, main, and settings

### Example:

```dart
enum OnboardingNavigationEvent {
  goToLogin,
  goToSignup,
}
```

### Why this matters:

ViewModels should manage state and emit events. The UI listens for those events and performs `context.go(...)`. This keeps the presentation logic testable and avoids putting Flutter navigation code inside the ViewModel.

---

## 5.3 `app/routers/`

### Purpose:

Centralized app routing using GoRouter.

### Responsibilities:

* Define route paths and names
* Choose the initial screen based on onboarding and login status
* Redirect users away from screens they should not access
* Pass typed route arguments to pages that need extra data

### Current files:

```plaintext
routers/
  app_router.dart
  router_args.dart
```

### Important behavior:

* If onboarding has not been completed, the user is sent to `/onboarding`
* If the user is not logged in, protected routes redirect to `/login`
* If the user is logged in, auth pages redirect to `/home`
* Pages such as settings, about, FAQ, help center, and image preview receive typed argument objects from `router_args.dart`

### Example:

```dart
routerConfig: AppRouter.createRouter(
  seenOnboarding: seenOnboarding,
  isLoggedIn: isLoggedIn,
  user: userEntity,
)
```

---

## 5.4 `app/app.dart`

### Purpose:

Root widget of the application

### Responsibilities:

* Create `MaterialApp.router`
* Hide the debug banner
* Apply `AppTheme.lightTheme`
* Build the router using the current onboarding, login, and user state

### Example:

```dart
class App extends StatelessWidget {
  final bool seenOnboarding;
  final bool isLoggedIn;
  final UserEntity? userEntity;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Foodopia',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.createRouter(
        seenOnboarding: seenOnboarding,
        isLoggedIn: isLoggedIn,
        user: userEntity,
      ),
    );
  }
}
```

---

# 6.0 Entry Point (`main.dart`)

## 🚀 Purpose:

Start the application

### Responsibilities:

* Initialize Flutter bindings
* Initialize Firebase
* Setup dependency injection using `initDependencies()`
* Initialize `SharedPrefsManager`
* Check whether onboarding has been completed
* Check whether the Firebase user is logged in and email verified
* Load the user document from Firestore
* Launch `App` with onboarding, login, and user state

### Example:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await initDependencies();
  await SharedPrefsManager.init();

  final seenOnboarding = SharedPrefsManager.hasCompletedOnboarding();
  final currentUser = FirebaseAuth.instance.currentUser;
  UserEntity? userEntity;
  // Load userEntity from Firestore when currentUser is verified.
  final isLoggedIn = currentUser != null &&
      currentUser.emailVerified &&
      userEntity != null;

  runApp(App(
    seenOnboarding: seenOnboarding,
    isLoggedIn: isLoggedIn,
    userEntity: userEntity,
  ));
}
```

---

# 7.0 Features Layer (`features/`)

## 📌 Purpose

Each folder represents **one feature of the system**

---

## 7.1 Feature Structure

Features in this project follow Clean Architecture, but are implemented using a progressive approach based on complexity.

### Simple Features (Presentation-First)
For features with minimal logic (e.g. onboarding, static pages), use:

```plaintext
feature_name/
  |-- domain/
  |   `-- entities/
  `-- presentation/
      |-- view/
      |-- viewmodel/
      `-- widgets/
```

### Current examples:

```plaintext
onboarding/
home/
explore/
library/
manage/
meal_plan/
notifications/
statistics/
```

### Reason:

Simple features do not need every Clean Architecture folder immediately. For example, onboarding only needs an entity plus presentation files, because it does not currently call an API or contain complex domain rules.

---

### Complex Features (Full Clean Architecture)
For features involving API, business logic, or scalability, use:

```plaintext
feature_name/
  |-- data/
  |   |-- datasources/
  |   |-- models/
  |   `-- repositories/
  |-- domain/
  |   |-- entities/
  |   |-- repositories/
  |   `-- usecases/
  `-- presentation/
      |-- view/
      |-- viewmodel/
      `-- widgets/
```

### Current examples:

```plaintext
auth/
settings/
recipe/
main/
```

### Reason:

Complex features usually need API calls, repository contracts, data models, and use cases. Keeping these layers separate prevents UI code from directly depending on Firebase, Cloudinary, or other implementation details.

---

### Important Rule:

Clean Architecture should be applied progressively, not strictly.

* Start simple -> expand when needed
* Do NOT create unnecessary layers for simple features
* Add `data/` only when the feature needs remote/local data handling
* Add `domain/usecases/` when the feature has business rules worth separating from the ViewModel
* Keep feature-specific widgets inside `features/<feature_name>/presentation/widgets/`

---

## 7.2 `domain/` — Business Logic

### Contains:

* Entities (core models)
* Use cases (business rules)
* Repository interfaces

### Example:

```plaintext
domain/
  entities/
  usecases/
  repositories/
```

---

## 7.3 `data/` — Data Handling

### Contains:

* Repository implementations
* API calls
* Data models (DTOs)

---

## 7.4 `presentation/` — UI Layer

### Contains:

* Screens (UI)
* ViewModels (state management)

---

## 7.5 Role Separation

Inside `presentation/`, roles are separated:

```plaintext
presentation/
  user/
  admin/
```

### Why?

* UI differs between roles
* Business logic remains shared

---

# 8.0 Feature Naming Rules

## ✅ Shared Features (default)

```plaintext
recipe/
meal_plan/
grocery/
ai_recipe/
recommendation/
```

## ✅ Admin-only Features

```plaintext
admin_dashboard/
admin_user_management/
```

## ⚠️ Rules

* Do NOT duplicate features by role
* Do NOT use:

  ```
  user_recipe/
  admin_recipe/
  ```

---

# 9.0 System Modules Mapping

## 👤 User Features

* Recipe browsing
* Meal planning
* Grocery list generation
* AI recipe generation
* Recommendations

## 🛠️ Admin Features

* Manage users
* Manage recipes
* Monitor system usage

---

# 10.0 Data Flow (MVVM)

```plaintext
UI (View)
   ↓
ViewModel
   ↓
Use Case
   ↓
Repository
   ↓
Data Source (API/DB)
```

---

# 11.0 Development Rules

These rules are the checklist every team member should follow when adding or modifying a feature.

## 11.1 Feature Ownership and Structure

Use **MVVM with Clean Architecture**. Each feature must be feature-specific and live inside `features/`.

For example, `add_recipe` should be one feature folder:

```plaintext
features/
  add_recipe/
    data/
      datasources/
      models/
      repositories/
    domain/
      entities/
      repositories/
      usecases/
    presentation/
      view/
      viewmodel/
      widgets/
```

For smaller features, follow the progressive approach in Section 7.1. Do not create unnecessary `data/` or `usecases/` folders if the feature is only static UI.

---

## 11.2 Core Reuse Rules

Always reuse shared `core/` utilities before creating new ones.

| Need | Use |
| ---- | --- |
| Loading UI | `core/widgets/dialogs/loading_dialog.dart` |
| Shared error handling | `core/error/failures.dart` |
| Either helpers | `core/extensions/either_extensions.dart` |
| App theme and text styles | `core/theme/app_theme.dart` and `core/theme/theme_extension.dart` |
| Empty state image | `assets/images/empty_page.png` |

Rules:

* Do not create a new loading dialog inside a feature.
* Do not create new failure classes inside a feature unless they truly belong only to that feature.
* Use existing theme styles instead of hardcoding repeated text styles.
* Use `empty_page.png` for empty pages or empty list states.

---

## 11.3 App Layer Updates

When adding a new page, update the app layer properly:

* Register new dependencies in `app/dependency_injection/injection_container.dart`
* Add navigation events in `app/navigation/navigation_events.dart` when the ViewModel needs to request navigation
* Add route paths and route builders in `app/routers/app_router.dart`
* Add route argument classes in `app/routers/router_args.dart` when the page needs typed data

---

## 11.4 ViewModel Rules

ViewModels should manage state and call use cases. They should not directly access Flutter UI APIs.

Do NOT put these inside ViewModels:

* `BuildContext`
* `context.read` / `context.watch`
* `Navigator`
* `showDialog`
* `ScaffoldMessenger`
* `Theme.of`
* `MediaQuery`
* `TextEditingController`
* `PageController`
* `ScrollController`
* `FocusNode`
* `AnimationController`
* `material.dart`
* `HapticFeedback`
* `ImagePicker`
* Dialogs, snackbars, or navigation execution using `context`
* Timers used only for UI animation or autoplay

Preferred rule:

* Temporary selected files/images should usually stay in the View.
* The ViewModel may receive a `File` as a method parameter when saving or uploading.
* Existing simple ViewModel presentation state does not need risky refactoring unless it causes UI coupling, testing problems, or repeated bugs.

Example:

```dart
// View
final pickedFile = await picker.pickImage(source: ImageSource.gallery);
if (pickedFile != null) {
  await viewModel.saveImageOnly(File(pickedFile.path));
}

// ViewModel
Future<bool> saveImageOnly(File imageFile) async {
  return await updateProfileImageUseCase.execute(
    uid: uid,
    imageFile: imageFile,
  );
}
```

---

## 11.5 Navigation Rules

Use **GoRouter** for navigation.

Do NOT use:

* `MaterialPageRoute`
* Page-level `Navigator.push`
* Router or navigation calls inside ViewModels

Correct flow:

```plaintext
ViewModel emits navigation event
View listens to the event
View calls context.go(...) or context.push(...)
GoRouter resolves the page from app_router.dart
```

Example:

```dart
// ViewModel
_navigationEvent = SettingsNavigationEvent.goToEditProfile;
notifyListeners();

// View
if (event == SettingsNavigationEvent.goToEditProfile) {
  context.push(AppRouter.editProfile, extra: EditProfileArgs(uid: uid));
}
```

---

## 11.6 Do Not

* Put business logic in `core/`
* Put feature logic in `app/`
* Duplicate features for admin/user
* Put API or Firebase calls directly inside Views
* Put UI-only effects inside ViewModels

## 11.7 Always

* Keep features independent
* Share domain logic
* Separate UI by role only
* Apply Clean Architecture progressively based on feature complexity
* Keep reusable UI in `core/widgets/`
* Keep feature-specific UI in `features/<feature_name>/presentation/widgets/`
* Keep route setup centralized in `app/routers/`

---

# 12.0 Team Collaboration Guidelines

## Feature Ownership

Each team member should:

* Own 1–2 features
* Work only inside assigned feature folders

## Code Consistency

* Follow naming conventions
* Keep folder structure consistent
* Reuse components from `core/`

---

# 13.0 Future Scalability

This architecture supports:

* Adding AI modules easily
* Scaling features independently
* Supporting more roles (e.g. nutritionist)

---

# 14.0 Summary

| Folder      | Responsibility |
| ----------- | -------------- |
| `core/`     | reusable tools |
| `app/`      | configuration  |
| `features/` | business logic |
| `main.dart` | app entry      |

---

# 15.0 Final Note

This structure is designed to:

* Reduce confusion
* Improve scalability
* Support team collaboration
* Maintain clean and modular code

---

If you are unsure where to place something:
👉 Ask: *“Is this reusable, configuration, or feature logic?”*

---
