# 🌍 Topografía App – Sistema de Rastreo y Mapeo en Tiempo Real

![Flutter](https://img.shields.io/badge/Flutter-Framework-blue?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Backend-orange?logo=firebase&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-En%20Desarrollo-yellow)

## Video de youtube <img width="40" height="40" alt="image" src="https://github.com/user-attachments/assets/146ff1e9-82f4-481b-b266-5f66c45139b5" />

https://youtu.be/gSbLnWPj3Qw?si=OgZwcSRGItiyYINC

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


| Componente       | Tecnología                 | Objetivo |
|------------------|---------------------------|---------|
| **Estructura**   | SDK de Flutter           | Desarrollo multiplataforma |
| **Autenticación**| Criptografía DB          | Hashing y verificación de contraseñas |
| **Base de datos**| Firestore en la nube     | Base de datos NoSQL en tiempo real |
| **Mapas**        | Flutter de Google Maps   | Mapas interactivos |
| **Ubicación**    | Geolocalizador           | GPS y transmisión de ubicación |
| **Permisos**     | Manejador de permisos    | Gestión en tiempo de ejecución |
| **Almacenamiento** | SharedPreferences      | Datos de sesión y usuario |

Dependencias usadas
<img width="1660" height="212" alt="image" src="https://github.com/user-attachments/assets/da836137-d1c9-4f5b-a59b-e55dffa81142" />
---


## 🔧 Descripción General de la Configuración
La aplicación utiliza una **arquitectura de configuración en capas**:
- **Configuraciones de entorno**
- **Parámetros de compilación**
- **Valores de implementación**

---

## 📸 Capturas y Diagramas

# Aplicación 📱
## Login 

<p align="center">
  <img width="300" height="551" src="https://github.com/user-attachments/assets/b202369f-08f7-4545-9c1a-39277459f8ac" alt="Login" />
  <img width="300" height="550" alt="image" src="https://github.com/user-attachments/assets/8ece4196-0935-4465-83de-6b1465e24836" />
</p>

## Panel principal y Mapa
<p align="center">
  <img width="300" height="550" alt="image" src="https://github.com/user-attachments/assets/4b9834a1-a922-4967-a455-67d880fa97a3" />
  <img width="300" height="550" alt="image" src="https://github.com/user-attachments/assets/042c0772-5aca-4b80-b138-f2c72e3dd75f" />
</p>

## Gestión de usuarios
<p align="center">
  <img width="300" height="550" alt="image" src="https://github.com/user-attachments/assets/963becee-1c24-475e-8c43-155d39466547" />
  <img width="300" height="550" alt="image" src="https://github.com/user-attachments/assets/1f392a1d-b731-4872-8d6d-1cde6cd7ea7f" />

</p>

## Creación del Poligono
<img width="1919" height="1079" alt="image" src="https://github.com/user-attachments/assets/109b4a8e-387e-4aba-8b79-d2d586eaef8e" />
<img width="1919" height="1079" alt="image" src="https://github.com/user-attachments/assets/7568334a-05f5-4306-9add-6354d55c5bef" />




# Diagramas <img width="40" height="40" alt="image" src="https://github.com/user-attachments/assets/2c15030d-94e5-46fc-a3ad-9f4ece829948" />



## Arquitectura del sistema
<img width="1671" height="431" alt="image" src="https://github.com/user-attachments/assets/420ecfe3-5028-48f2-bf3a-4ab438077dc9" />

## Componentes principales y flujo de datos
<img width="1693" height="647" alt="image" src="https://github.com/user-attachments/assets/7d6d004b-37e1-4248-ab35-f93effdb6a4d" />

## Modelos y colecciones de datos
<img width="1563" height="774" alt="image" src="https://github.com/user-attachments/assets/49210dd1-4500-4bc6-8a83-642d94fdf5b6" />

## Sistema de gestión de usuarios
<img width="1529" height="388" alt="image" src="https://github.com/user-attachments/assets/fa71cc7f-9b7a-4dc2-af7e-bd86c7bff1e2" />

## Sistema de mapeo y localización
<img width="1640" height="622" alt="image" src="https://github.com/user-attachments/assets/a3684702-28ff-47e3-8f58-01a120f8aa05" />

# App en la tienda de Amazon 
<img width="1919" height="1019" alt="image" src="https://github.com/user-attachments/assets/cdead078-119c-4028-8236-aa3be250b944" />

# Link de la aplicacion 
```bash
https://www.amazon.com/Farbiopharma-Topography/dp/B0FKR66XQL/ref=sr_1_1?crid=3CULFQ67P5KLL&dib=eyJ2IjoiMSJ9.R9vASfbjOHllg1mHuXGsxjWRgayEX_dYlzKLLtOSL37uGycVcLblas4EqnGEhdoB.5YEQnCenxZWOaVJAjrA3aEofGVNAUsVxwXG_zbmKczo&dib_tag=se&keywords=Topograf%C3%ADa+app&qid=1754158437&sprefix=topograf%C3%ADa+app%2Caps%2C169&sr=8-1
```

<img width="1919" height="908" alt="image" src="https://github.com/user-attachments/assets/bf0b446a-c446-4bcd-a8b2-9ec2f8c306d0" />


---

## 🚀 Instalación y Uso
```bash
# Clonar repositorio
git clone https://github.com/tuusuario/topografia-app.git

# Instalar dependencias
flutter pub get

# Ejecutar la app
flutter run
```
## 🏆 Créditos
Desarrollado por Ariel Catucuamba y Joseph Caza

Basado en Flutter + Firebase + Google Maps.
