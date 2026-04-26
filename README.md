````# 🍽️ Smart Meal & Recipe Assistant — Developer Guide

---

# 📑 Table of Contents

1. [1.0 Overview](#10-overview)
2. [2.0 Architecture Overview](#20-architecture-overview)
3. [3.0 Project Structure](#30-project-structure)
4. [4.0 Core Layer (core/)](#40-core-layer-core)
    - [4.1 constants/](#41-coreconstants)
    - [4.2 network/](#42-corenetwork)
    - [4.3 theme/](#43-coretheme)
    - [4.4 utils/](#44-coreutils)
    - [4.5 widgets/](#45-corewidgets)
5. [5.0 App Layer (app/)](#50-app-layer-app)
    - [5.1 dependency_injection/](#51-appdependency_injection)
    - [5.2 routers/](#52-approuters)
    - [5.3 app.dart](#53-appdart)
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
├── core/
├── features/
├── app/
├── main.dart
```

---

# 4.0 Core Layer (`core/`)

## 📌 Purpose

Contains **generic, reusable components** used across multiple features.

⚠️ Rule:

* No business logic here
* No feature-specific code

---

## 4.1 `core/constants/`

### Purpose:

Store **fixed values used globally**

### Examples:

* App name
* API base URL
* Default limits
* Static keys

### Example:

```dart
class AppConstants {
  static const String appName = "Smart Meal Assistant";
  static const int maxRecipeResults = 20;
}
```

---

## 4.2 `core/network/`

### Purpose:

Handle **all API communication**

### Responsibilities:

* HTTP client setup (e.g. Dio)
* API endpoints
* Request/response handling
* Interceptors (logging, auth token)
* Error handling

### Example Structure:

```plaintext
network/
  api_client.dart
  api_endpoints.dart
  network_exception.dart
```

---

## 4.3 `core/theme/`

### Purpose:

Define the **UI design system**

### Responsibilities:

* Colors
* Typography
* Light/Dark themes

### Example:

```plaintext
theme/
  app_colors.dart
  app_text_styles.dart
  app_theme.dart
```

---

## 4.4 `core/utils/`

### Purpose:

Provide **helper functions**

### Examples:

* Date formatting
* Input validation
* String formatting

### Example:

```dart
String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}
```

---

## 4.5 `core/widgets/`

### Purpose:

Reusable UI components used across multiple features

### Examples:

* CustomButton
* LoadingIndicator
* ErrorDialog

⚠️ Rule:

* If widget is feature-specific → put inside that feature
* If reusable → put here

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

Manage dependencies using DI (e.g. GetIt)

### Responsibilities:

* Register services
* Register repositories
* Register ViewModels

### Example:

```dart
final getIt = GetIt.instance;

void setupDI() {
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  getIt.registerFactory<RecipeViewModel>(() => RecipeViewModel());
}
```

---

## 5.2 `app/routers/`

### Purpose:

Centralized navigation system

### Responsibilities:

* Define routes
* Handle navigation
* Apply route guards (e.g. auth check)

### Example:

```plaintext
routers/
  app_router.dart
  route_names.dart
```

---

## 5.3 `app/app.dart`

### Purpose:

Root widget of the application

### Responsibilities:

* Initialize MaterialApp
* Apply theme
* Configure routing

### Example:

```dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
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
* Setup dependency injection
* Launch the app

### Example:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupDI();

  runApp(App());
}
```

---

# 7.0 Features Layer (`features/`)

## 📌 Purpose

Each folder represents **one feature of the system**

---

## 7.1 Feature Structure

Here is the updated README.md with the modifications to Section 7.1 and Section 11.0. I have integrated the progressive approach to Clean Architecture as requested.

🍽️ Smart Meal & Recipe Assistant — Developer Guide
📑 Table of Contents
1.0 Overview

2.0 Architecture Overview

3.0 Project Structure

4.0 Core Layer (core/)

4.1 constants/

4.2 network/

4.3 theme/

4.4 utils/

4.5 widgets/

5.0 App Layer (app/)

5.1 dependency_injection/

5.2 routers/

5.3 app.dart

6.0 Entry Point (main.dart)

7.0 Features Layer (features/)

7.1 Feature Structure

7.2 domain/

7.3 data/

7.4 presentation/

7.5 Role Separation

8.0 Feature Naming Rules

9.0 System Modules Mapping

10.0 Data Flow (MVVM)

11.0 Development Rules

12.0 Team Collaboration Guidelines

13.0 Future Scalability

14.0 Summary

15.0 Final Note

1.0 Overview
📌 Overview
This project is a Smart Meal & Recipe Assistant mobile application built using Flutter, following MVVM (Model-View-ViewModel) and Clean Architecture principles.

The system aims to:

Help users decide what to cook

Generate recipes based on available ingredients (AI-based)

Provide personalized recommendations

Support meal planning and grocery list generation

Reduce food waste

2.0 Architecture Overview
🧠 Architecture Overview
This project follows Clean Architecture, divided into 3 main layers:

Plaintext
Presentation Layer  → UI + ViewModels
Domain Layer        → Business logic (Use Cases, Entities)
Data Layer          → API, Database, Repositories
Additionally, we use:

core/ → reusable utilities across the app

app/ → app-level configuration (routing, DI, theme setup)

features/ → main business modules

3.0 Project Structure
🗂️ Project Structure
Plaintext
lib/
├── core/
├── features/
├── app/
├── main.dart
4.0 Core Layer (core/)
📌 Purpose
Contains generic, reusable components used across multiple features.

⚠️ Rule:

No business logic here

No feature-specific code

4.1 core/constants/
Purpose:
Store fixed values used globally

Examples:
App name

API base URL

Default limits

Static keys

Example:
Dart
class AppConstants {
  static const String appName = "Smart Meal Assistant";
  static const int maxRecipeResults = 20;
}
4.2 core/network/
Purpose:
Handle all API communication

Responsibilities:
HTTP client setup (e.g. Dio)

API endpoints

Request/response handling

Interceptors (logging, auth token)

Error handling

Example Structure:
Plaintext
network/
  api_client.dart
  api_endpoints.dart
  network_exception.dart
4.3 core/theme/
Purpose:
Define the UI design system

Responsibilities:
Colors

Typography

Light/Dark themes

Example:
Plaintext
theme/
  app_colors.dart
  app_text_styles.dart
  app_theme.dart
4.4 core/utils/
Purpose:
Provide helper functions

Examples:
Date formatting

Input validation

String formatting

4.5 core/widgets/
Purpose:
Reusable UI components used across multiple features

Examples:
CustomButton

LoadingIndicator

ErrorDialog

⚠️ Rule:

If widget is feature-specific → put inside that feature

If reusable → put here

5.0 App Layer (app/)
📌 Purpose
Handles how the app is wired together

⚠️ Rule:

No business logic here

Only configuration

5.1 app/dependency_injection/
Purpose:
Manage dependencies using DI (e.g. GetIt)

Responsibilities:
Register services

Register repositories

Register ViewModels

5.2 app/routers/
Purpose:
Centralized navigation system

Responsibilities:
Define routes

Handle navigation

Apply route guards (e.g. auth check)

5.3 app/app.dart
Purpose:
Root widget of the application

6.0 Entry Point (main.dart)
🚀 Purpose:
Start the application

7.0 Features Layer (features/)
📌 Purpose
Each folder represents one feature of the system

7.1 Feature Structure
Features in this project follow Clean Architecture, but are implemented using a progressive approach based on complexity.

🟢 Simple Features (Presentation-First)
For features with minimal logic (e.g. onboarding, static pages), use:

Plaintext
feature_name/
  ├── presentation/
  ├── model/
Examples:

onboarding

simple settings

static UI pages

👉 Reason: Avoid over-engineering and keep development fast.

🔵 Complex Features (Full Clean Architecture)
For features involving API, business logic, or scalability, use:

Plaintext
feature_name/
  ├── domain/
  ├── data/
  ├── presentation/
Examples:

auth

recipe

meal_plan

grocery

recommendation

⚠️ Important Rule:
Clean Architecture should be applied progressively, not strictly.
Start simple → expand when needed.
Do NOT create unnecessary layers for simple features.

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

## ❌ DO NOT:

* Put business logic in `core/`
* Put feature logic in `app/`
* Duplicate features for admin/user

## ✅ ALWAYS:

* Keep features independent
* Share domain logic
* Separate UI by role only
* Apply Clean Architecture progressively based on feature complexity

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
````