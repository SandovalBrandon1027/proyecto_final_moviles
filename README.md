<h1>Integrantes</h1> 
<h3>* Martin Jimenez</h3> 
<h3>* David Lascano </h3> 
<h3>* Brandon Sandoval </h3> 
<h3>* Andrew Vilcacundo </h3> 


# Proyecto de Aplicación Móvil para Mapeo de Terrenos

Este proyecto tiene como objetivo evaluar el desarrollo de aplicaciones móviles con servicios en segundo plano. La aplicación permite rastrear en tiempo real la ubicación de dispositivos para mapear terrenos y calcular el área de dichos terrenos.

## Características

- **Login para Validación de Usuarios**: Sistema de autenticación con roles de usuario y administrador.
- **Sistema de Administración Web/Móvil**: Permite agregar, eliminar o desactivar usuarios y administradores, y ver en tiempo real la ubicación de los topógrafos.
- **Visualización de Terrenos**: Muestra terrenos y sus características, ubicación, polígono definido, área, etc.
- **Geolocalización en Tiempo Real**: Utiliza Google Maps para mostrar la ubicación actual de los topógrafos y genera automáticamente enlaces de geolocalización.
- **Cálculo del Área del Polígono**: Calcula el área del terreno mapeado.

## Instalación

1. Clona este repositorio:

    ```bash
    git clone <URL_DEL_REPOSITORIO>
    ```

2. Navega al directorio del proyecto:

    ```bash
    cd <NOMBRE_DEL_DIRECTORIO>
    ```

3. Instala las dependencias:

    ```bash
    flutter pub get
    ```

4. Configura Firebase en tu proyecto Flutter. Sigue la [documentación de Firebase](https://firebase.google.com/docs/flutter/setup) para añadir Firebase a tu aplicación.

5. Agrega las configuraciones necesarias para Google Maps y Firebase en los archivos `android/app/src/main/AndroidManifest.xml` y `ios/Runner/Info.plist`.

6. Ejecuta la aplicación:

    ```bash
    flutter run
    ```

## Características de la Aplicación

### Registrate / Inicio de sesión 

La aplicación permite a los usuarios registrarse e iniciar sesión. Dependiendo del rol (Administrador o Usuario), la aplicación redirige a la vista correspondiente.

![image](https://github.com/user-attachments/assets/04180b89-b7d6-4e1a-9a4e-7f0b8801c784)

![image](https://github.com/user-attachments/assets/f7ec55ab-d3ca-4d94-a15d-4fc670a1aa3f)


### Administración Web/Móvil

El sistema de administración permite gestionar usuarios y administradores. La vista de administración muestra la ubicación en tiempo real de los topógrafos para monitorear su posición.

![image](https://github.com/user-attachments/assets/e466392a-877a-4289-a9c7-daae994e057a)


### Visualización de Terrenos

Permite ver los terrenos, su ubicación, el polígono definido y el área calculada.

![image](https://github.com/user-attachments/assets/cf36c1f2-1bda-499c-bf67-d38eedf77209)


### Geolocalización en Tiempo Real

Utiliza Google Maps para mostrar la ubicación actual de los usuarios y generar enlaces de geolocalización.

![image](https://github.com/user-attachments/assets/d2a1e5ec-0f6f-43d2-b392-7f94a907be23)


### Cálculo del Área

Calcula el área del polígono formado por las ubicaciones de los topógrafos.

![image](https://github.com/user-attachments/assets/61cecaad-3aeb-46c8-a0ec-ae738707a88e)


## Documentación y Videos

El código fuente completo y la documentación están disponibles en [GitHub](<[URL_DEL_REPOSITORIO](https://github.com/SandovalBrandon1027/proyecto_final_moviles.git)>).

Un video de funcionamiento y una breve explicación del proceso de desarrollo están disponibles en [YouTube](<[URL_DEL_VIDEO](https://youtu.be/i9hvKQHhkhg?si=9k-s8FJtLBl4Yq6W)>).

## Publicación en la Tienda de Aplicaciones

El proyecto ha sido publicado en la tienda de aplicaciones. Puedes encontrar la aplicación en [Google Play Store](<URL_DE_LA_TIENDA>)



