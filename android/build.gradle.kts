// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    // Definiciones de plugins para que estén disponibles para los módulos.
    // Usamos apply false porque solo estamos definiendo el 'classpath' aquí.

    // Plugin de Android Application: Eliminamos la versión para evitar conflictos.
    id("com.android.application") apply false

    // Plugin de Kotlin: Eliminamos la versión para evitar conflictos.
    id("org.jetbrains.kotlin.android") apply false

    // Plugin de Google Services para Firebase (CRÍTICO para leer google-services.json)
    // MANTENEMOS la versión de Google Services, ya que es la que se necesita específicamente.
    id("com.google.gms.google-services") version "4.4.1" apply false

    // Plugin de Flutter
    id("dev.flutter.flutter-gradle-plugin") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
