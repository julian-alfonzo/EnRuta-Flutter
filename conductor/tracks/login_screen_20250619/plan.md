# Implementation Plan: Login Screen con Sistema de Colores

## Phase 1: Sistema de Colores Parametrizado

- [x] Task: Crear archivo app_theme.dart con paleta MSM [4aa0054]
    - [x] Definir colores como constantes (primary, secondary, tertiary, surface, onSurface)
    - [x] Crear función `buildLightTheme()` que retorne `ThemeData` con los colores
    - [x] Configurar `useMaterial3: true`
    - [x] Integrar el tema en `main.dart` usando `theme: buildLightTheme()`
- [ ] Task: Verificar que el tema se aplica correctamente
    - [ ] Ejecutar `flutter analyze` y confirmar cero errores
    - [ ] Ejecutar `flutter test` y confirmar que los tests existentes pasan
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Sistema de Colores Parametrizado' (Protocol in workflow.md)

## Phase 2: Login Screen UI

- [ ] Task: Escribir test para Login Screen
    - [ ] Crear `test/login_screen_test.dart`
    - [ ] Test que verifica que los campos Usuario y Contraseña existen
    - [ ] Test que verifica que el botón 'Iniciar Sesión' está presente
    - [ ] Test que verifica que el botón 'Acceso Dev' está presente
    - [ ] Ejecutar tests y confirmar que fallan (Red Phase)
- [ ] Task: Implementar Login Screen
    - [ ] Crear `lib/screens/login_screen.dart`
    - [ ] Diseñar layout centrado con campos de texto (iconos, placeholders)
    - [ ] Agregar botón 'Iniciar Sesión' con color primary
    - [ ] Agregar botón 'Acceso Dev' al pie (texto secundario)
    - [ ] Estilo minimalista: espaciado generoso, tipografía limpia, sin ornamentos
- [ ] Task: Implementar mock validation
    - [ ] Lógica: si usuario == 'admin' y pass == 'admin123' → éxito
    - [ ] Si no → mostrar SnackBar con error 'Credenciales inválidas'
- [ ] Task: Implementar botón Acceso Dev
    - [ ] Auto-fill campos con usuario 'admin' y contraseña 'admin123'
    - [ ] Ejecutar login automáticamente después del auto-fill
- [ ] Task: Verificar tests pasan
    - [ ] Ejecutar tests y confirmar que ahora pasan (Green Phase)
    - [ ] Ejecutar `flutter analyze`
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Login Screen UI' (Protocol in workflow.md)

## Phase 3: Home Screen y Navegación

- [ ] Task: Escribir test para Home Screen
    - [ ] Crear `test/home_screen_test.dart`
    - [ ] Test que verifica texto 'Bienvenido' con nombre de usuario
    - [ ] Test que verifica botón 'Cerrar Sesión'
    - [ ] Ejecutar tests y confirmar que fallan (Red Phase)
- [ ] Task: Implementar Home Screen
    - [ ] Crear `lib/screens/home_screen.dart`
    - [ ] Mostrar 'Bienvenido, {usuario}'
    - [ ] Botón 'Cerrar Sesión' que vuelve al Login
    - [ ] Integrar navegación con Navigator.pushReplacement
- [ ] Task: Verificar tests pasan
    - [ ] Ejecutar tests y confirmar que pasan
    - [ ] Ejecutar `flutter analyze`
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Home Screen y Navegación' (Protocol in workflow.md)

## Phase 4: Integración y Verificación Final

- [ ] Task: Integrar Login y Home en main.dart
    - [ ] Configurar LoginScreen como pantalla inicial
    - [ ] Verificar flujo completo: Login → Home → Cerrar Sesión → Login
- [ ] Task: Verificación completa
    - [ ] Ejecutar `flutter test` — todos los tests pasan
    - [ ] Ejecutar `flutter analyze` — cero errores
    - [ ] Verificar que `app_theme.dart` puede modificarse fácilmente
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Integración y Verificación Final' (Protocol in workflow.md)
