# 🌍 Topografía App – Sistema de Rastreo y Mapeo en Tiempo Real

![Flutter](https://img.shields.io/badge/Flutter-Framework-blue?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Backend-orange?logo=firebase&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-En%20Desarrollo-yellow)

## 📌 Propósito y Alcance
El **Sistema de Autenticación** proporciona un inicio de sesión y registro seguro para la aplicación **Topografía**.  
Este sistema gestiona:
- ✅ Validación de credenciales  
- ✅ Hashing de contraseñas (BCrypt)  
- ✅ Gestión de sesiones  
- ✅ Asignación inicial de roles  

Sirve como punto de acceso a la aplicación y establece la base para el **control de acceso basado en roles** en todo el sistema.

---

## 🏗️ Descripción General
La **Aplicación Topografía** es un sistema de **rastreo y mapeo de ubicación basado en Flutter**, diseñado para:
- 📍 **Monitoreo de usuarios en tiempo real**
- 🗺️ **Dibujo de polígonos para cálculo de áreas**
- 🔐 **Gestión de acceso y roles de usuario**

### 📂 **Estructura de la Base de Datos Firestore**
- **`users`** → Credenciales cifradas y roles  
- **`locations`** → Datos de ubicación en tiempo real indexados por usuario  
- **`polygons`** → Polígonos dibujados con coordenadas y áreas calculadas  

---

## ⚙️ Sistemas Centrales

### 👥 Sistema de Gestión de Usuarios
Proporciona **administración completa de usuarios**, incluyendo CRUD, control de acceso y monitoreo en tiempo real.  

**Pantallas principales:**
- **`UserCrudScreen`** → Supervisión de usuarios y listas  
- **`CrudUserScreen`** → Operaciones CRUD individuales  

Los datos se almacenan en la colección **`users`** de Firebase con permisos basados en roles.

---

### 🗺️ Sistema de Mapeo y Localización
Gestiona **seguimiento de ubicación en tiempo real**, dibujo de polígonos y cálculos geoespaciales.  

📌 **Componentes clave:**
- 📡 **Seguimiento de ubicación:** `Geolocator.getPositionStream()`  
- 🔄 **Actualizaciones en tiempo real:** Almacenadas en la colección **`locations`**  
- ✏️ **Creación de polígonos:** Dibujo interactivo y cálculo de área  
- 💾 **Persistencia de datos:** Polígonos y áreas en **`polygons`**

---

### 🔐 Sistema de Autenticación
El sistema gestiona:
- Inicio de sesión y registro
- Persistencia de sesión (almacenamiento local)
- Validación del estado de sesión

📊 **Componentes:**
| Componente        | Objetivo                                         | Implementación                          |
|-------------------|--------------------------------------------------|-----------------------------------------|
| `LoginScreen`     | Interfaz de autenticación                        | Importado en `main.dart`                |
| `SharedPreferences` | Persistencia de sesión                         | Guarda `userId` en almacenamiento local |
| Validación de sesión | Verifica estado de inicio de sesión           | Método `MyApp._isLoggedIn()`            |

🖥️ **Flujo:** La clase `MyApp` busca `userId` en `SharedPreferences` para dirigir al usuario a **LoginScreen** o **HomeScreen**.

---

### ⚠️ Estrategia de Manejo de Errores
Se implementan mensajes claros y localizados en la pantalla:

| Tipo de Error | Ubicación | Mensaje Ejemplo |
|---------------|-----------|-----------------|
| Validación de correo | Bajo el campo de correo | “El formato del correo electrónico es incorrecto” |
| Validación de contraseña | Bajo el campo de contraseña | “La contraseña debe tener al menos 6 caracteres” |
| Autenticación | Formulario | “Usuario no encontrado”, “Contraseña incorrecta” |
| Registro | Formulario | “El correo electrónico ya está en uso” |

---

## 🏗️ Pila de Tecnología y Dependencias

![Pila de tecnología](./3ee2b3bd-7293-49c9-bf1a-6fdf5239fc58.png)

| Componente       | Tecnología                 | Objetivo |
|------------------|---------------------------|---------|
| **Estructura**   | SDK de Flutter           | Desarrollo multiplataforma |
| **Autenticación**| Criptografía DB          | Hashing y verificación de contraseñas |
| **Base de datos**| Firestore en la nube     | Base de datos NoSQL en tiempo real |
| **Mapas**        | Flutter de Google Maps   | Mapas interactivos |
| **Ubicación**    | Geolocalizador           | GPS y transmisión de ubicación |
| **Permisos**     | Manejador de permisos    | Gestión en tiempo de ejecución |
| **Almacenamiento** | SharedPreferences      | Datos de sesión y usuario |

---

## 🔧 Descripción General de la Configuración
La aplicación utiliza una **arquitectura de configuración en capas**:
- **Configuraciones de entorno**
- **Parámetros de compilación**
- **Valores de implementación**

---

## 📸 Capturas y Diagramas

### Sistema de Autenticación
![Sistema de autenticación](./05c2af76-b462-4406-8e2a-f57570ab983b.png)

### Manejo de Errores
![Estrategia de manejo de errores](./769864a0-9034-4c06-8e46-ad6efd92366d.png)

---

## 🚀 Instalación y Uso
```bash
# Clonar repositorio
git clone https://github.com/tuusuario/topografia-app.git

# Instalar dependencias
flutter pub get

# Ejecutar la app
flutter run

