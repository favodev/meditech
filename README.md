# MediTech: Ficha Médica Personal

MediTech es una plataforma digital integral centrada en la seguridad del paciente para la gestión activa y la portabilidad estandarizada del Tratamiento Anticoagulante Oral (TACO). El proyecto utiliza herramientas de inteligencia clínica para optimizar la toma de decisiones médicas y mitigar los riesgos derivados de la fragmentación de la información en el sistema de salud.

## Características Principales

- **Inteligencia Clínica:** Motor de cálculo automático del Tiempo en Rango Terapéutico (TTR) mediante el Algoritmo de Rosendaal.
- **Estándares Internacionales:** Modelado de datos basado en el estándar HL7 FHIR para garantizar la interoperabilidad y trazabilidad.
- **Seguridad Avanzada:** Autenticación de dos factores (2FA) mediante TOTP y gestión de archivos en la nube con URLs firmadas de caducidad automática.
- **Portabilidad:** Generación de códigos QR temporales para el intercambio seguro de información con profesionales de la salud sin necesidad de registro previo.

## Tecnologías Principales

- **Backend:** NestJS (Framework modular de Node.js), TypeScript, MongoDB con Mongoose (Base de datos NoSQL documental).
- **Frontend:** Flutter (SDK multiplataforma para iOS y Android).
- **Infraestructura:** Google Cloud Platform (GCP) y Cloud Storage.

## Estructura del Repositorio

- **[backend](./backend):** API REST que gestiona la lógica de negocio, seguridad (JWT/2FA) y persistencia clínica.
- **[frontend](./frontend):** Aplicación móvil nativa optimizada para la visualización de indicadores y escaneo de códigos QR.

---

## Configuración y Ejecución

### Backend (NestJS)
1. **Requisitos:** Node.js (v18+) y MongoDB.
2. **Instalación:**
   ```bash
   cd backend && npm install
   ```
3. **Variables de Entorno:** Configurar `.env` basado en `.env.example` (incluir claves de JWT y Firebase/GCP).
4. **Inicio:** `npm run start:dev`.

### Frontend (Flutter)
1. **Requisitos:** Flutter SDK (v3.9.2+).
2. **Instalación:**
   ```bash
   cd frontend && flutter pub get
   ```
3. **Inicio:** Conectar emulador/dispositivo y ejecutar `flutter run`.

---

## Autores

- **Estudiantes:** Johnson Davis Valenzuela Fuentes y Fernando Aurelio Vergara Ortiz.
